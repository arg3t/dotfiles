{ pkgs, ... }:

{
  home-manager.users.yeet = { config, ... }: {
    # Zsh fully declarative: plugins from nixpkgs (pinned by flake.lock),
    # replacing the vendored antidote + unpinned git clones.
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;

      history = {
        size = 100000;
        save = 100000;
        path = "${config.xdg.dataHome}/zsh/history";
        append = true;
      };

      plugins = [
        {
          name = "powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
          file = "powerlevel10k.zsh-theme";
        }
        {
          name = "fzf-tab";
          src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
          file = "fzf-tab.plugin.zsh";
        }
        {
          name = "zsh-completions";
          src = "${pkgs.zsh-completions}/share/zsh/site-functions";
        }
      ];

      # The old .zshrc body (aliases, cmds, p10k, keybinds) stays as files,
      # sourced after the HM-managed plugin setup.
      initContent = ''
        [[ -f ${config.xdg.configHome}/zsh/rc.zsh ]] && source ${config.xdg.configHome}/zsh/rc.zsh
      '';
    };

    # zoxide replaces rupa/z (same `z` command, maintained, nix-native).
    programs.zoxide.enable = true;

    # fzf keybindings/completion wired by HM instead of hardcoded paths.
    programs.fzf = {
      enable = true;
      enableNushellIntegration = false;
    };

    # Custom zsh files stay live-editable in the repo.
    xdg.configFile."zsh/rc.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh/rc.zsh";
    xdg.configFile."zsh/aliases".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh/aliases";
    xdg.configFile."zsh/cmds".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh/cmds";
    xdg.configFile."zsh/p10k.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh/p10k.zsh";
    xdg.configFile."zsh/completions".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh/completions";
    xdg.configFile."zsh/bm-dirs".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/zsh/bm-dirs";

    home.packages = with pkgs; [
      fortune
      cowsay
      lolcat
    ];

    services.ssh-agent.enable = true;

    programs.starship.enable = false;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
