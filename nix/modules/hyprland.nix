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
    noto-fonts-emoji
  ];

  environment.systemPackages = with pkgs; [
    kitty
    alacritty
    firefox
    bemenu
    mako
    grim
    slurp
    wl-clipboard
    hyprpaper
    hyprlock
    hypridle
  ];

  home-manager.users.yeet = { config, ... }: {
    # Out-of-store symlink: hypr config stays live-editable in ~/dotfiles
    # (the repo dir also contains the machine-local `own` symlink).
    home.file.".config/hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.config/hypr";
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
