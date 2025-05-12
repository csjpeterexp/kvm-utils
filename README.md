# kvm-utils
Bash scripts to ease using kvm with libvirt.
These scripts are using sudo, and for convenience a passwordless sudo is
recommended.

## kvm-install.sh

The script `kvm-install.sh` installs kvm and libvirt on a RedHat-based
system. Tested on Rocky 9.
The script is idempotent, so it can be run multiple times.

Example usage:
```bash
./kvm-install.sh sure
```

## kvm-uninstall.sh

The script `kvm-uninstall.sh` uninstalls kvm and libvirt on a
RedHat-based system. Tested on Rocky 9.
The script is idempotent, so it can be run multiple times.

Example usage:
```bash
./kvm-uninstall.sh sure
```

## kvm-net.sh

The script `kvm-net.sh` create and ruin network configuration for kvm.
Configures virtual bridge with NAT, and static DHCP.

Example usage:
```bash
./kvm-net.sh define default 192.168.122.0/24 --bridge-name=virbr0
```

### kvm-net-define.sh

The script `kvm-net-define.sh` creates a network configuration for kvm. It
creates a bridge with NAT and static DHCP. The script is idempotent, so it
can be run multiple times without creating duplicate networks.

Example usage:
```bash
./kvm-net.sh define default 192.168.122.0/24 --bridge-name=virbr0
```

### kvm-net-undefine.sh

The script `kvm-net-undefine.sh` removes a network configuration for kvm. It
removes the bridge and static DHCP. The script is idempotent, so it can be
run multiple times without creating duplicate networks.

Example usage:
```bash
./kvm-net.sh undefine default --bridge-name=virbr0
```

## kvm-import-image.sh

This script imports cloud images into KVM libvirt.

Example usage:
```bash
./kvm-import-image.sh ubuntu24
```

## kvm-create-vm.sh

This script creates a new VM in KVM libvirt. It uses the cloud image
imported by `kvm-import-image.sh` and creates a new VM with the specified
name and configuration.

Example usage:
```bash
./kvm-create-vm.sh ubuntu24 ubuntu24-guest 192.168.100.2 --ram=2048 --vcpus=2 --disk-size=20G 
```

## kvm-delete-vm.sh

This script deletes a VM in KVM libvirt. It removes the VM and its
associated resources.

Example usage:
```bash
./kvm-delete-vm.sh ubuntu24-guest
```

## kvm-remote.sh

This script copies the necessary kvm utility script to a remote server and
executes it there with the arguments passed to this script.

Example usage:
```bash
./kvm-remote.sh my-test-server.org install sure
```

