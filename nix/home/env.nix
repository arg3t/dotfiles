{
  pkgs,
  config,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = { config, lib, ... }: {
    # Manages XDG base dirs declaratively (XDG_CONFIG_HOME, XDG_DATA_HOME,
    # XDG_CACHE_HOME) instead of exporting them in .profile.
    xdg.enable = true;

    home.sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "alacritty";

      BAT_THEME = "Catppuccin Mocha";

      # Keep tool homes out of ~. Note: no session variable may reference
      # another session variable, so these are spelled out.
      CARGO_HOME = "$HOME/.local/share/cargo";
      GOPATH = "$HOME/.local/share/go";
      GNUPGHOME = "$HOME/.local/share/gnupg";
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      OPENER = "xdg-open";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
      MPV_IPC = "$XDG_RUNTIME_DIR/mpv.socket";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      OPENER = "open";
      MPV_IPC = "$TMPDIR/mpv.socket";
    };

    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/cargo/bin"
      "$HOME/.local/share/go/bin"
    ];

    # Script-facing config; status-bar scripts `source ~/.config/config.env`.
    # Machine-local secrets go in ~/.config/config.env.local (untracked).
    home.file.".config/config.env".text = ''
      LOCATION=Delft
      BUIENRADAR=1
      BATTERY=/sys/class/power_supply/BAT0

      if [ -f "$HOME/.config/config.env.local" ]; then
        . "$HOME/.config/config.env.local"
      fi
    '';

    xdg.mimeApps = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/jetbrains" = "jetbrains-toolbox.desktop";
        "x-scheme-handler/mailspring" = "mailspring.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "image/png" = "sxiv.desktop";
        "image/jpeg" = "sxiv.desktop";
        "text/plain" = "vim.desktop";
        "x-scheme-handler/postman" = "Postman.desktop";
        "x-scheme-handler/gitkraken" = "GitKraken.desktop";
        "x-scheme-handler/ssh" = "ktelnetservice5.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "vlc.desktop";
        "text/html" = "firefox.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "libreoffice-writer.desktop";
        "application/x-shellscript" = "vim.desktop";
        "inode/directory" = "lf.desktop";
        "application/x-gnome-saved-search" = "lf.desktop";
        "application/pdf" = "zathura.desktop";
        "application/epub" = "zathura.desktop";
        "video/webm" = "mpv.desktop";
        "application/zip" = "engrampa.desktop";
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
        "x-scheme-handler/mailto" = "thunderbird.desktop";
        "message/rfc822" = "thunderbird.desktop";
        "application/x-directory" = "lf.desktop";
        "x-scheme-handler/discord-474605546457137157" = "discord-474605546457137157.desktop";
        "x-scheme-handler/msteams" = "teams.desktop";
        "x-scheme-handler/discord-402572971681644545" = "discord-402572971681644545.desktop";
        "x-scheme-handler/discord-378347429537251328" = "discord-378347429537251328.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
        "application/x-extension-htm" = "firefox.desktop";
        "application/x-extension-html" = "firefox.desktop";
        "application/x-extension-shtml" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/x-extension-xhtml" = "firefox.desktop";
        "application/x-extension-xht" = "firefox.desktop";
        "x-scheme-handler/discord-589393213723246592" = "discord-589393213723246592.desktop";
        "x-scheme-handler/discord-1170028348756471908" = "discord-1170028348756471908.desktop";
        "x-scheme-handler/mid" = "thunderbird.desktop";
        "x-scheme-handler/feed" = "thunderbird.desktop";
        "application/rss+xml" = "thunderbird.desktop";
        "application/x-extension-rss" = "thunderbird.desktop";
        "x-scheme-handler/webcal" = "thunderbird.desktop";
        "text/calendar" = "thunderbird.desktop";
        "application/x-extension-ics" = "thunderbird.desktop";
        "x-scheme-handler/webcals" = "thunderbird.desktop";
        "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
        "x-scheme-handler/betterdiscord" = "discord.desktop";
      };
      associations.added = {
        "application/rtf" = [
          "libreoffice-writer.desktop"
          "nvim.desktop"
        ];
        "text/x-java-source" = "vim.desktop";
        "x-scheme-handler/tg" = [
          "userapp-Telegram Desktop-APVS20.desktop"
          "org.telegram.desktop.desktop"
        ];
        "application/x-rdp" = "vim.desktop";
        "text/markdown" = "nvim.desktop";
        "application/pdf" = "zaread.desktop";
        "text/plain" = "nvim.desktop";
        "x-scheme-handler/https" = [
          "firefox.desktop"
          "userapp-Firefox-HRFVY1.desktop"
          "zen.desktop"
        ];
        "video/x-matroska" = "vlc.desktop";
        "x-scheme-handler/mailto" = "thunderbird.desktop";
        "x-scheme-handler/mid" = "thunderbird.desktop";
        "x-scheme-handler/feed" = "thunderbird.desktop";
        "application/rss+xml" = "thunderbird.desktop";
        "application/x-extension-rss" = "thunderbird.desktop";
        "x-scheme-handler/webcal" = "thunderbird.desktop";
        "x-scheme-handler/webcals" = "thunderbird.desktop";
        "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
        "x-scheme-handler/http" = [
          "firefox.desktop"
          "zen.desktop"
        ];
        "x-scheme-handler/chrome" = [
          "firefox.desktop"
          "zen.desktop"
        ];
        "text/html" = [
          "zen.desktop"
          "firefox.desktop"
        ];
        "application/x-extension-htm" = [
          "zen.desktop"
          "firefox.desktop"
        ];
        "application/x-extension-html" = [
          "zen.desktop"
          "firefox.desktop"
        ];
        "application/x-extension-shtml" = [
          "zen.desktop"
          "firefox.desktop"
        ];
        "application/xhtml+xml" = [
          "zen.desktop"
          "firefox.desktop"
        ];
        "application/x-extension-xhtml" = [
          "zen.desktop"
          "firefox.desktop"
        ];
        "application/x-extension-xht" = [
          "zen.desktop"
          "firefox.desktop"
        ];
      };
    };

    xdg.dataFile."applications/mimeapps.list" = lib.mkIf pkgs.stdenv.isLinux {
      force = true;
    };

    xdg.configFile."pavucontrol.ini" = lib.mkIf pkgs.stdenv.isLinux {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/pavucontrol.ini";
    };

    xdg.configFile."fontconfig/fonts.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/fontconfig/fonts.conf";

    xdg.configFile."htop/htoprc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/htop/htoprc";
  };
in
if standaloneHome then
  userConfig { inherit config; }
else
  { home-manager.users.${username} = userConfig; }
