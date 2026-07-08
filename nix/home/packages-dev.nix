{ pkgs, username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    home.packages = with pkgs; [
      awscli2
      azure-cli
      github-cli
      kubectl
      docker-client
      terragrunt
      opentofu
      attic-client
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
