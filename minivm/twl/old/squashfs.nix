{config, pkgs, ...}:
{
  imports = [
		./base.nix
	];

  boot.loader.grub.enable = false;
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };

  system.build.squashfsStore = pkgs.callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
    storeContents = [ config.system.build.toplevel ];
  };
}
