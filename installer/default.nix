let
  nixos = import <nixpkgs/nixos> { configuration = import ./config.nix; };
  lib = (import <nixpkgs> { }).lib;
  pkgs = nixos.pkgs;
  config = nixos.config;

  dirFiles = suffix: dir: builtins.mapAttrs (n: v: dir + "/${n}")
    (lib.filterAttrs (name: _: lib.hasSuffix suffix name)
      (builtins.readDir dir));
  confFiles = dirFiles ".nix" "${../configuration}";
  resFiles = dirFiles "" "${../configuration/resources}";

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

      # Copy nix configuration files
      mkdir -p ./files/etc/twl-base
      NIX_FILES=$(echo '${builtins.toJSON confFiles}' | ${pkgs.jq}/bin/jq --raw-output -c 'to_entries | map("\(.key);\(.value)") | .[]')
      for f in $NIX_FILES; do
        IFS=';' read -ra FILE <<< "$f"
        cat ''${FILE[1]} > "./files/etc/twl-base/''${FILE[0]}"
      done

      # Copy resources
      mkdir -p ./files/etc/twl-base/resources
      RES_FILES=$(echo '${builtins.toJSON resFiles}' | ${pkgs.jq}/bin/jq --raw-output -c 'to_entries | map("\(.key);\(.value)") | .[]')
      for f in $RES_FILES; do
        IFS=';' read -ra FILE <<< "$f"
        cat ''${FILE[1]} > "./files/etc/twl-base/resources/''${FILE[0]}"
      done

      mkdir -p ./files/etc/nixos
      install ${configNix} -m644 ./files/etc/nixos/configuration.nix
    '';
  });
}
