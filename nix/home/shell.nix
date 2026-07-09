{ pkgs, config, lib, username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = { config, lib, ... }: {
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      enableCompletion = true;

      # Full compinit + compaudit costs ~800ms; do it at most once a day,
      # use the cached dump (-C) otherwise.
      completionInit = builtins.concatStringsSep "\n" [
        "fpath=(\"${config.xdg.configHome}/zsh/completions\" $fpath)"
        "autoload -U compinit"
        "if [[ -n \"\${ZDOTDIR}/.zcompdump\"(#qN.mh-24) ]]; then compinit -C; else compinit; fi"
      ];
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

      # p10k instant prompt must run before anything that prints (mkOrder 500
      # puts it at the very top of .zshrc); personal config loads last.
      initContent = lib.mkMerge [
        (lib.mkOrder 500 ''
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        '')
        ''
          [[ -f ${config.xdg.configHome}/zsh/rc.zsh ]] && source ${config.xdg.configHome}/zsh/rc.zsh
        ''
      ];
    };

    # zoxide replaces rupa/z (same `z` command, maintained, nix-native).
    programs.zoxide.enable = true;

    # fzf keybindings/completion wired by HM instead of hardcoded paths.
    programs.fzf = {
      enable = true;
    };

    home.shellAliases = {
      cat = "bat";
      ga = "git add";
      gc = "git commit";
      gcm = "git commit -m";
    };

    xdg.configFile."zsh/rc.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zsh/rc.zsh";
    xdg.configFile."zsh/aliases".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zsh/aliases";
    xdg.configFile."zsh/cmds".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zsh/cmds";
    xdg.configFile."zsh/p10k.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zsh/p10k.zsh";
    xdg.configFile."zsh/bm-dirs".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zsh/bm-dirs";
    xdg.configFile."zsh/completions".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zsh/completions";

    home.packages = with pkgs; [
      fortune
      cowsay
      lolcat
    ];


    programs.starship.enable = false;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
in
if standaloneHome then userConfig { inherit config lib; } else { home-manager.users.${username} = userConfig; }
