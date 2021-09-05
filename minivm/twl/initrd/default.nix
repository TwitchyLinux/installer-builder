{ stdenv, lib, fetchFromGitHub, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn, pkgs, config }:
let
  # CPIO with initrd kernel module tree
  kmod-dir = pkgs.makeModulesClosure {
    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
    kernel = config.system.modulesTree.override { name = "linux-modules"; };
    firmware = config.hardware.firmware;
    allowMissing = false;
  };
  kmod-cpio = stdenv.mkDerivation {
    name = "kmod-cpio";
    nativeBuildInputs = [ pkgs.cpio ];
    src = kmod-dir;
    installPhase = ''
    find * .[^.*] -print0  | sort -z | ${pkgs.cpio}/bin/cpio -o -H newc -R +0:+0 --reproducible --null > "$out"
    '';
  };

  u-root-source = (pkgs.callPackage ./u-root.nix { config = config; }).u-root-source;
  u-root-binary = (pkgs.callPackage ./u-root.nix { config = config; }).u-root-binary;

  # Init script to setup the filesystem + nix state, then launch bash
  bringup = pkgs.writeScriptBin "bringup.sh" ''#!/bbin/elvish
  # Setup symlinks that most programs expect
  chmod 666 /dev/{null,urandom}
  ln -s -f /proc/self/fd /dev/fd
  ln -s -f /proc/self/fd/0 /dev/stdin
  ln -s -f /proc/self/fd/1 /dev/stdout
  ln -s -f /proc/self/fd/2 /dev/stderr

  # Get necessary drivers loaded
  modprobe -va loop squashfs overlay
  modscan load
  modscan -v load
  modscan load

  # Parse kernel commandline & setup the filesystem
  usetup
  # Load any explicitly-required kernel modules.
  ${pkgs.bash}/bin/bash -c 'for i in ${builtins.concatStringsSep " " config.boot.initrd.kernelModules}; do modprobe $i; done'

  # Create the /run/current-system symlink
  mkdir /run
  ln -s -f ${config.system.build.toplevel} /run/current-system

  # Initialize the nix store and get things moving
  ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration
  ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
  ${config.nix.package}/bin/nix-env --switch-profile /nix/var/nix/profiles/system

  echo 'twl' > /etc/hostname
  echo 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd

  exec ${pkgs.bashInteractive}/bin/bash -l
  '';

  modscan = pkgs.callPackage ./modscan.nix {};

  uroot-cpio = stdenv.mkDerivation {
    name = "uroot-cpio";
    buildInputs = [ modscan bringup ./usetup ];
    nativeBuildInputs = [ pkgs.go pkgs.coreutils u-root-binary ];
    src = u-root-source;

    installPhase = ''
      dir=$(pwd)
      mkdir -p $TMPDIR/go/src/{usetup,github.com/u-root}

      mv $dir $TMPDIR/go/src/github.com/u-root/u-root
      ${pkgs.coreutils}/bin/install -C -m 775 "${./usetup}"/* $TMPDIR/go/src/usetup

      export GOCACHE=$TMPDIR/go-cache
      export GOPATH="$TMPDIR/go"
      export GOSUMDB=off
      export GOPROXY=off
      export GO111MODULE=off
      export GOROOT=${pkgs.go}/share/go

      ${u-root-binary}/u-root -o "$out" \
        -base=/dev/null \
        -files "${modscan}/bin/modscan:bin/modscan" \
        -files "${bringup}/bin/bringup.sh:bringup" \
        -uinitcmd '/bringup' \
        core boot \
        github.com/u-root/u-root/cmds/exp/{console,partprobe,modprobe} \
        usetup/
    '';
  };

in
  stdenv.mkDerivation {
    name = "initrd";
    nativeBuildInputs = [ pkgs.cpio pkgs.coreutils pkgs.xz ];
    src = [
      kmod-cpio
      uroot-cpio
      config.system.build.toplevel
    ];

    unpackPhase = ''
      ln -sv ${kmod-cpio} kmod-cpio
      ln -sv ${uroot-cpio} uroot-cpio

      wd=`pwd`
      cd ${config.system.build.toplevel}
      find * .[^.*] -print0  | sort -z | ${pkgs.cpio}/bin/cpio -o -H newc -R +0:+0 --reproducible --null > "$wd/toplevel-cpio"
      cd $wd
    '';

    installPhase = ''
    ${pkgs.xz}/bin/xz --check=crc32 -9 --lzma2=dict=1MiB \
                      --stdout kmod-cpio toplevel-cpio uroot-cpio \
    | ${pkgs.coreutils}/bin/dd conv=sync bs=512 \
                               "of=$out"
    '';
  }
