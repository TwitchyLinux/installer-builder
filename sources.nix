{
  # https://github.com/TwitchyLinux/base-config
  # This is the basic configuration/internals of the system.
  #
  # This is imported into the nixos configuration for both the installer
  # and the final TwitchyLinux installation.
  twl-base-config = builtins.fetchTarball {
     url = "https://github.com/TwitchyLinux/base-config/archive/refs/tags/v0.1.15.tar.gz";
     sha256 = "0jsml5mixn0clri5asy1i4k5hli49rsxri2zdylgq2qh29svms0b"; # use nix-prefetch-url --unpack '<url>'
  };

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/3006d2860a6ed5e01b0c3e7ffb730e9b293116e2.tar.gz";
    sha256 = "1xds9sy8hw98ss7fv5d2cqa1nf3agq4bm0x3appbawrhzp275zvq"; # use nix-prefetch-url --unpack '<url>'
  };
}
