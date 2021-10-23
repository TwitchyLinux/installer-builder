{ lib, pkgs, ... }:
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

  system.activationScripts.etc = lib.stringAfter [ "users" "groups" ]
    ''
      mkdir -pv /home/nixos/.config/sway
      ln -s /etc/installer-sway.config /home/nixos/.config/sway/config || true

      if [ ! -f /home/nixos/.bashrc ]; then
        echo 'if [[ $(tty) == "/dev/tty1" ]]; then' >> /home/nixos/.bash_login
        echo '  sleep 2 && startsway' >> /home/nixos/.bash_login
        echo 'fi' >> /home/nixos/.bash_login
      fi
    '';


  # Prevent installation media from evacuating persistent storage, as their
  # var directory is not persistent and it would thus result in deletion of
  # those entries.
  environment.etc."systemd/pstore.conf".text = ''
    [PStore]
    Unlink=no
  '';

  # Installer needs this
  environment.etc."twlinst.glade" = {
    mode = "0644";
    text = lib.fileContents "${pkgs.twlinst}/twlinst.glade";
  };
  environment.etc."installer-sway.config" = {
    mode = "0644";
    text = lib.fileContents ../configuration/resources/sway.config + "\nexec twlinst";
  };

  documentation.enable = true;
  documentation.nixos.enable = true;
}
