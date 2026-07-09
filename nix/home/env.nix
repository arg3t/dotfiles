{ pkgs, username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    # Manages XDG base dirs declaratively (XDG_CONFIG_HOME, XDG_DATA_HOME,
    # XDG_CACHE_HOME) instead of exporting them in .profile.
    xdg.enable = true;

    home.sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "alacritty";
      OPENER = "xdg-open";

      BAT_THEME = "Catppuccin Mocha";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # Keep tool homes out of ~. Note: no session variable may reference
      # another session variable, so these are spelled out.
      CARGO_HOME = "$HOME/.local/share/cargo";
      GOPATH = "$HOME/.local/share/go";
      GNUPGHOME = "$HOME/.local/share/gnupg";

      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
      MPV_IPC = "$XDG_RUNTIME_DIR/mpv.socket";
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

    xdg.mimeApps = {
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
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
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
        "application/rtf" = [ "libreoffice-writer.desktop" "nvim.desktop" ];
        "text/x-java-source" = "vim.desktop";
        "x-scheme-handler/tg" = [ "userapp-Telegram Desktop-APVS20.desktop" "org.telegram.desktop.desktop" ];
        "application/x-rdp" = "vim.desktop";
        "text/markdown" = "nvim.desktop";
        "application/pdf" = "zaread.desktop";
        "text/plain" = "nvim.desktop";
        "x-scheme-handler/https" = [ "firefox.desktop" "userapp-Firefox-HRFVY1.desktop" "zen.desktop" ];
        "video/x-matroska" = "vlc.desktop";
        "x-scheme-handler/mailto" = "thunderbird.desktop";
        "x-scheme-handler/mid" = "thunderbird.desktop";
        "x-scheme-handler/feed" = "thunderbird.desktop";
        "application/rss+xml" = "thunderbird.desktop";
        "application/x-extension-rss" = "thunderbird.desktop";
        "x-scheme-handler/webcal" = "thunderbird.desktop";
        "x-scheme-handler/webcals" = "thunderbird.desktop";
        "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
        "x-scheme-handler/http" = [ "firefox.desktop" "zen.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" "zen.desktop" ];
        "text/html" = [ "zen.desktop" "firefox.desktop" ];
        "application/x-extension-htm" = [ "zen.desktop" "firefox.desktop" ];
        "application/x-extension-html" = [ "zen.desktop" "firefox.desktop" ];
        "application/x-extension-shtml" = [ "zen.desktop" "firefox.desktop" ];
        "application/xhtml+xml" = [ "zen.desktop" "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "zen.desktop" "firefox.desktop" ];
        "application/x-extension-xht" = [ "zen.desktop" "firefox.desktop" ];
      };
    };

    xdg.dataFile."applications/mimeapps.list".force = true;

    xdg.configFile."pavucontrol.ini".source = (pkgs.runCommandLocal "pavucontrol.ini" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
W3dpbmRvd10Kd2lkdGg9NTAwCmhlaWdodD00MDAKc2lua0lucHV0VHlwZT0xCnNvdXJjZU91dHB1dFR5cGU9MQpzaW5rVHlwZT0wCnNvdXJjZVR5cGU9MQpzaG93Vm9sdW1lTWV0ZXJzPTEKaGlkZVVuYXZhaWxhYmxlQ2FyZFByb2ZpbGVzPTAK
EOF
      '');

    xdg.configFile."fontconfig/fonts.conf".source = (pkgs.runCommandLocal "fonts.conf" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIGZvbnRjb25maWcgU1lTVEVNICJmb250cy5kdGQiPgo8Zm9udGNvbmZpZz4KICAgIDxtYXRjaCB0YXJnZXQ9ImZvbnQiPgogICAgICAgIDxlZGl0IG5hbWU9ImFudGlhbGlhcyIgbW9kZT0iYXNzaWduIj4KICAgICAgICAgICAgPGJvb2w+dHJ1ZTwvYm9vbD4KICAgICAgICA8L2VkaXQ+CiAgICAgICAgPGVkaXQgbmFtZT0iaGludGluZyIgbW9kZT0iYXNzaWduIj4KICAgICAgICAgICAgPGJvb2w+ZmFsc2U8L2Jvb2w+CiAgICAgICAgPC9lZGl0PgogICAgICAgIDxlZGl0IG5hbWU9ImhpbnRzdHlsZSIgbW9kZT0iYXNzaWduIj4KICAgICAgICAgICAgPGNvbnN0PmhpbnRzbGlnaHQ8L2NvbnN0PgogICAgICAgIDwvZWRpdD4KICAgICAgICA8ZWRpdCBuYW1lPSJyZ2JhIiBtb2RlPSJhc3NpZ24iPgogICAgICAgICAgICA8Y29uc3Q+cmdiPC9jb25zdD4KICAgICAgICA8L2VkaXQ+CiAgICAgICAgPGVkaXQgbmFtZT0iYXV0b2hpbnQiIG1vZGU9ImFzc2lnbiI+CiAgICAgICAgICAgIDxib29sPmZhbHNlPC9ib29sPgogICAgICAgIDwvZWRpdD4KICAgICAgICA8ZWRpdCBuYW1lPSJsY2RmaWx0ZXIiIG1vZGU9ImFzc2lnbiI+CiAgICAgICAgICAgIDxjb25zdD5sY2RkZWZhdWx0PC9jb25zdD4KICAgICAgICA8L2VkaXQ+CiAgICAgICAgPGVkaXQgbmFtZT0iZHBpIiBtb2RlPSJhc3NpZ24iPgogICAgICAgICAgICA8ZG91YmxlPjEwMjwvZG91YmxlPgogICAgICAgIDwvZWRpdD4KICAgIDwvbWF0Y2g+CjwvZm9udGNvbmZpZz4K
EOF
      '');

    xdg.configFile."htop/htoprc".source = (pkgs.runCommandLocal "htoprc" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
IyBCZXdhcmUhIFRoaXMgZmlsZSBpcyByZXdyaXR0ZW4gYnkgaHRvcCB3aGVuIHNldHRpbmdzIGFyZSBjaGFuZ2VkIGluIHRoZSBpbnRlcmZhY2UuCiMgVGhlIHBhcnNlciBpcyBhbHNvIHZlcnkgcHJpbWl0aXZlLCBhbmQgbm90IGh1bWFuLWZyaWVuZGx5LgpodG9wX3ZlcnNpb249My40LjEtMy40LjEKY29uZmlnX3JlYWRlcl9taW5fdmVyc2lvbj0zCmZpZWxkcz0wIDQ4IDE3IDE4IDM4IDM5IDQwIDIgMCAxMTkgNDYgNDcgNDkgMQpoaWRlX2tlcm5lbF90aHJlYWRzPTEKaGlkZV91c2VybGFuZF90aHJlYWRzPTEKaGlkZV9ydW5uaW5nX2luX2NvbnRhaW5lcj0wCnNoYWRvd19vdGhlcl91c2Vycz0wCnNob3dfdGhyZWFkX25hbWVzPTAKc2hvd19wcm9ncmFtX3BhdGg9MQpoaWdobGlnaHRfYmFzZV9uYW1lPTEKaGlnaGxpZ2h0X2RlbGV0ZWRfZXhlPTEKc2hhZG93X2Rpc3RyaWJ1dGlvbl9wYXRoX3ByZWZpeD0wCmhpZ2hsaWdodF9tZWdhYnl0ZXM9MQpoaWdobGlnaHRfdGhyZWFkcz0xCmhpZ2hsaWdodF9jaGFuZ2VzPTAKaGlnaGxpZ2h0X2NoYW5nZXNfZGVsYXlfc2Vjcz01CmZpbmRfY29tbV9pbl9jbWRsaW5lPTEKc3RyaXBfZXhlX2Zyb21fY21kbGluZT0xCnNob3dfbWVyZ2VkX2NvbW1hbmQ9MQpoZWFkZXJfbWFyZ2luPTEKc2NyZWVuX3RhYnM9MApkZXRhaWxlZF9jcHVfdGltZT0wCmNwdV9jb3VudF9mcm9tX29uZT0xCnNob3dfY3B1X3VzYWdlPTEKc2hvd19jcHVfZnJlcXVlbmN5PTEKc2hvd19jcHVfdGVtcGVyYXR1cmU9MQpkZWdyZWVfZmFocmVuaGVpdD0wCnNob3dfY2FjaGVkX21lbW9yeT0xCnVwZGF0ZV9wcm9jZXNzX25hbWVzPTAKYWNjb3VudF9ndWVzdF9pbl9jcHVfbWV0ZXI9MApjb2xvcl9zY2hlbWU9MAplbmFibGVfbW91c2U9MQpkZWxheT0xNQpoaWRlX2Z1bmN0aW9uX2Jhcj0wCmhlYWRlcl9sYXlvdXQ9dHdvXzUwXzUwCmNvbHVtbl9tZXRlcnNfMD1MZWZ0Q1BVczIgQ1BVIEJhdHRlcnkgQmxhbmsgQmxhbmsgQmxhbmsgTWVtb3J5IE5ldHdvcmtJTyBEaXNrSU8KY29sdW1uX21ldGVyX21vZGVzXzA9MSAxIDEgMiAyIDIgMyA0IDQKY29sdW1uX21ldGVyc18xPVJpZ2h0Q1BVczIgTWVtb3J5IFN3YXAgQmxhbmsgQmxhbmsgQmxhbmsgTG9hZEF2ZXJhZ2UgVXB0aW1lIFRhc2tzCmNvbHVtbl9tZXRlcl9tb2Rlc18xPTEgMSAxIDIgMiAyIDMgNCA0CnRyZWVfdmlldz0wCnNvcnRfa2V5PTQ2CnRyZWVfc29ydF9rZXk9MApzb3J0X2RpcmVjdGlvbj0tMQp0cmVlX3NvcnRfZGlyZWN0aW9uPTEKdHJlZV92aWV3X2Fsd2F5c19ieV9waWQ9MAphbGxfYnJhbmNoZXNfY29sbGFwc2VkPTAKc2NyZWVuOk1haW49UElEIFVTRVIgUFJJT1JJVFkgTklDRSBNX1ZJUlQgTV9SRVNJREVOVCBNX1NIQVJFIFNUQVRFIFBJRCBNX1NXQVAgUEVSQ0VOVF9DUFUgUEVSQ0VOVF9NRU0gVElNRSBDb21tYW5kCi5zb3J0X2tleT1QRVJDRU5UX0NQVQoudHJlZV9zb3J0X2tleT1QSUQKLnRyZWVfdmlld19hbHdheXNfYnlfcGlkPTAKLnRyZWVfdmlldz0wCi5zb3J0X2RpcmVjdGlvbj0tMQoudHJlZV9zb3J0X2RpcmVjdGlvbj0xCi5hbGxfYnJhbmNoZXNfY29sbGFwc2VkPTAKc2NyZWVuOkkvTz1QSUQgVVNFUiBJT19QUklPUklUWSBJT19SQVRFIElPX1JFQURfUkFURSBJT19XUklURV9SQVRFIFBFUkNFTlRfU1dBUF9ERUxBWSBQRVJDRU5UX0lPX0RFTEFZIENvbW1hbmQKLnNvcnRfa2V5PUlPX1JBVEUKLnRyZWVfc29ydF9rZXk9UElECi50cmVlX3ZpZXdfYWx3YXlzX2J5X3BpZD0wCi50cmVlX3ZpZXc9MAouc29ydF9kaXJlY3Rpb249LTEKLnRyZWVfc29ydF9kaXJlY3Rpb249MQouYWxsX2JyYW5jaGVzX2NvbGxhcHNlZD0wCg==
EOF
      '');
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
