{ pkgs, ... }:

{
  imports = [
    ../home/base.nix
    ../home/env.nix
    ../home/scripts.nix
    ../home/shell.nix
    ../home/terminal.nix
    ../home/git.nix
    ../home/firefox.nix
    ../home/packages-cli.nix
    ../home/packages-dev.nix
    ../home/packages-nix.nix
    ../home/packages-editor.nix
  ];

  users.users.yeet = {
    home = "/Users/yeet";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  system.stateVersion = 6;
}
