{ pkgs, ... }:

{
  imports = [
    ../hardware/ursa.nix

    ../modules/nix.nix
    ../modules/base.nix
    ../modules/users.nix
    ../modules/impermanence.nix
    ../modules/bluetooth.nix
    ../modules/audio.nix

    ../modules/hyprland.nix
    ../modules/login.nix

    ../modules/apps.nix
    ../modules/graphics.nix
    ../modules/power.nix
    ../modules/plymouth.nix

    ../home/base.nix
    ../home/env.nix
    ../home/scripts.nix
    ../home/shell.nix
    ../home/terminal.nix
    ../home/git.nix
    ../home/firefox.nix
    ../home/packages-cli.nix
    ../home/packages-dev.nix
    ../home/packages-nix.nix
    ../home/packages-editor.nix
    ../home/backgrounds.nix
    ../home/linux-theme.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "ursa";

  my.login = {
    autoLogin = true;
    user = "yeet";
    session = "hyprland";
  };

  my.power.swapSize = 16 * 1024;

  system.stateVersion = "26.05";
}
