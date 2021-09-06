{ ... }:
{
  imports = [
     <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>

    ../configuration
  ];

  services.getty = {
    greetingLine = ''<<< Welcome to the TwitchyLinux Installer! (\m) - \l >>>'';
    autologinUser = "nixos";
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    # Allow the graphical user to login without password
    initialHashedPassword = "";
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };


  # Prevent installation media from evacuating persistent storage, as their
  # var directory is not persistent and it would thus result in deletion of
  # those entries.
  environment.etc."systemd/pstore.conf".text = ''
    [PStore]
    Unlink=no
  '';

  documentation.enable = true;
  documentation.nixos.enable = true;
}
