{ pkgs, ... }:

{
  boot.plymouth = {
    enable = true;
    theme = "mac-style";
    themePackages = [ pkgs.mac-style-plymouth ];
  };

  boot.kernelParams = [
    "quiet"
    "splash"
    "udev.log_level=3"
  ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
}
