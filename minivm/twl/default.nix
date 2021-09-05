let
  nixos = import <nixpkgs/nixos> { configuration = import ./config.nix; };
  # udev = import ./udev.nix { config = config; pkgs = pkgs; lib = (import <nixpkgs> {}).lib; };
  pkgs = nixos.pkgs;
  config = nixos.config;
in {
  toplevel = config.system.build.toplevel;
  squashfs = pkgs.callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    storeContents = [ config.system.build.toplevel ];
  };

  initrd = pkgs.callPackage ./initrd { config = config; };
}
