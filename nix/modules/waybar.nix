{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    waybar

    # Deps of the waybar config and status-bar scripts
    jq
    curl
    pavucontrol
    networkmanagerapplet
  ];

  home-manager.users.yeet = {
    home.file.".config/waybar".source = ../../.config/waybar;
  };
}
