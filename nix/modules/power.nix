{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    powertop
    tlp
    upower
  ];

  services.upower.enable = true;

  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/krypt";
    fsType = "btrfs";
    options = [ "subvol=swap" "noatime" ];
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024; # MiB; = RAM, enough for hibernation
    }
  ];

  boot.resumeDevice = "/dev/mapper/krypt";
  boot.kernelParams = [ "resume_offset=5621002" ];

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "suspend";
  };
}
