{ pkgs, ... }:

{
  imports = [
    ../hardware/crux.nix

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
    ../modules/nvidia.nix
    ../modules/power.nix
    # ../modules/plymouth.nix

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

  networking.hostName = "crux";

  my.login = {
    autoLogin = true;
    user = "yeet";
    session = "hyprland";
  };

  # Desktop: Acer XB271HU (DP-3, 1440p@144) left of Samsung C27F390 (HDMI-A-1, 1080p@60).
  my.hyprland = {
    monitors = [
      "DP-3,2560x1440@144,0x0,1"
      "HDMI-A-1,1920x1080@60,2560x0,1"
    ];
    workspaces = [
      "1, monitor:HDMI-A-1, persistent:true"
      "2, monitor:HDMI-A-1, persistent:true"
      "3, monitor:HDMI-A-1, persistent:true"
      "4, monitor:HDMI-A-1, persistent:true"
      "5, monitor:HDMI-A-1, persistent:true"
      "6, monitor:HDMI-A-1, persistent:true"
      "7, monitor:HDMI-A-1, persistent:true"
      "8, monitor:HDMI-A-1, persistent:true"
      "9, monitor:HDMI-A-1, persistent:true"
      "10, monitor:HDMI-A-1, persistent:true"
      "11, monitor:DP-3, persistent:true"
      "12, monitor:DP-3, persistent:true"
      "13, monitor:DP-3, persistent:true"
      "14, monitor:DP-3, persistent:true"
      "15, monitor:DP-3, persistent:true"
      "16, monitor:DP-3, persistent:true"
      "17, monitor:DP-3, persistent:true"
      "18, monitor:DP-3, persistent:true"
      "19, monitor:DP-3, persistent:true"
      "20, monitor:DP-3, persistent:true"
    ];
    exec = [ "uvx nvibrant 700 700 700 700 700 700 700 700" ];
    battery = false; # desktop, no battery
  };

  home-manager.users.yeet.home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  my.power.swapSize = 16 * 1024;
  my.power.hibernation.enable = false;

  system.stateVersion = "26.05";
}
