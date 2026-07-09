{ pkgs, ... }:

let
  catppuccinThunderbird = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "thunderbird";
    rev = "0289f3bd9566f9666682f66a3355155c0d0563fc";
    hash = "sha256-07gT37m1+OhRTbUk51l0Nhx+I+tl1il5ayx2ow23APY=";
  };
  catppuccinMochaMauve = "${catppuccinThunderbird}/themes/mocha/mocha-mauve.xpi";
in

{
  environment.systemPackages = with pkgs; [
    slack
    zed-editor
    vscodium
    discord
    chromium
    spotify
    signal-desktop
    wireguard-tools
  ];

  programs.thunderbird = {
    enable = true;
    policies = {
      OfferToSaveLogins = true;
      PasswordManagerEnabled = true;
      ExtensionSettings."{47f5c9df-1d03-5424-ae9e-0613b69a9d2f}" = {
        installation_mode = "force_installed";
        install_url = "file://${catppuccinMochaMauve}";
      };
    };
    preferences = {
      "calendar.network.multirealm" = false;
      "mail.shell.checkDefaultClient" = false;
      "signon.rememberSignons" = true;
    };
  };

  services.tailscale.enable = true;
}
