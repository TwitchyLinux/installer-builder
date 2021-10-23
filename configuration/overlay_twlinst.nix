{ self, super }:

  super.buildGoPackage rec {
   name = "twlinst";
   version = "833aae0a873de9f3b468dfbeaca9a2254f34d139";
   goPackagePath = "https://github.com/twitchylinux/twlinst";

   src = super.fetchFromGitHub {
     owner = "twitchylinux";
     repo = "twlinst";
     rev = "${version}";
     sha256 = "1srcgv3k7q1xfig7vlmjavdgkc78616pw5npvwlbnhflrj4z816r"; # use nix-prefetch-git
   };
   goDeps = ./resources/twlinst-deps.nix;

   nativeBuildInputs = [ super.pkg-config ];
   buildInputs = [ super.gtk3 ];

   preBuild = ''
       mv go/src/${goPackagePath}/layout.glade layout.glade
     '';
   postInstall = ''
       cp -v layout.glade $out/twlinst.glade
     '';

   meta = with super.lib; {
     description = "Graphical installer for twitchylinux.";
     license = licenses.bsd3;
     platforms = platforms.unix;
   };
 }
