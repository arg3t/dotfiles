{ pkgs, lib, username ? "yeet", standaloneHome ? false, ... }:

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
      (python3.withPackages (ps: with ps; [ requests ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pygobject3
          pydbus
        ]))
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
