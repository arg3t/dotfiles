{ ... }:

{
  home-manager.users.yeet = {
    programs.git = {
      enable = true;
      userName = "Yeet";
      userEmail = "root@yigit.run";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };
  };
}
