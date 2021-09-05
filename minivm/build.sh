#!/bin/bash
set -e

# Globals
SCRIPT_BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
TMP_AREA=$(mktemp -d)
# Configurable globals
NO_DELETE='0' # set with --no-delete
RUN_QEMU='0' # set with --test-qemu

# Handle positionals
POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -n|--no-delete)
      NO_DELETE='1'
      shift # past argument
      ;;
      -t|--test-qemu)
      RUN_QEMU='1'
      shift # past argument
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Error / interrupt handling
cleanup () {
  if [ -z ${1+x} ]; then
    echo "Error on line $1."
  fi

  if [[ "${TMP_AREA}" != "" ]]; then
    if [[ "${NO_DELETE}" != "1" ]]; then
      rm -r "${TMP_AREA}"
    fi
    TMP_AREA=""
  fi
}

trap 'cleanup $LINENO' ERR EXIT


# Build nix initrd, rootfs, and squashfs store.
set -x
nix_opts='--cores 18 --max-jobs 2'
nix-build $nix_opts \
      -o "${TMP_AREA}/nix-store.squashfs" \
      -A squashfs \
      twl
nix-build $nix_opts \
      -o "${TMP_AREA}/toplevel" \
      -A toplevel \
      twl
nix-build $nix_opts \
      -o "${TMP_AREA}/initramfs.linux_amd64.cpio.xz" \
      -A initrd \
      twl
set +x


# Perhaps run in qemu
if [[ "${RUN_QEMU}" == "1" ]]; then
  qemu-system-x86_64 -kernel "${TMP_AREA}/toplevel/kernel" \
                     -initrd "${TMP_AREA}/initramfs.linux_amd64.cpio.xz" \
                     \
                     -drive "file=${TMP_AREA}/nix-store.squashfs,format=raw,if=none,id=squashfs,readonly" \
                     -device virtio-blk-pci,drive=squashfs,scsi=off \
                     \
                     -fsdev "local,id=rootfs,path=${TMP_AREA}/toplevel,security_model=none,readonly" \
                     -device 'virtio-9p-pci,fsdev=rootfs,mount_tag=rootfs' \
                     \
                     -device virtio-rng-pci \
                     -nographic \
                     -enable-kvm -cpu host -smp 4 -m 4G \
                     -append "console=ttyS0 uroot.nix-store=/dev/vda uroot.mount.test=ro:virtio-9p-pci:rootfs"

# -drive "file=${TMP_AREA}/nix-store.squashfs,format=raw,media=disk" \
fi
