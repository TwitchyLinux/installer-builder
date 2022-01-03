{config, pkgs, boot, lib, ...}:
{
 imports = [
   <nixpkgs/nixos/modules/profiles/all-hardware.nix>
   <nixpkgs/nixos/modules/hardware/all-firmware.nix>

   ./software.nix
   ./filesystems.nix # Line-marker: Trim on install
 ];
 nixpkgs.overlays = [ (import ./overlays.nix) ];

 # Boot
 boot.loader.grub.enable = false;
 boot.loader.systemd-boot.enable = true;
 system.autoUpgrade.enable = true;
 boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      rm -f /nix-path-registration
    fi
  '';

 # Basic localization
 console = {
   keyMap = "us";
 };
 environment.etc.inputrc = {
   mode = "0644";
   source = pkgs.copyPathToStore ./resources/inputrc;
 };

 # Fonts
 fonts.fontDir.enable = true;
 fonts.fonts = with pkgs; [
     freefont_ttf
     liberation_ttf
     source-code-pro
     font-awesome_4
   ];

 nixpkgs.config.allowUnfree = true;

 # Networking
 networking.networkmanager.enable = true;

 # Users / access control
 security.sudo = {
   enable = true;
   wheelNeedsPassword = false;
 };

 documentation.enable = true;
 documentation.man.enable = true;
 documentation.dev.enable = true;
 documentation.nixos.enable = true;
}
