{config, pkgs, boot, lib, ...}:
{
 fileSystems = {
   # Start-marker: Filesystem auto-populated section
   "/" = {
      label = "NIXOS_ROOT";
      fsType = "ext4";
    };
    "/boot" = {
      label = "SYSTEM-EFI";
      fsType = "vfat";
    };
    # End-marker: Filesystem auto-populated section
 };
}
