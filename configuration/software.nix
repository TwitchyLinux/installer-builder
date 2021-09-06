{config, pkgs, ...}:
  let
    editors = with pkgs; [ nano vim ];
    net-tools = with pkgs; [ wget curl rsync socat inetutils iproute2 ];
    mon-tools = with pkgs; [ htop iotop iftop nload smartmontools ];

    fs-tools = with pkgs; [
      ntfsprogs
      e2fsprogs
      dosfstools
      f2fs-tools
      squashfsTools
      squashfs-tools-ng

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
      bash
      bashInteractive
      coreutils
      gnugrep
      findutils
      util-linux
      getent
      shadow
      killall

      unzip
      zip
      xz

      git
      jq

      bat
      lsd
      duf

      screen
      tmux
    ];

    hw-tools = with pkgs; [
      pciutils
      usbutils
    ];

    toolchains = with pkgs; [
      go
      rustc rustfmt cargo clippy gcc # cc needed for rust too
      stdenv
    ];

    gui-apps = with pkgs; [
      google-chrome
    ];

  in {
    imports = [
      ./graphical-software.nix
    ];

    system.extraDependencies = with pkgs;
      [
        stdenv
        stdenvNoCC # for runCommand
        patchelf
      ];

    environment.systemPackages = [
         pkgs.firecracker
       ]
        ++ editors
        ++ net-tools
        ++ mon-tools
        ++ fs-tools
        ++ general-tools
        ++ hw-tools
        ++ toolchains
        ++ gui-apps;
  }
