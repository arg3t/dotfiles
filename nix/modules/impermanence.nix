{ lib, ... }:

{
  fileSystems."/persist".neededForBoot = true;

  # Roll the root subvolume back to the blank snapshot on every boot.
  # Runs in initrd (systemd stage 1), after LUKS is opened, before /sysroot
  # is mounted.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.rollback = {
    description = "Rollback btrfs root subvolume to blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@krypt.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/mapper/krypt /mnt

      # Delete nested subvolumes under root first (srv, tmp, var/tmp,
      # var/lib/portables, var/lib/machines, ...), then root itself.
      btrfs subvolume list -o /mnt/root |
        cut -f9- -d' ' |
        while read -r subvolume; do
          btrfs subvolume delete "/mnt/$subvolume"
        done

      btrfs subvolume delete /mnt/root
      btrfs subvolume snapshot /mnt/root-blank /mnt/root

      umount /mnt
    '';
  };

  # State that must survive the wipe. /home, /nix, /var/log and /persist are
  # their own subvolumes and are never touched.
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/bluetooth"
      "/var/lib/tailscale"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
