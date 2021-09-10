{ pkgs, lib, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock # lockscreen
      swayidle
      xwayland # for legacy apps
      i3status-rust # status bar
      mako # notification daemon
      swaynagmode # action confirmation
      kanshi # hotplug => output changes
      wob # volume popover
      wofi

      grim
      slurp

      alacritty
      pcmanfm-qt
      feh

      twl-desktop-shortcuts
      gnome-icon-theme
      hicolor-icon-theme
    ];
  };
  programs.waybar.enable = false;


  environment.systemPackages = with pkgs; [
    wl-clipboard
    mesa
    win-spice
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



  hardware.opengl = {
    enable = true;
    #driSupport32Bit = true;
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    #package = pkgs.pulseaudioFull;
  };



  systemd.user.targets.sway-session = {
    description = "Sway compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
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
        ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug
      '';
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
