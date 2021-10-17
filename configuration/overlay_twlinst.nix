{ self, super }:

  super.buildGoPackage rec {
   name = "twlinst";
   version = "909b1f24cbddcb215335a21c6628aefc559b80c5";
   goPackagePath = "https://github.com/twitchylinux/twlinst";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "909b1f24cbddcb215335a21c6628aefc559b80c5";
     sha256 = "0q5v42bq1ds9pny4c9jg7d6avi0qxs9icbka8k9ld4ldn5g2p0f5"; # use nix-prefetch-git
   };
   goDeps = ./resources/twlinst-deps.nix;

   nativeBuildInputs = [ super.pkg-config ];
    buildInputs = [ super.gtk3 ];

   meta = with super.lib; {
     description = "Linux kernel module detection based on modules.alias.";
     license = licenses.bsd3;
     platforms = platforms.all;
   };
 }
