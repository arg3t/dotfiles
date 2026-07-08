{ pkgs, username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    home.packages = with pkgs; [
      git
      git-lfs
      curl
      wget
      ripgrep
      fd
      jq
      just
      htop
      fzf
      eza
      tree
      unzip
      zip
      bat
      file
      fastfetch
      magic-wormhole
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
