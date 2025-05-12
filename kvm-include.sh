
# Color codes
PURPLE='\033[0;35m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Logging functions
log_title()   {
    echo -e "\n${PURPLE}[TITLE]${NC} $*\n";
}
log_info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" 1>&2 ; }
log_debug()   { echo -e "${PURPLE}[DEBUG]${NC} $*"; }

LINUX_FAMILY=$(grep -oP '(?<=^ID=).*' /etc/os-release | tr -d '"')
if [ "$LINUX_FAMILY" == "centos" ]; then
    LINUX_FAMILY="rhel"
fi
if [ "$LINUX_FAMILY" == "rocky" ]; then
    LINUX_FAMILY="rhel"
fi
if [ "$LINUX_FAMILY" == "almalinux" ]; then
    LINUX_FAMILY="rhel"
fi
if [ "$LINUX_FAMILY" == "fedora" ]; then
    LINUX_FAMILY="rhel"
fi
if [ "$LINUX_FAMILY" == "ubuntu" ]; then
    LINUX_FAMILY="debian"
fi
    
QEMU_GROUP="qemu" # RedHat default
if [ "$LINUX_FAMILY" == "debian" ]; then
    QEMU_GROUP="libvirt-qemu" # Debian default
fi

function ip_to_mac()
{
    local ip="$1"
    if [ -z "$ip" ]; then
        log_error "IP address not specified"
        return 1
    fi
    if ! [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid IP address format: $ip"
        return 1
    fi
    IFS='.' read -r a b c d <<< "$ip"
    export RETURNED_MAC=$(printf '52:54:%02X:%02X:%02X:%02X' $a $b $c $d)
}

function find_nic_by_vm_ip()
{
    local ip=$1

    export RETURNED_BRIDGE_NAME=""

    local best_match=""
    local best_match_count=0
    local ip_fields=()

    # Breake up $ip into fileds of array named ip_fields
    ip_fields=(${ip//./ })

    mapfile -t lines < <(ip addr)
    for line in "${lines[@]}"; do
        # Capture interface name from the previous line
        if [[ "$line" =~ ^[0-9]+:\ ([a-zA-Z0-9-]+): ]]; then
            local nic_name="${BASH_REMATCH[1]}"
        fi

        # Look for lines containing ipv4 address
        # For example: inet 192.168.100.1/24
        if [[ "$line" =~ inet\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\/ ]]; then
            local nic_ip="${BASH_REMATCH[1]}"

            # Breake up $nic_ip into fields of array named nic_ip_fields
            nic_ip_fields=(${nic_ip//./ })

            # count the number of matching elements
            # in ip_fields and nic_ip_fields
            local match_count=0
            for ((i=0; i<${#ip_fields[@]}; i++)); do
                if [[ "${ip_fields[i]}" == "${nic_ip_fields[i]}" ]]; then
                    ((match_count++))
                else
                    break
                fi
            done

            # If the match count is greater than the best match count, update
            # the best match and the best match count
            if (( match_count > best_match_count )); then
                export best_match="${nic_name}"
                best_match_count=$match_count
            fi
        fi
    done

    if [ -n "$best_match" ]; then
        export RETURNED_BRIDGE_NAME="$best_match"
    else
        log_error "No network interface found for IP $ip."
        return 1
    fi
}

# Find libvirt network based on bridge name
# param 1: Bridge name
function find_libvirt_network_by_bridge()
{
    local bridge=$1
    export RETURNED_NETWORK_NAME=

    # Iterate all networks and their associated bridges
    for net in $(sudo virsh net-list --all --name); do
        # Get the bridge name associated with each network
        local net_bridge=$(sudo virsh net-dumpxml "$net" | grep -oP '<bridge name='\''\K[^'\'' ]+')
        # Print the network name and its associated bridge
        if [[ "$net_bridge" == "$bridge" ]]; then
            RETURNED_NETWORK_NAME=$net
            break
        fi
    done
}


