{ pkgs, ... }:

let
  # flameshot is X11-native; under Hyprland it has no native Wayland grab
  # path, so the GrimAdapter only fires when $XDG_CURRENT_DESKTOP matches a
  # wlroots-style string. Wrap every flameshot binary with that env (and
  # QT_QPA_PLATFORM=wayland so the Qt UI uses the Wayland plugin) so any
  # launch path — keybind, dmenu, autostart — picks up the right
  # environment without per-invocation env hacks.
  flameshot-wrapped = pkgs.symlinkJoin {
    name = "flameshot-${pkgs.flameshot.version}";
    paths = [ pkgs.flameshot ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/flameshot \
        --set XDG_CURRENT_DESKTOP sway \
        --set QT_QPA_PLATFORM wayland \
        --set QT_AUTO_SCREEN_SCALE_FACTOR 0 \
        --set QT_SCREEN_SCALE_FACTORS 1
    '';
  };
in
{
  programs.hyprland.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;
  programs.ssh.startAgent = false;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    kitty
    alacritty
    alacritty.terminfo
    bemenu
    j4-dmenu-desktop
    cliphist
    alsa-utils
    mako
    grim
    slurp
    wl-clipboard
    libnotify
    waybar
    eww
    pavucontrol
    networkmanagerapplet
    xfce4-power-manager
    nemo
    glib
    lf
    flameshot-wrapped
    zathura
    syshud
    satty
    wf-recorder
    playerctl
    hyprpicker
    pamixer
    wireplumber
    brightnessctl
    wl-gammarelay-rs
    bc
    pass
    hyprpaper
    hyprlock
    hypridle
  ];

  home-manager.users.yeet = { config, ... }: {
    home.file.".config/hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hypr";

    home.file.".config/hypr-own".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hypr/default";

    xdg.configFile."flameshot/flameshot.ini".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/flameshot/flameshot.ini";

    xdg.configFile."mako/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/mako/config";

    xdg.configFile."wofi/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/wofi/config";
    xdg.configFile."wofi/style.css".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/wofi/style.css";

    xdg.configFile."bemenu/config.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/bemenu/config.sh";

    home.file.".config/waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/waybar";

    home.file.".config/eww".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/eww";

    systemd.user.services.update-wallpaper = {
      Unit = {
        Description = "Update wallpaper";
        After = [
          "graphical-session.target"
          "sync-backgrounds.service"
        ];
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

    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
    };

    home.pointerCursor = {
      package = pkgs.catppuccin-cursors.mochaMauve;
      name = "catppuccin-mocha-mauve-cursors";
      size = 18;
      gtk.enable = true;
      hyprcursor.enable = true;
    };
  };
}
