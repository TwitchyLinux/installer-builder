let
  nixos = import <nixpkgs/nixos> { configuration = import ./config.nix; };
  lib = (import <nixpkgs> { }).lib;
  pkgs = nixos.pkgs;
  config = nixos.config;

  base-twl-config = (import ./sources.nix).twl-base-config;
  nixos-hardware = (import ./sources.nix).nixos-hardware;

  hw-info = import ./hardware.nix {
    pkgs = pkgs;
    nixos-hardware = nixos-hardware;
  };

  configNix = pkgs.writeTextFile {
    name = "configuration.nix";
    text = ''
      {...}:
      {
       imports = [
        /etc/twl-base
       ];
      }
    '';
  };

  installer-sway-config = ./sway.config;

in
{
  version,
}: {
  toplevel = config.system.build.toplevel;

  rootfsImage = pkgs.callPackage <nixpkgs/nixos/lib/make-ext4-fs.nix> ({
    storePaths = [ config.system.build.toplevel ];
    volumeLabel = "NIXOS_ROOT";

    populateImageCommands = ''
      mkdir -p ./files
      ln -s ${config.system.build.toplevel}/init ./files/init

      # Copy TwitchyLinux base configuration
      mkdir -p ./files/etc/twl-base
      cp -rv ${base-twl-config}/* ./files/etc/twl-base

      # Copy nixos-hardware
      mkdir -p ./files/etc/nixos-hardware
      cp -rv ${nixos-hardware}/* ./files/etc/nixos-hardware

      mkdir -p ./files/etc/nixos
      install ${configNix} -m644 ./files/etc/nixos/configuration.nix

      echo '${version}' > ./files/twl-installer-version

      install ${hw-info} -m644 ./files/nixos-hardware-info.json
      install ${installer-sway-config} -m644 ./files/sway.config
    '';
  });
}
