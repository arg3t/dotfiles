{ pkgs, ... }:

{
  home-manager.users.yeet = {
    home.file.".config/alacritty".source = ../../.config/alacritty;

    programs.tmux = {
      enable = true;
      plugins = [
        {
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig = "set -g @catppuccin_flavor 'mocha'";
        }
      ];
      extraConfig = builtins.readFile ../../.config/tmux/tmux.conf;
    };
  };
}
