{ lib, pkgs, config, ... }:
let
  inputClosureOf = pkg: pkgs.runCommand "full-closure"
    {
      refs = pkgs.writeReferencesToFile pkg.drvPath;
    } ''
    touch $out
    while read ref; do
      case $ref in
        *.drv)
          cat $ref >>$out
          ;;
      esac
    done <$refs
  '';

  base-twl-config = (import ./sources.nix).twl-base-config;

in
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    <nixpkgs/nixos/modules/profiles/base.nix>

    base-twl-config
  ];

  twl.installer = lib.mkForce true;
  fileSystems = {
    "/" = {
      label = "NIXOS_ROOT";
      fsType = "ext4";
    };
    "/boot" = {
      label = "INST-EFI";
      fsType = "vfat";
    };
  };

  services.getty = {
    greetingLine = ''<<< Welcome to the TwitchyLinux Installer! (\m) - \l >>>'';
    autologinUser = "nixos";
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    # Allow the graphical user to login without password
    initialHashedPassword = "";
  };

  system.activationScripts.etc = lib.stringAfter [ "users" "groups" ]
    ''
      mkdir -pv /home/nixos/.config/sway
      ln -s /sway.config /home/nixos/.config/sway/config || true
      chown nixos /home/nixos/.config
      chown nixos /home/nixos/.config/sway

      if [ ! -f /home/nixos/.bashrc ]; then
        echo 'if [[ $(tty) == "/dev/tty1" ]]; then' >> /home/nixos/.bash_login
        echo '  sleep 2 && startsway' >> /home/nixos/.bash_login
        echo 'fi' >> /home/nixos/.bash_login
        chown nixos /home/nixos/.bash_login
      fi
    '';


  # Prevent installation media from evacuating persistent storage, as their
  # var directory is not persistent and it would thus result in deletion of
  # those entries.
  environment.etc."systemd/pstore.conf".text = ''
    [PStore]
    Unlink=no
  '';

  # Installer needs this
  environment.etc."twlinst.glade" = {
    mode = "0644";
    text = lib.fileContents "${pkgs.twlinst}/twlinst.glade";
  };

  # environment.extraOutputsToInstall = [ "doc" "man" "info" ];
  system.extraDependencies = with pkgs;
    [
      stdenv
      stdenvNoCC # for runCommand
      binutilsNoLibc
      buildPackages.patchelf
      buildPackages.nukeReferences
      buildPackages.bash
      buildPackages.perl
      buildPackages.busybox
      stdenv.cc.libc
      busybox-sandbox-shell

      nukeReferences
      perlPackages.FileSlurp
      perlPackages.JSON

      buildPackages.desktop-file-utils
      buildPackages.shared-mime-info
      buildPackages.gtk3
      buildPackages.texinfo
      w3m-nographics
      texinfoInteractive

      xorg.lndir

      # buildEnv { }

      (import <nixpkgs/pkgs/stdenv/linux/make-bootstrap-tools.nix> { }).build

      /* (
        callPackage <nixpkgs/pkgs/shells/bash/5.1.nix> {
        binutils = stdenv.cc.bintools;
        withDocs = true;
        }
        ) */

      # (inputClosureOf (import <nixpkgs/nixos> { configuration = import ../configuration; }).pkgs.sway)
    ] ++   
    # Don't error if it doesnt exist: it wont exist if base-twl-config
    # is a path rather than a fetchtarball.
      (if builtins.hasAttr "base-twl-config" pkgs then [base-twl-config] else []);

  time.timeZone = "America/Los_Angeles";
  boot.initrd.luks.forceLuksSupportInInitrd = true;
}
