{ pkgs, ... }:

{
  programs.hyprland.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

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
    firefox
    bemenu
    j4-dmenu-desktop
    cliphist
    alsa-utils
    mako
    grim
    slurp
    wl-clipboard
    hyprpaper
    hyprlock
    hypridle
  ];

  home-manager.users.yeet = { config, ... }: {
    # Out-of-store symlink: hypr config stays live-editable in ~/.dots.
    home.file.".config/hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hypr";

    # Machine variant (default/desktop/tarnag/thinker), declared per host.
    # hyprland.conf sources ~/.config/hypr-own/*.conf.
    home.file.".config/hypr-own".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hypr/default";

    home.file.".config/mako".source = ../../.config/mako;
    home.file.".config/wofi".source = ../../.config/wofi;
    home.file.".config/bemenu".source = ../../.config/bemenu;

    home.pointerCursor = {
      package = pkgs.catppuccin-cursors.mochaMauve;
      name = "catppuccin-mocha-mauve-cursors";
      size = 18;
      gtk.enable = true;
      hyprcursor.enable = true;
    };
  };
}
