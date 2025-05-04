#!/bin/bash

set -o pipefail

MYDIR=$(dirname "$(readlink -f "$0")")

source "$MYDIR/kvm-include.sh"

IMAGE_NAME=""
IMAGE_URL=""

TMP_IMAGE_PATH===

declare -A KNOWN_IMAGES=(
    ["ubuntu22"]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    ["ubuntu24"]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
)

print_help()
{
    cat <<EOF
This script imports cloud images into KVM libvirt.

Usage: $0 <name> [url]

Arguments:
    <name>                 Name of the local qcow2 image
    [url]                  URL of the cloud image to import

Known images:
EOF
    for image in "${!KNOWN_IMAGES[@]}"; do
        echo "    $image: ${KNOWN_IMAGES[$image]}"
    done
}

function parse_args()
{
    # No argument is specified
    if [ "$#" -eq 0 ]; then
        print_help
        if [ -x virsh ]; then
            log_info "No action specified. Listing all images."
            sudo virsh image-list --all
        fi
        return 1
    fi

    # Help requested
    if [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        print_help
        return 0
    fi

    # Argument 1 is the machine name
    IMAGE_NAME=$1
    shift
    if [ "$IMAGE_NAME" == "" ]; then
        log_error "Image name is required"
        return 1
    fi
    log_info "Image name: $IMAGE_NAME"

    # Argument 2 is optionlly the image URL
    IMAGE_URL=$1
    shift
    if [ "$IMAGE_URL" == "" ]; then
        IMAGE_URL=${KNOWN_IMAGES[$IMAGE_NAME]}
    fi
    log_info "Image URL: $IMAGE_URL"
}

function cleanup()
{
    log_info "Cleaning up temporary image file: ${TMP_IMAGE_PATH}"

    rm -f ${TMP_IMAGE_PATH}
    if [ $? -ne 0 ]; then
        log_error "Failed to cleanup temporary image file."
        return 1
    fi
}

function main()
{
    parse_args "$@"
    if [ $? -ne 0 ]; then
        return 1
    fi

    local tpl_image_path="/var/lib/libvirt/images/${IMAGE_NAME}.qcow2"

    if sudo [ -f ${tpl_image_path} ]; then
        echo "Image ${tpl_image_path} already exists. Skipping download."
        return 0
    fi

    # Lets have a temporary file
    TMP_IMAGE_PATH=$(mktemp /tmp/kvm-import-image.XXXXXX)
    if [ $? -ne 0 ]; then
        log_error "Failed to create temporary image file."
        return 1
    fi

    log_info "Downloading image to ${TMP_IMAGE_PATH}."
    wget -q -O ${TMP_IMAGE_PATH} ${IMAGE_URL}
    if [ $? -ne 0 ]; then
        log_error "Failed to download image from ${IMAGE_URL}."
        return 1
    fi
    trap 'cleanup' EXIT

    log_info "Converting image to qcow2 format into ${tpl_image_path}."
    sudo qemu-img convert -f qcow2 -O qcow2 ${TMP_IMAGE_PATH} ${tpl_image_path}
    if [ $? -ne 0 ]; then
        log_error "Failed to convert image to qcow2 format."
        return 1
    fi

    sudo chmod 644 ${tpl_image_path}
    if [ $? -ne 0 ]; then
        log_error "Failed to set permissions on image file."
        return 1
    fi

    QEMU_GROUP="qemu" # RedHat default
    if [ "$LINUX_FAMILY" == "debian" ]; then
        QEMU_GROUP="libvirt-qemu" # Debian default
    fi
    sudo chown ${QEMU_GROUP}:kvm ${tpl_image_path}
    if [ $? -ne 0 ]; then
        log_error "Failed to set ownership ${QEMU_GROUP}:kvm on image file ${tpl_image_path}."
        return 1
    fi

    log_info "Image ${tpl_image_path} imported successfully."
}

main "$@"

