{ stdenv, lib, fetchFromGitHub, buildGoPackage, fetchgit, fetchhg, fetchbzr, fetchsvn, pkgs, config }:
let
  u-root-source = fetchFromGitHub {
    owner = "u-root";
    repo = "u-root";
    rev = "236bcb5a057c69b708f1844e93d97e248a103c05";
    sha256 = "0hx5zv5mry80ywpbi5nr7ikpixy4f6b8rv2c8qh54614cgjkydjw"; # use nix-prefetch-git
  };
  u-root-binary = buildGoPackage rec {
   name = "u-root";
   version = u-root-source.rev;
   goPackagePath = "github.com/u-root/u-root";

   buildPhase = ''
   runHook preBuild
   go build -o "$TMPDIR/u-root" -v github.com/u-root/u-root
   runHook postBuild
   '';

   installPhase = ''
   runHook preInstall

   mkdir -p $out
   cp -rv "$TMPDIR/u-root" $out

   runHook postInstall
   '';

   src = u-root-source;

   meta = with lib; {
     description = "A fully Go userland! u-root can create a root file system (initramfs) containing a busybox-like set of tools written in Go.";
     license = licenses.bsd3;
     homepage = https://u-root.tk;
     platforms = platforms.all;
   };
 };
in
  {
    u-root-source = u-root-source;
    u-root-binary = u-root-binary;
  }
