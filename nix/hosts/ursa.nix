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
    ../modules/waybar.nix
    ../modules/packages.nix
    ../modules/login.nix
    ../modules/shell.nix
    ../modules/dev.nix

    ../modules/apps.nix
    ../modules/graphics.nix
    ../modules/power.nix
    ../modules/plymouth.nix

    ../home/base.nix
    ../home/env.nix
    ../home/scripts.nix
    ../home/shell.nix
    ../home/terminal.nix
    ../home/firefox.nix
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

  system.stateVersion = "26.05";
}
