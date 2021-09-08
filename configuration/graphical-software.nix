{ pkgs, ... }:
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

      alacritty

      twl-desktop-shortcuts
      gnome-icon-theme
      hicolor-icon-theme
    ];
  };
  programs.waybar.enable = true;


  environment.systemPackages = with pkgs; [
    wl-clipboard
    mesa
    win-spice
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
}
