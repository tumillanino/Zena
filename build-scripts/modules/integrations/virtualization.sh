set -ouex pipefail

shopt -s nullglob

dnf5 -y install qemu-kvm libvirt virt-install guestfs-tools virt-manager waydroid
