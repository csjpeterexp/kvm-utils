#!/bin/bash
#
# kvm-setup.sh - Basic KVM/libvirt setup script for Rocky Linux 9
#

set -o pipefail

MYDIR="$(dirname "$(readlink -f "$0")")"

source "$MYDIR/kvm-include.sh"

print_help() {
    cat <<EOF
This script uninstalls KVM and libvirt virtualization.

Usage: $0 <action> [OPTIONS]

Actions:
  sure           Yes, do remove KVM and libvirt

Options:
  -h, --help     Show this help message and exit

EOF
}

uninstall_kvm()
{
    log_info "Stopping and disabling libvirtd service..."

    sudo systemctl stop libvirtd
    if [ $? -ne 0 ]; then
        log_error "Failed to stop libvirtd service."
        return 1
    fi

    sudo systemctl disable libvirtd
    if [ $? -ne 0 ]; then
        log_error "Failed to disable libvirtd service."
        return 1
    fi

    log_info "Uninstalling KVM and libvirt packages..."

    sudo dnf remove -y qemu-kvm libvirt bridge-utils virt-install virt-viewer libvirt-daemon-kvm
    if [ $? -ne 0 ]; then
        log_error "Failed to uninstall KVM and libvirt packages."
        return 1
    fi

    sudo systemctl daemon-reload
    if [ $? -ne 0 ]; then
        log_error "Failed to reload systemd daemon."
        return 1
    fi

    log_info "KVM and libvirt uninstalled."
}

main()
{
    if [ "$#" -eq 0 ]; then
        print_help
        return 1
    fi

    local action="$1"
    shift
    case "$action" in
        sure)
            uninstall_kvm
            return $?
            ;;
        *)
            print_error "Invalid action: $action"
            return 1
            ;;
    esac
}

main "$@"

