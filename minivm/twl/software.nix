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
    ];

    hw-tools = with pkgs; [
      pciutils
      usbutils
    ];

    toolchains = with pkgs; [
      go
    ];

  in {
    environment.systemPackages = [
         pkgs.screen
       ]
        ++ editors
        ++ net-tools
        ++ mon-tools
        ++ fs-tools
        ++ general-tools
        ++ hw-tools
        ++ toolchains;
  }
