{ ... }:

{
  # Time-of-day wallpaper rotation: HM-managed systemd user units running the
  # existing ~/.local/bin/update_wallpaper script (picks a random image from
  # ~/.local/backgrounds/{morning,afternoon,evening} via hyprpaper).
  home-manager.users.yeet = { config, ... }: {
    systemd.user.services.update-wallpaper = {
      Unit = {
        Description = "Update wallpaper";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "%h/.local/bin/update_wallpaper";
      };
    };

    systemd.user.timers.update-wallpaper = {
      Unit.Description = "Rotate wallpaper every 10 minutes";
      Timer = {
        OnActiveSec = "15sec";
        OnUnitActiveSec = "10min";
        Unit = "update-wallpaper.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };

    # Wallpapers are content, not config: keep them in the repo and link them.
    home.file.".local/backgrounds".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.local/backgrounds";
  };
}
