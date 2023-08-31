{
  # https://github.com/TwitchyLinux/base-config
  # This is the basic configuration/internals of the system.
  #
  # This is imported into the nixos configuration for both the installer
  # and the final TwitchyLinux installation.
  twl-base-config = builtins.fetchTarball {
     url = "https://github.com/TwitchyLinux/base-config/archive/refs/tags/v0.1.16.tar.gz";
     sha256 = "0vpj9dh93zvlp73ksnm78c9p485iqblq5ry3lg4cnwv7cghanivg"; # use nix-prefetch-url --unpack '<url>'
  };

  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/817e297fc3352fadc15f2c5306909aa9192d7d97.tar.gz";
    sha256 = "1mm2kdbrgqvnah813znigxyzmrhzi6ccdndbs68m4hzyzlzfvjjf"; # use nix-prefetch-url --unpack '<url>'
  };
}
