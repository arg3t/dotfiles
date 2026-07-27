{ username ? "yeet", homeDirectory ? "/home/${username}", standaloneHome ? false, ... }:

let
  userConfig = {
    home.username = username;
    home.homeDirectory = homeDirectory;
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;
  };
in
if standaloneHome then
  userConfig
else {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # First activation: move pre-existing dotfiles aside instead of failing.
  home-manager.backupFileExtension = "hm-backup";

  home-manager.users.${username} = userConfig;
}
