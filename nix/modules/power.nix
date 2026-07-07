{ ... }:

{
  # Swap subvolume (already exists on the krypt btrfs volume) mounted at /swap;
  # NixOS creates the swapfile with chattr +C (no-CoW) on btrfs.
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

  # Hibernation: resume from the swapfile inside the LUKS container.
  # resume_offset computed with: btrfs inspect-internal map-swapfile -r /swap/swapfile
  boot.resumeDevice = "/dev/mapper/krypt";
  boot.kernelParams = [ "resume_offset=5621002" ];

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "suspend";
  };
}
