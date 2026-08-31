{
  pkgs,
  config,
  lib,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

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
        "typeset -f _zt_mark >/dev/null && _zt_mark pre_compinit"
        "autoload -U compinit"
        "() { local d=( \"\${ZDOTDIR}/.zcompdump\"(N.mh-24) ); if (( \$#d )); then compinit -C; else compinit; fi }"
        "typeset -f _zt_mark >/dev/null && _zt_mark post_compinit"
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
      ]
      ++ lib.optional pkgs.stdenv.isDarwin {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        file = "fzf-tab.plugin.zsh";
      }
      ++ [
        {
          name = "zsh-completions";
          src = "${pkgs.zsh-completions}/share/zsh/site-functions";
        }
      ];

      # p10k instant prompt must run before anything that prints (mkOrder 500
      # puts it at the very top of .zshrc); personal config loads last.
      initContent = lib.mkMerge [
        # startup profiling: per-segment checkpoints -> $XDG_CACHE_HOME/zsh-startup.log
        (lib.mkOrder 490 ''
          zmodload zsh/datetime 2>/dev/null
          typeset -gA _ZT_MARKS
          typeset -ga _ZT_ORDER
          _zt_mark() { _ZT_MARKS[$1]=$EPOCHREALTIME; _ZT_ORDER+=($1); }
          _zt_mark start
          _zt_flush() {
            autoload -Uz add-zsh-hook
            add-zsh-hook -d precmd _zt_flush
            _zt_mark first_prompt
            local log="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh-startup.log" line seg prev
            line="$(strftime %Y-%m-%dT%H:%M:%S $EPOCHSECONDS)"
            line+=" total=$(printf %.3f $(( _ZT_MARKS[first_prompt] - _ZT_MARKS[start] )))"
            prev=$_ZT_MARKS[start]
            for seg in $_ZT_ORDER; do
              line+=" ''${seg}=$(printf %.3f $(( _ZT_MARKS[$seg] - prev )))"
              prev=$_ZT_MARKS[$seg]
            done
            print -r -- "$line" >> "$log"
          }
          autoload -Uz add-zsh-hook
          add-zsh-hook precmd _zt_flush
        '')
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
    # Native zsh hook disabled; re-added with startup marks in rc.zsh.
    programs.zoxide = {
      enable = true;
      enableZshIntegration = false;
    };

    # fzf keybindings/completion; native hook disabled, re-added in rc.zsh.
    programs.fzf = {
      enable = true;
      enableZshIntegration = false;
    };

    home.shellAliases = {
      cat = "bat -p --paging=never";
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
      our.lolcrab
    ];

    programs.starship.enable = false;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # Native zsh hook disabled; re-added with startup marks in rc.zsh.
      enableZshIntegration = false;
    };
  };
in
if standaloneHome then
  userConfig { inherit config lib; }
else
  { home-manager.users.${username} = userConfig; }
