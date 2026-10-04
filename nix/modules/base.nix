{ lib, ... }:

{
  time.timeZone = "Europe/Amsterdam";

  # The CMOS cell is dead, so the RTC gives a wrong time after resume from
  # hibernate or suspend. The kernel copies that wrong time into the system
  # clock. Restart timesyncd to step the clock back to NTP time.
  # ponytail: restart is enough; use chrony if sub-second accuracy matters.
  systemd.services.resync-clock-after-resume = {
    description = "Resync the system clock after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/systemd/bin/systemctl try-restart systemd-timesyncd.service";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = true;
  # Show asterisks while typing the sudo password.
  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';

  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;
}
