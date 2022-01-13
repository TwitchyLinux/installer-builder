set -e

if [[ $(whoami) == "root" ]]; then
  echo "Cannot be run as root"
  exit 1
fi

# Nix
NIX_TOPLEVEL_PATH=$(nix-build --max-jobs 4 --cores 8 -A toplevel installer)
NIX_ROOTFS_PATH=$(nix-build --max-jobs 4 --cores 8 -A rootfsImage installer)
kernel_params=$(cat "${NIX_TOPLEVEL_PATH}/kernel-params")

# Globals
SCRIPT_BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
IMG_FILE="/tmp/twl-installer.img"
IMG_DEV=""
BOOT_IMG_MOUNT_POINT=""



init_image () {
  echo "Creating partition table..."
  sudo parted --script "${IMG_DEV}" mklabel gpt            \
         mkpart fat32 1MiB 512MiB                          \
         mkpart ext4  512MiB 100%                          \
         set 1 boot on
  sudo partprobe $IMG_DEV
  sleep 2

  echo "Creating fat32 filesystem on ${IMG_DEV_BOOT}..."
  sudo mkfs.fat -F32 -n INST-EFI "${IMG_DEV_BOOT}"
  sleep 2

  mkdir -p /tmp/tmp_boot_mnt || true
  sudo mount -o uid=$(id -u) "${IMG_DEV_BOOT}" /tmp/tmp_boot_mnt
  BOOT_IMG_MOUNT_POINT="/tmp/tmp_boot_mnt"

  echo "Copying rootfs to ${IMG_DEV_MAIN}..."
  sudo dd status=progress if=${NIX_ROOTFS_PATH} "of=${IMG_DEV_MAIN}"
}

setup_boot () {
  sudo bootctl "--path=${BOOT_IMG_MOUNT_POINT}" --no-variables install

cat > ${BOOT_IMG_MOUNT_POINT}/loader/entries/installer.conf <<EOF
title TwitchyLinux Installer
version test v 1
linux /efi/kernel
initrd /efi/initrd
options OPTS_LINE
EOF

  sed -i "s*OPTS_LINE*${kernel_params}*g" ${BOOT_IMG_MOUNT_POINT}/loader/entries/installer.conf

  install "${NIX_TOPLEVEL_PATH}/kernel" -m 0755 "${BOOT_IMG_MOUNT_POINT}/efi/kernel"
  install "${NIX_TOPLEVEL_PATH}/initrd" -m 0755 "${BOOT_IMG_MOUNT_POINT}/efi/initrd"
}


unmount_img () {
  if [[ $IMG_DEV == /dev/loop* ]]; then
    sudo losetup -d "${IMG_DEV}"
  fi
  IMG_DEV=''
}

on_exit () {
  if [[ "${BOOT_IMG_MOUNT_POINT}" != "" ]]; then
    echo "Unmounting $BOOT_IMG_MOUNT_POINT"
    sudo umount $BOOT_IMG_MOUNT_POINT
    BOOT_IMG_MOUNT_POINT=""
  fi

  if [[ "${IMG_DEV}" != "" ]]; then
    unmount_img
  fi
}





trap 'on_exit $LINENO' ERR EXIT

if [[ $1 == '' ]]; then
  dd if=/dev/zero "of=${IMG_FILE}" bs=1 count=0 seek=16G
  sudo losetup /dev/loop0 ${IMG_FILE}
  IMG_DEV='/dev/loop0'
  IMG_DEV_BOOT='/dev/loop0p1'
  IMG_DEV_MAIN='/dev/loop0p2'
else
  IMG_DEV="$1"
  IMG_DEV_BOOT="${1}1"
  IMG_DEV_MAIN="${1}2"
fi

init_image
setup_boot

# sudo apt-get install ovmf
#
# qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -device virtio-rng-pci -vga virtio -enable-kvm -cpu host -smp 4 -m 4G -drive format=raw,file=/tmp/twl-installer.img
