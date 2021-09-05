{ ... }:
{
  imports = [
    ../configuration
  ];

  services.getty.greetingLine = ''<<< Welcome to the TwitchyLinux Installer! (\m) - \l >>>'';
}
