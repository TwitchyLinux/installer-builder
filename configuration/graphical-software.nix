{ pkgs, lib, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock # lockscreen
      swayidle # Engage lockscreen after inactivity
      wob # volume popover
      wofi # launch menu

      i3status-rust # status bar
      mako # notification daemon
      swaynagmode # action confirmation

      gammastep

      # kanshi # hotplug => output changes

      grim # screenshots
      slurp # region selector, works with grim

      alacritty
      pcmanfm-qt
      feh
      google-chrome

      twlinst # Line-marker: Trim on install
      twl-desktop-shortcuts
      gnome-icon-theme
      hicolor-icon-theme
    ];
  };
  programs.waybar.enable = false;
  programs.xwayland.enable = true;


  environment.systemPackages = with pkgs; [
    wl-clipboard
    mesa
    (
      pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.bash}/bin/bash

          # first import environment variables from the login manager
          systemctl --user import-environment
          # then start the service
          exec systemctl --user start sway.service
        '';
      }
    )
  ];

  environment = {
    etc = {
      "sway/config".source = "${pkgs.twl-sway-conf}/sway.config";
      "sway/i3status-rs.toml".source = "${pkgs.twl-i3status-conf}/i3status-rs.toml";
      "twitchy_background.png".source = "${pkgs.twl-background}/twitchy_background.png";
    };
  };

  systemd.user.services.sway = {
    description = "Sway - Wayland window manager";
    documentation = [ "man:sway(5)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    # We explicitly unset PATH here, as we want it to be set by
    # systemctl --user import-environment in startsway
    environment.PATH = lib.mkForce null;
    environment.WLR_RENDERER_ALLOW_SOFTWARE = "1";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.dbus}/bin/dbus-run-session sway
      '';
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  hardware.opengl = {
    enable = true;
    #driSupport32Bit = true;
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };
}
