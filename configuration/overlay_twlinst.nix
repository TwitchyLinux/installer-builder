# File-marker: Trim on install
{ self, super }:

  super.buildGoModule rec {
   name = "twlinst";
   version = "04c922b825a7558b7416d6b9ff2234e70cad64a9";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "${version}";
     sha256 = "1ig3hiyh5sj4ijh9dficfggdiw7fbf72jbysn09ra333prm32sya"; # use nix-prefetch-git
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
