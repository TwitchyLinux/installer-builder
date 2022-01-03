# File-marker: Trim on install
{ self, super }:

  super.buildGoModule rec {
   name = "twlinst";
   version = "ea9ed3709440a59ad119dc775242af6310e9aaa7";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "${version}";
     sha256 = "0pj3mar3cwgcp49mawf1zsn1bxlwg7bvq79c2r2c00qzn5h0ha10"; # use nix-prefetch-git
   };

   vendorSha256 = "sha256-FKB3YiM/zkkW5olfnaCw4AYI7YvcpvLyLSP6xHMd5mY=";

   nativeBuildInputs = [ super.pkg-config ];
   buildInputs = [ super.gtk3 ];

   postInstall = ''
       cp -v layout.glade $out/twlinst.glade
     '';

   meta = with super.lib; {
     description = "Graphical installer for twitchylinux.";
     license = licenses.bsd3;
     platforms = platforms.unix;
   };
 }
