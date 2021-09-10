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

in {
  twl-background = noopMkderivation "twl-background" "twitchy_background.png";
  twl-sway-conf = noopMkderivation "twl-sway-conf" "sway.config";
  twl-i3status-conf = noopMkderivation "twl-i3status-conf" "i3status-rs.toml";

  swaynagmode = import ./overlay_swaynagmode.nix {
    inherit self super;
  };

  twl-desktop-shortcuts = import ./overlay_desktop-shortcuts.nix {
    inherit self super;
  };
}
