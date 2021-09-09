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

  swaynagmode = super.stdenv.mkDerivation rec {
    pname = "swaynagmode";
    version = "0.2.1";

    src = super.fetchFromGitHub {
      owner = "b0o";
      repo = "swaynagmode";
      rev = "v${version}";
      sha256 = "BuPnP9PerPpxi0DJgp0Cfkaddi8QAYzcvbDTiMehkJw=";
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      mkdir -p $out/bin
      cp swaynagmode $out/bin
    '';
  };

  twl-desktop-shortcuts = super.stdenv.mkDerivation rec {
    pname = "twl-desktop-shortcuts";
    version = "0.0.1";

    src = ./resources/shortcut-template;

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      mkdir -p $out/share/applications/

      cp $src $out/share/applications/shutdown.desktop
      sed -i 's/CMD/systemctl poweroff -i/g'            $out/share/applications/shutdown.desktop
      sed -i 's/NAME/Shutdown/g'                        $out/share/applications/shutdown.desktop
      sed -i 's/ICON/system-shutdown/g'                 $out/share/applications/shutdown.desktop

      cp $src $out/share/applications/reboot.desktop
      sed -i 's/CMD/systemctl reboot/g'                 $out/share/applications/reboot.desktop
      sed -i 's/NAME/Reboot/g'                          $out/share/applications/reboot.desktop
      sed -i 's/ICON/system-reboot\nKeywords=restart/g' $out/share/applications/reboot.desktop

      cp $src $out/share/applications/screenshot-selection.desktop
      sed -i "s/CMD/bash -c 'CMD'/g"                    $out/share/applications/screenshot-selection.desktop
      sed -i 's/CMD/grim -g "$(slurp)"/g'               $out/share/applications/screenshot-selection.desktop
      sed -i 's/NAME/Screenshot (to file)/g'            $out/share/applications/screenshot-selection.desktop
      sed -i 's/ICON/camera-web/g'                      $out/share/applications/screenshot-selection.desktop

      cp $src $out/share/applications/screenshot-clipboard.desktop
      sed -i "s/CMD/bash -c 'CMD'/g"                    $out/share/applications/screenshot-clipboard.desktop
      sed -i 's/CMD/grim -g "$(slurp)" - | wl-copy/g'   $out/share/applications/screenshot-clipboard.desktop
      sed -i 's/NAME/Screenshot (to clipboard)/g'       $out/share/applications/screenshot-clipboard.desktop
      sed -i 's/ICON/camera-web/g'                      $out/share/applications/screenshot-clipboard.desktop
    '';
  };
}
