# File-marker: Trim on install
{ self, super }:

  super.buildGoModule rec {
   name = "twlinst";
   version = "9a2db153b9446feaec747c2cf9cc6b5b600c407c";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "${version}";
     sha256 = "1s60ijih1m8yz40rjpkm7bsmb7vpn70wqx9s5hwngccnfn6mmv7l"; # use nix-prefetch-git
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
