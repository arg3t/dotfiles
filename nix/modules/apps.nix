{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    slack
    zed-editor
    vscodium
    discord
    chromium
    spotify
    wireguard-tools
  ];

  services.tailscale.enable = true;

  # WireGuard: tools installed; configure tunnels via NetworkManager
  # (native wg support) or add networking.wireguard.interfaces here later.
}
