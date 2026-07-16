{ pkgs, ... }:

{
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
