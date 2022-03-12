# https://github.com/TwitchyLinux/base-config
# This is the basic configuration/internals of the system.
#
# This is imported into the nixos configuration for both the installer
# and the final TwitchyLinux installation.

builtins.fetchTarball {
  url = "https://github.com/TwitchyLinux/base-config/archive/refs/tags/v0.1.0.tar.gz";
  sha256 = "06v7kcfjnpf0vldpwbb8sg36ag5sql8sa9hsa1s2j89pr6cc3bgz"; # use nix-prefetch-url --unpack '<url>'
}