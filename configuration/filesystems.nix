{config, pkgs, boot, lib, ...}:
{
 fileSystems = {
   "/" = {
      label = "NIXOS_ROOT";
      fsType = "ext4";
    };
    "/boot" = {
      label = "SYSTEM-EFI";
      fsType = "vfat";
    };
 };
}
