{config, pkgs, ...}:
  let
    editors = with pkgs; [ nano vim less ];
    net-tools = with pkgs; [
      inetutils iproute2 iputils nettools
      wget curl
      rsync
      socat netcat
      nftables dig
    ];
    mon-tools = with pkgs; [ htop iotop iftop nload smartmontools ];

    base-tools = with pkgs; [
      coreutils-full util-linux
      gnugrep gnused gnupatch gawk
      findutils diffutils binutils bintools procps
      attr acl zlib pcre atk libcap ncurses
      bash bashInteractive
      unzip gzip zip xz cpio bzip2 zstd gnutar
      getent getconf
      time which
      su sudo shadow
    ];

    fs-tools = with pkgs; [
      ntfsprogs e2fsprogs dosfstools f2fs-tools
      squashfsTools squashfs-tools-ng

      lvm2 mdadm

      parted
      gptfdisk

      ms-sys
      efibootmgr
      efivar

      sshfs
      sshfs-fuse
      squashfuse
      fuse-overlayfs

      sdparm
      hdparm

      cryptsetup
    ];

    general-tools = with pkgs; [
      mkpasswd
      killall
      kmod

      nix-tree nix-prefetch-git

      git
      jq

      bat lsd duf

      screen tmux

      age gnupg
      openssl

      graphviz
    ];

    hw-tools = with pkgs; [
      pciutils
      usbutils
    ];

    toolchains = with pkgs; [
      go
      rustc rustfmt cargo clippy gcc # cc needed for rust too
      stdenv
      perl python3
      gnumake cmake patch
      patchelf
    ];

  in {
    imports = [
      ./graphical-software.nix
    ];

    environment.systemPackages = [
         pkgs.firecracker
         pkgs.udisks
         pkgs.pamixer
       ]
        ++ base-tools
        ++ editors
        ++ net-tools
        ++ mon-tools
        ++ fs-tools
        ++ general-tools
        ++ hw-tools
        ++ toolchains;
  }
