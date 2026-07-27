{ pkgs, username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    gtk = {
      enable = true;

      theme = {
        name = "catppuccin-mocha-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
          variant = "mocha";
        };
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "mauve";
        };
      };

      font = {
        name = "Noto Sans";
        size = 10;
      };

      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=catppuccin-mocha-mauve
    '';
    xdg.configFile."Kvantum/catppuccin-mocha-mauve".source =
      "${pkgs.catppuccin-kvantum.override { variant = "mocha"; accent = "mauve"; }}/share/Kvantum/catppuccin-mocha-mauve";

    home.sessionVariables.GTK_THEME = "catppuccin-mocha-mauve-standard";
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
