{ pkgs, ... }:

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

  services.tailscale.enable = true;
}
