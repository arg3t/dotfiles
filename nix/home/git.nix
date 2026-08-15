{
  config,
  pkgs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = { config, pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user.name = "Yeet";
        user.email = "root@yigit.run";

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;

        core.pager = "delta --dark";
        core.untrackedCache = true;
        core.fsmonitor = true;
        interactive.diffFilter = "delta --color-only";
      };
    };

    xdg.configFile."lazygit/config.yml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/lazygit/config.yml";
  };
in

if standaloneHome then
  userConfig { inherit config pkgs; }
else
  { home-manager.users.${username} = userConfig; }
