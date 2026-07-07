{ ... }:

{
  home-manager.users.yeet = {
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

      if [ -f "$HOME/.config/config.env.local" ]; then
        . "$HOME/.config/config.env.local"
      fi
    '';
  };
}
