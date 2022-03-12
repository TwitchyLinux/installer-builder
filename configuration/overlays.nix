self: super:
let
  noopMkderivation = name: fname: super.stdenvNoCC.mkDerivation {
    name = name;
    src = ./resources;
    out = [
      "${fname}"
    ];

    dontBuild = true;
    dontUnpack = true;

    installPhase = ''
      mkdir $out
      cp $src/${fname} $out/${fname}
    '';
  };

in
{
  twl-background = noopMkderivation "twl-background" "twitchy_background.png";
  twl-sway-conf = noopMkderivation "twl-sway-conf" "sway.config";
  twl-i3status-conf = noopMkderivation "twl-i3status-conf" "i3status-rs.toml";

  twl-theme-gtk2 = noopMkderivation "twl-theme-gtk2" "gtk2";
  twl-theme-gtk3 = noopMkderivation "twl-theme-gtk3" "gtk3";

  swaynagmode = import ./overlay_swaynagmode.nix {
    inherit self super;
  };

  twl-desktop-shortcuts = import ./overlay_desktop-shortcuts.nix {
    inherit self super;
  };

  twlinst = import ./overlay_twlinst.nix {
    inherit self super;
  };
}
