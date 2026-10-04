{ pkgs, config, ... }:

let
  edp = "eDP-1,1920x1080@60,1792x1440,1.25";
  # The daisy-chained (MST) Dells get new connector names (DP-3..DP-6) after
  # resume or replug, so match them by serial number.
  leftSerial = "5TKVLJ4";
  rightSerial = "37LVLJ4";
  left = "desc:Dell Inc. DELL U2724DE ${leftSerial}";
  right = "desc:Dell Inc. DELL U2724DE ${rightSerial}";
  # Hyprland has no conditional monitor rules: disable eDP-1 while either Dell
  # is connected. Re-run on config reload, which re-applies `monitor=`.
  edp-toggle = pkgs.writeShellApplication {
    name = "edp-toggle";
    runtimeInputs = [ config.programs.hyprland.package pkgs.socat pkgs.jq ];
    text = ''
      apply() {
        if hyprctl -j monitors all | jq -e 'any(.[]; .serial == "${leftSerial}" or .serial == "${rightSerial}")' >/dev/null; then
          hyprctl keyword monitor eDP-1,disable
        else
          hyprctl keyword monitor "${edp}"
        fi
      }
      apply
      socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r ev; do
        case $ev in
          "monitoradded>>eDP-1"* | "monitorremoved>>eDP-1"*) ;;
          "monitoradded>>"* | "monitorremoved>>"* | "configreloaded>>"*) apply ;;
        esac
      done
    '';
  };
in
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
    ../home/omp.nix
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

  # Left | right Dell on top, laptop centered below.
  # eDP-1 at 1.25 scale is 1536x864 logical: x = (2*2560 - 1536) / 2.
  my.hyprland.monitors = [
    "${left},2560x1440@59.95,0x0,1"
    "${right},2560x1440@59.95,2560x0,1"
    "${edp}"
  ];

  # Undocked, Hyprland puts all of these on eDP-1.
  my.hyprland.workspaces = [
    "1, monitor:${left}, persistent:true"
    "6, monitor:${left}, persistent:true"
    "7, monitor:${left}, persistent:true"
    "8, monitor:${left}, persistent:true"
    "2, monitor:${right}, persistent:true"
    "3, monitor:${right}, persistent:true"
    "4, monitor:${right}, persistent:true"
    "5, monitor:${right}, persistent:true"
    "9, monitor:${right}, persistent:true"
    "10, monitor:${right}, persistent:true"
  ];

  # A user service, not exec-once: `just switch` only reloads Hyprland, but
  # home-manager (re)starts changed services.
  home-manager.users.yeet.systemd.user.services.edp-toggle = {
    Unit = {
      Description = "Disable eDP-1 while either Dell is connected";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${edp-toggle}/bin/edp-toggle";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # UHD 620 display buffer (DDB) is too small for Y-tiled 1920+2560+2560 wide
  # scanout: i915 "exceeds system DDB limitations" and DP-5 drops to 1080p.
  # Untiled buffers need fewer blocks. See swaywm/wlroots#1877.
  home-manager.users.yeet.wayland.windowManager.hyprland.settings.env = [ "AQ_NO_MODIFIERS,1" ];

  home-manager.users.yeet.home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  my.power.swapSize = 16 * 1024;
  my.power.hibernation = {
    enable = true;
    resumeOffset = 5621002;
  };

  system.stateVersion = "26.05";
}
