{ stdenv, lib, fetchFromGitHub, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn, pkgs }:

  buildGoPackage rec {
   name = "modscan";
   version = "f4eed6febe57841e731fccb361a4f8c77183561f";
   goPackagePath = "github.com/bensallen/modscan";

   src = fetchFromGitHub {
     owner = "bensallen";
     repo = "modscan";
     rev = "f4eed6febe57841e731fccb361a4f8c77183561f";
     sha256 = "0gdpw15ala1qrsxgz78r0idg5ihk4rvnwx8xikwxnx741jdrwrbd"; # use nix-prefetch-git
   };

   meta = with lib; {
     description = "Linux kernel module detection based on modules.alias.";
     license = licenses.bsd3;
     platforms = platforms.all;
   };
 }
