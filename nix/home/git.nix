{ username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    programs.git = {
      enable = true;
      settings = {
        user.name = "Yeet";
        user.email = "root@yigit.run";

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
