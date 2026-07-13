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
      (python3.withPackages (ps: with ps; [
        pygobject3
        pydbus
        requests
      ]))
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
