## Build

Make sure nix is working in your shell using the instructions below, then:

1. `./make-installer.sh`, be ready to sudo
1. `qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -soundhw hda -device virtio-rng-pci -vga virtio -enable-kvm -cpu host -smp 4 -m 4G -drive format=raw,file=/tmp/twl-installer.img`

## Getting nix working

Each session:

```shell
sudo sysctl -w kernel.unprivileged_userns_clone=1
nix-user-chroot /scratch/nix-store/ bash -l
```

First time:

```shell
$ git clone https://github.com/nix-community/nix-user-chroot
$ cd nix-user-chroot
$ cargo build --release

$ sudo apt-get install ovmf
$ nix-user-chroot /scratch/nix-store bash -c "curl -L https://nixos.org/nix/install | bash"
```

## minivm instructions

1. `cd minivm`
1. Run `./build.sh --test-qemu`
