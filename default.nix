let
  nixos = import <nixpkgs/nixos> { configuration = import ./config.nix; };
  lib = (import <nixpkgs> { }).lib;
  pkgs = nixos.pkgs;
  config = nixos.config;

  base-twl-config = import ./base-config-src.nix;

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

in
{
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

      mkdir -p ./files/etc/nixos
      install ${configNix} -m644 ./files/etc/nixos/configuration.nix
    '';
  });
}
