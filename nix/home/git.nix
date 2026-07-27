{
  config,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = { config, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user.name = "Yeet";
        user.email = "root@yigit.run";

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;

        core.pager = "delta --dark";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
        merge.conflictStyle = "zdiff3";
      };
    };

    xdg.configFile."lazygit/config.yml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/lazygit/config.yml";
  };
in
if standaloneHome then
  userConfig { inherit config; }
else
  { home-manager.users.${username} = userConfig; }
