{ pkgs, ... }:

{
  home-manager.users.yeet = { config, ... }: {
    # Out-of-store symlink: antidote writes .zsh_plugins.zsh next to its
    # config, so ~/.config/zsh must stay writable (store links are read-only).
    home.file.".config/zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh";

    # Declarative .zshenv replacing `source ~/.profile`:
    #  - loads Home Manager session variables (hm-session-vars.sh)
    #  - points zsh at ~/.config/zsh
    #  - custom sudo prompt from the old .profile
    home.file.".zshenv".text = ''
      for f in \
        "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" \
        "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; do
        [ -f "$f" ] && . "$f" && break
      done

      export ZDOTDIR="$HOME/.config/zsh"

      export SUDO_PROMPT="$(printf '\033[38;5;141m\xef\x80\xa3\033[0m Shall you pass?') "
    '';

    # Deps of the .zshrc: fzf keybindings, fortune/cowsay banner.
    home.packages = with pkgs; [
      fzf
      fortune
      cowsay
      lolcrab
    ];

    # Replaces the imperative `eval $(ssh-agent)` from the old .profile.
    services.ssh-agent.enable = true;

    programs.starship.enable = false;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
