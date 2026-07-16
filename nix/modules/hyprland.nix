{ pkgs, ... }:

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
    flameshot
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

    xdg.configFile."mako/config".source = ../../.config/mako/config;

    xdg.configFile."wofi/config".source = ../../.config/wofi/config;
    xdg.configFile."wofi/style.css".source = ../../.config/wofi/style.css;

    xdg.configFile."bemenu/config.sh".source = ../../.config/bemenu/config.sh;

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
