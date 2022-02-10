# File-marker: Trim on install
{ self, super }:

  super.buildGoModule rec {
   name = "twlinst";
   version = "d588f9c7e386c23d76848730cd0d3bd4b2f80e85";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "${version}";
     sha256 = "07arq62hv62vifdpiq6yx5yxjkzmfys16m15cbgvxzlimzm05dp2"; # use nix-prefetch-git
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
