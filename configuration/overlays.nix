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
}
