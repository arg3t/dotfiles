{ ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # First activation: move pre-existing dotfiles aside instead of failing.
  home-manager.backupFileExtension = "hm-backup";

  home-manager.users.yeet = {
    home.username = "yeet";
    home.homeDirectory = "/home/yeet";
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;
  };
}
