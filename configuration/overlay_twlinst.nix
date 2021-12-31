# File-marker: Trim on install
{ self, super }:

  super.buildGoModule rec {
   name = "twlinst";
   version = "63f9a3d17ae6afd7adc415dbfd3c5c2f3a81b2e3";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "${version}";
     sha256 = "0y1my8j9iswfmg0pzwyfpq32g03akbsrjql4rdn1cf4mcwkpgmpd"; # use nix-prefetch-git
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
