{config, pkgs, lib, ...}:
let
  udev = config.systemd.package;

  # A utility for enumerating the shared-library dependencies of a program
  # Source: https://github.com/NixOS/nixpkgs/blob/8284fc30c84ea47e63209d1a892aca1dfcd6bdf3/nixos/modules/system/boot/stage-1.nix
  # Licensed as MIT: https://github.com/NixOS/nixpkgs/blob/master/COPYING
  # Copyright (c) 2003-2021 Eelco Dolstra and the Nixpkgs/NixOS contributors
  findLibs = pkgs.buildPackages.writeShellScriptBin "find-libs" ''
    set -euo pipefail
    declare -A seen
    left=()
    patchelf="${pkgs.buildPackages.patchelf}/bin/patchelf"
    function add_needed {
      rpath="$($patchelf --print-rpath $1)"
      dir="$(dirname $1)"
      for lib in $($patchelf --print-needed $1); do
        left+=("$lib" "$rpath" "$dir")
      done
    }
    add_needed "$1"
    while [ ''${#left[@]} -ne 0 ]; do
      next=''${left[0]}
      rpath=''${left[1]}
      ORIGIN=''${left[2]}
      left=("''${left[@]:3}")
      if [ -z ''${seen[$next]+x} ]; then
        seen[$next]=1
        # Ignore the dynamic linker which for some reason appears as a DT_NEEDED of glibc but isn't in glibc's RPATH.
        case "$next" in
          ld*.so.?) continue;;
        esac
        IFS=: read -ra paths <<< $rpath
        res=
        for path in "''${paths[@]}"; do
          path=$(eval "echo $path")
          if [ -f "$path/$next" ]; then
              res="$path/$next"
              echo "$res"
              add_needed "$res"
              break
          fi
        done
        if [ -z "$res" ]; then
          echo "Couldn't satisfy dependency $next" >&2
          exit 1
        fi
      fi
    done
  '';

  # Modified from: https://github.com/NixOS/nixpkgs/blob/8284fc30c84ea47e63209d1a892aca1dfcd6bdf3/nixos/modules/system/boot/stage-1.nix#L90
  # Licensed as MIT: https://github.com/NixOS/nixpkgs/blob/master/COPYING
  # Copyright (c) 2003-2021 Eelco Dolstra and the Nixpkgs/NixOS contributors
  # Contains udevadm and a few utilities that are needed for setting up the device tree.
  udev-base = pkgs.runCommandCC "udev-base"
    { nativeBuildInputs = [pkgs.buildPackages.nukeReferences];
      allowedReferences = [ "out" ]; # prevent accidents like glibc being included in the initrd
    }
    ''
      set +o pipefail
      mkdir -p $out/bin $out/lib
      ln -s $out/bin $out/sbin
      copy_bin_and_libs () {
        [ -f "$out/bin/$(basename $1)" ] && rm "$out/bin/$(basename $1)"
        cp -pdv $1 $out/bin
      }

      # Copy some util-linux stuff.
      copy_bin_and_libs ${pkgs.util-linux}/sbin/blkid
      # Copy dmsetup and lvm.
      copy_bin_and_libs ${lib.getBin pkgs.lvm2}/bin/dmsetup
      copy_bin_and_libs ${lib.getBin pkgs.lvm2}/bin/lvm
      # Add RAID mdadm tool.
      copy_bin_and_libs ${pkgs.mdadm}/sbin/mdadm
      copy_bin_and_libs ${pkgs.mdadm}/sbin/mdmon
      # Copy udev.
      copy_bin_and_libs ${udev}/bin/udevadm
      copy_bin_and_libs ${udev}/lib/systemd/systemd-sysctl
      for BIN in ${udev}/lib/udev/*_id; do
        copy_bin_and_libs $BIN
      done
      # systemd-udevd is only a symlink to udevadm these days
      ln -sf udevadm $out/bin/systemd-udevd

      ${config.boot.initrd.extraUtilsCommands}
      # Copy ld manually since it isn't detected correctly
      cp -pv ${pkgs.stdenv.cc.libc.out}/lib/ld*.so.? $out/lib
      # Copy all of the needed libraries
      find $out/bin $out/lib -type f | while read BIN; do
        echo "Copying libs for executable $BIN"
        for LIB in $(${findLibs}/bin/find-libs $BIN); do
          TGT="$out/lib/$(basename $LIB)"
          if [ ! -f "$TGT" ]; then
            SRC="$(readlink -e $LIB)"
            cp -pdv "$SRC" "$TGT"
          fi
        done
      done
      # Strip binaries further than normal.
      chmod -R u+w $out
      stripDirs "$STRIP" "lib bin" "-s"
      # Run patchelf to make the programs refer to the copied libraries.
      find $out/bin $out/lib -type f | while read i; do
        if ! test -L $i; then
          nuke-refs -e $out $i
        fi
      done
      find $out/bin -type f | while read i; do
        if ! test -L $i; then
          echo "patching $i..."
          patchelf --set-interpreter $out/lib/ld*.so.? --set-rpath $out/lib $i || true
        fi
      done
      if [ -z "${toString (pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform)}" ]; then
      # Make sure that the patchelf'ed binaries still work.
      echo "testing patched programs..."
      export LD_LIBRARY_PATH=$out/lib
      $out/bin/blkid -V 2>&1
      $out/bin/udevadm --version
      $out/bin/dmsetup --version 2>&1
      $out/bin/mdadm --version
      ${config.boot.initrd.extraUtilsCommandsTest}
      fi
    ''; # */
in
{
  base = udev-base;

  # Source: https://github.com/NixOS/nixpkgs/blob/8284fc30c84ea47e63209d1a892aca1dfcd6bdf3/nixos/modules/system/boot/stage-1.nix
  # Licensed as MIT: https://github.com/NixOS/nixpkgs/blob/master/COPYING
  # Copyright (c) 2003-2021 Eelco Dolstra and the Nixpkgs/NixOS contributors
  rules = pkgs.runCommand "udev-rules" {
      allowedReferences = [ udev-base ];
      preferLocalBuild = true;
    } ''
      mkdir -p $out
      echo 'ENV{LD_LIBRARY_PATH}="${udev-base}/lib"' > $out/00-env.rules
      cp -v ${udev}/lib/udev/rules.d/60-cdrom_id.rules $out/
      cp -v ${udev}/lib/udev/rules.d/60-persistent-storage.rules $out/
      cp -v ${udev}/lib/udev/rules.d/75-net-description.rules $out/
      cp -v ${udev}/lib/udev/rules.d/80-drivers.rules $out/
      cp -v ${udev}/lib/udev/rules.d/80-net-setup-link.rules $out/
      cp -v ${pkgs.lvm2}/lib/udev/rules.d/*.rules $out/
      ${config.boot.initrd.extraUdevRulesCommands}
      for i in $out/*.rules; do
          substituteInPlace $i \
            --replace ata_id ${udev-base}/bin/ata_id \
            --replace scsi_id ${udev-base}/bin/scsi_id \
            --replace cdrom_id ${udev-base}/bin/cdrom_id \
            --replace ${pkgs.coreutils}/bin/basename ${udev-base}/bin/basename \
            --replace ${pkgs.util-linux}/bin/blkid ${udev-base}/bin/blkid \
            --replace ${lib.getBin pkgs.lvm2}/bin ${udev-base}/bin \
            --replace ${pkgs.mdadm}/sbin ${udev-base}/sbin \
            --replace ${pkgs.bash}/bin/sh ${udev-base}/bin/sh \
            --replace ${udev} ${udev-base}
      done
      # Work around a bug in QEMU, which doesn't implement the "READ
      # DISC INFORMATION" SCSI command:
      #   https://bugzilla.redhat.com/show_bug.cgi?id=609049
      # As a result, `cdrom_id' doesn't print
      # ID_CDROM_MEDIA_TRACK_COUNT_DATA, which in turn prevents the
      # /dev/disk/by-label symlinks from being created.  We need these
      # in the NixOS installation CD, so use ID_CDROM_MEDIA in the
      # corresponding udev rules for now.  This was the behaviour in
      # udev <= 154.  See also
      #   http://www.spinics.net/lists/hotplug/msg03935.html
      substituteInPlace $out/60-persistent-storage.rules \
        --replace ID_CDROM_MEDIA_TRACK_COUNT_DATA ID_CDROM_MEDIA
    ''; # */
}
