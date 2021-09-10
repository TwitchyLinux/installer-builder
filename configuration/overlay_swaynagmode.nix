{ self, super }:
super.stdenv.mkDerivation rec {
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
}
