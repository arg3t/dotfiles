{ ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
  };

  home-manager.users.yeet = {
    home.file.".config/nvim".source = ../../.config/nvim;
  };
}
