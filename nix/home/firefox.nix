{ pkgs, username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    programs.firefox = {
      enable = true;
      # nixpkgs' Firefox package is Linux-only. On Darwin, manage the native
      # Firefox installation's profile and policies without installing it.
      package = if pkgs.stdenv.isDarwin then null else pkgs.firefox;

      policies = {
        # Bitwarden handles passwords; kill the built-in manager.
        PasswordManagerEnabled = false;
        OfferToSaveLogins = false;
        AutofillCreditCardEnabled = false;
        # Force-installed, auto-updating extensions from AMO.
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            # Bitwarden
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          };
          "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
            # Vimium
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          };
          "enhancerforyoutube@maximerf.addons.mozilla.org" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
          };
          "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = {
            # Stylus (for catppuccin userstyles)
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
          };
          "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}" = {
            # Catppuccin Mocha Mauve browser theme
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-mocha-mauve-git/latest.xpi";
          };
        };
      };

      profiles.yeet = {
        isDefault = true;

        settings = {
          # Wayland/perf
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.use-xdg-desktop-portal.file-picker" = 1;

          # Let the catppuccin theme apply to about: pages
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "extensions.activeThemeID" = "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}";
        };
      };
    };
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
