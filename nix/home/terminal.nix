{ ... }:

{
  home-manager.users.yeet = {
    home.file.".config/alacritty".source = ../../.config/alacritty;
    home.file.".config/tmux".source = ../../.config/tmux;
  };
}
