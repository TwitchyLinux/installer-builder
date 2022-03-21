{
  # https://github.com/TwitchyLinux/base-config
  # This is the basic configuration/internals of the system.
  #
  # This is imported into the nixos configuration for both the installer
  # and the final TwitchyLinux installation.
  twl-base-config = builtins.fetchTarball {
    url = "https://github.com/TwitchyLinux/base-config/archive/refs/tags/v0.1.7.tar.gz";
    sha256 = "0ss8ng000g0k1k1nhpkvvqgs7k5p3bgm2y9jknj943svgjj1ynsi"; # use nix-prefetch-url --unpack '<url>'
  };

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/816a935bf5aa5f77cb1f03ebfe20ab13b112d0f1.tar.gz";
    sha256 = "1dldbr0ikwb28ramzncriylfr8v6chf5wsadm844wx3487hx4sxr"; # use nix-prefetch-url --unpack '<url>'
  };
}