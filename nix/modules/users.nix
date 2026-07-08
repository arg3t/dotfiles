{ pkgs, ... }:

{
  # Impermanence: /etc/shadow lives on the wiped root subvolume, so passwords
  # must be declarative. Hashes are copied from the pre-impermanence /etc/shadow
  # into /persist/passwords (chmod 600).
  programs.zsh.enable = true;
  users.mutableUsers = false;

  users.users.root.hashedPasswordFile = "/persist/passwords/root";

  users.users.yeet = {
    isNormalUser = true;
    description = "YEAT";
    hashedPasswordFile = "/persist/passwords/yeet";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];

    shell = pkgs.zsh;
  };
}
