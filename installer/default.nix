let
  nixos = import <nixpkgs/nixos> { configuration = import ./config.nix; };
  lib = (import <nixpkgs> {}).lib;
  pkgs = nixos.pkgs;
  config = nixos.config;

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

in {
  toplevel = config.system.build.toplevel;

  rootfsImage = pkgs.callPackage <nixpkgs/nixos/lib/make-ext4-fs.nix> ({
    storePaths = [ config.system.build.toplevel ];
    volumeLabel = "NIXOS_ROOT";

    populateImageCommands = ''
      mkdir -p ./files
      ln -s ${config.system.build.toplevel}/init ./files/init

      mkdir -p ./files/etc/twl-base
      echo '${lib.fileContents ../configuration/software.nix}' > ./files/etc/twl-base/software.nix
      echo '${lib.fileContents ../configuration/filesystems.nix}' > ./files/etc/twl-base/filesystems.nix
      echo '${lib.fileContents ../configuration/overlays.nix}' > ./files/etc/twl-base/overlays.nix
      echo '${lib.fileContents ../configuration/default.nix}' > ./files/etc/twl-base/default.nix

      mkdir -p ./files/etc/nixos
      install ${configNix} -m644 ./files/etc/nixos/configuration.nix
    '';
  });
}
