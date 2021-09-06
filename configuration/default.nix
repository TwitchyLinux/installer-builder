{config, pkgs, boot, lib, ...}:
{
 imports = [
   <nixpkgs/nixos/modules/profiles/all-hardware.nix>

   ./software.nix
   ./filesystems.nix
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
 i18n = {
   defaultLocale = "en_US.UTF-8";
   supportedLocales = [ (config.i18n.defaultLocale + "/UTF-8") ];
 };
 time.timeZone = "America/Los_Angeles";

 # Fonts
 fonts.fontDir.enable = true;
 fonts.fonts = with pkgs; [
     freefont_ttf
     liberation_ttf
     source-code-pro
     font-awesome_4
   ];
}
