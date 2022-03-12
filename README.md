# installer-builder

Creates a TwitchyLinux installer image or USB.

`./make-installer.sh`

If you want to test the installer by installing to a fake HDD:

```shell

qemu-img create -f qcow2 /tmp/qemu_hdd.img 25G
qemu-system-x86_64 -bios $(nix eval --raw nixpkgs.OVMF.fd)/FV/OVMF.fd -device virtio-rng-pci -vga virtio \
    -device intel-hda -device hda-duplex \
    -enable-kvm -cpu host -smp 4 -m 4G -drive format=raw,file=/tmp/twl-installer.img \
    -drive id=disk,file=/tmp/qemu_hdd.img,if=none -device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0
# Dont forget to install qemu and 'OVMF'

```
