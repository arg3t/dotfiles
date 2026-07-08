{ ... }:

{
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
