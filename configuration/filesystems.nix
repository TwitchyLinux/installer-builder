# File-marker: Trim on install
{config, pkgs, boot, lib, ...}:
{
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
}
