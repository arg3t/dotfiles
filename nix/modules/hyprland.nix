{ pkgs, ... }:

{
  programs.hyprland.enable = true;

  # Removable media: udisks2 (mount as user, no sudo), gvfs (nemo/gio mounts,
  # trash, MTP, smb/dav), tumbler (thumbnails).
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

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
    pavucontrol
    networkmanagerapplet
    xfce4-power-manager
    nemo
    glib # gio CLI for gvfs mounts/trash
    lf
    flameshot
    zathura
    syshud
    thunderbird
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
    # Out-of-store symlink: hypr config stays live-editable in ~/.dots.
    home.file.".config/hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hypr";

    # Machine variant (default/desktop/tarnag/thinker), declared per host.
    # hyprland.conf sources ~/.config/hypr-own/*.conf.
    home.file.".config/hypr-own".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hypr/default";

    xdg.configFile."mako/config".source = (pkgs.runCommandLocal "mako-config" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
IyBNYWtvIGNvbmZpZ3VyYXRpb24KIyBHbG9iYWwgc2V0dGluZ3MKZm9udD1DYXNrYXlkaWFDb3ZlIE5lcmQgRm9udCAxMAptYXJrdXA9MQpzb3J0PS10aW1lCmxheWVyPW92ZXJsYXkKYW5jaG9yPXRvcC1yaWdodAp3aWR0aD00MDAKaGVpZ2h0PTEwMAptYXJnaW49NQpwYWRkaW5nPTEwCmJvcmRlci1zaXplPTEKYm9yZGVyLXJhZGl1cz0wCmRlZmF1bHQtdGltZW91dD01MDAwCmlnbm9yZS10aW1lb3V0PTAKbWF4LXZpc2libGU9LTEKYm9yZGVyLXNpemU9MAoKIyBDb2xvcnMgYW5kIGFwcGVhcmFuY2UKYmFja2dyb3VuZC1jb2xvcj0jMUUxRTJFCnRleHQtY29sb3I9I0NERDZGNApib3JkZXItY29sb3I9I0I3QTZGMQpwcm9ncmVzcy1jb2xvcj0jQjdBNkYxCgojIEljb24gc2V0dGluZ3MKaWNvbi1wYXRoPS91c3Ivc2hhcmUvaWNvbnMvQWR3YWl0YS8KbWF4LWljb24tc2l6ZT0zMgoKIyBBY3Rpb25zCm9uLWJ1dHRvbi1sZWZ0PWRpc21pc3MKb24tYnV0dG9uLW1pZGRsZT1pbnZva2UtZGVmYXVsdC1hY3Rpb24Kb24tYnV0dG9uLXJpZ2h0PWRpc21pc3MtYWxsCgojIEZvcm1hdApmb3JtYXQ9PGI+JWE8L2I+XG4lc1xuJWIKCiMgQ3JpdGVyaWEtYmFzZWQgcnVsZXMKW3VyZ2VuY3k9bG93XQpkZWZhdWx0LXRpbWVvdXQ9NTAwMAoKW3VyZ2VuY3k9bm9ybWFsXQpkZWZhdWx0LXRpbWVvdXQ9NTAwMAoKW3VyZ2VuY3k9Y3JpdGljYWxdCmJvcmRlci1jb2xvcj0jRkFCMzg3CmRlZmF1bHQtdGltZW91dD0wCmlnbm9yZS10aW1lb3V0PTEKClttb2RlPWRuZF0KaW52aXNpYmxlPTEKCiMgdmltOiBmdD1jZmcK
EOF
      '');

    xdg.configFile."wofi/config".source = (pkgs.runCommandLocal "wofi-config" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
IyBXb2ZpIGNvbmZpZ3VyYXRpb24gZmlsZQojIFNhdmUgYXMgfi8uY29uZmlnL3dvZmkvY29uZmlnCgojIEJhc2ljIGJlaGF2aW9yCm1vZGU9ZHJ1bgphbGxvd19tYXJrdXA9ZmFsc2UKYWxsb3dfaW1hZ2VzPWZhbHNlCmltYWdlX3NpemU9MTYKaW5zZW5zaXRpdmU9dHJ1ZQpoaWRlX3Njcm9sbD10cnVlCm5vX2FjdGlvbnM9dHJ1ZQoKIyBQb3NpdGlvbmluZyBhbmQgc2l6ZSAobWF0Y2hpbmcgZG1lbnUgb2Zmc2V0IGFuZCBtYXJnaW4pCng9NQp5PS0yNQp3aWR0aD00MDAKaGVpZ2h0PTMwMAoKIyBQcm9tcHQgdGV4dApwcm9tcHQ9U2VsZWN0IGFuIG9wdGlvbgoKIyBGaWx0ZXIgbW9kZQptYXRjaGluZz1mdXp6eQoKIyBPdGhlciBvcHRpb25zCnNpbmdsZV9jbGljaz1mYWxzZQpwYXJzZV9zZWFyY2g9ZmFsc2UKcHJpbnRfY29tbWFuZD10cnVlCg==
EOF
      '');
    xdg.configFile."wofi/style.css".source = (pkgs.runCommandLocal "wofi-style.css" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
KiB7CiAgICBmb250LWZhbWlseTogIkNhc2theWRpYUNvdmUgTmVyZCBGb250IE1vbm8iLCAiU3ltYm9sYSIsICJKb3lQaXhlbHMiLCBtb25vc3BhY2U7CiAgICBmb250LXNpemU6IDEwcHQ7Cn0KCndpbmRvdyB7CiAgICBtYXJnaW46IDIwcHg7CiAgICBib3JkZXI6IDFweCBzb2xpZCAjY2NjOwogICAgYmFja2dyb3VuZC1jb2xvcjogIzIyMjIyMjsKICAgIGNvbG9yOiAjYmJiYmJiOwogICAgYm9yZGVyLXJhZGl1czogMHB4Owp9CgojaW5wdXQgewogICAgbWFyZ2luOiA1cHg7CiAgICBib3JkZXI6IG5vbmU7CiAgICBjb2xvcjogI2ZmZmZmZjsKICAgIGJhY2tncm91bmQtY29sb3I6ICMyMjIyMjI7CiAgICBmb250LWZhbWlseTogIkNhc2theWRpYUNvdmUgTmVyZCBGb250IE1vbm8iLCBtb25vc3BhY2U7CiAgICBmb250LXNpemU6IDEwcHQ7CiAgICBtaW4taGVpZ2h0OiAyN3B4Owp9CgojaW5uZXItYm94IHsKICAgIG1hcmdpbjogNXB4OwogICAgYm9yZGVyOiBub25lOwogICAgYmFja2dyb3VuZC1jb2xvcjogIzIyMjIyMjsKfQoKI291dGVyLWJveCB7CiAgICBtYXJnaW46IDBweDsKICAgIGJvcmRlcjogbm9uZTsKICAgIGJhY2tncm91bmQtY29sb3I6ICMyMjIyMjI7Cn0KCiNzY3JvbGwgewogICAgbWFyZ2luOiAwcHg7CiAgICBib3JkZXI6IG5vbmU7Cn0KCiN0ZXh0IHsKICAgIG1hcmdpbjogNXB4OwogICAgYm9yZGVyOiBub25lOwogICAgY29sb3I6ICNiYmJiYmI7CiAgICBmb250LWZhbWlseTogIkNhc2theWRpYUNvdmUgTmVyZCBGb250IE1vbm8iLCBtb25vc3BhY2U7CiAgICBmb250LXNpemU6IDEwcHQ7CiAgICBtaW4taGVpZ2h0OiAyN3B4Owp9CgojZW50cnkgewogICAgYm9yZGVyOiBub25lOwogICAgbWFyZ2luOiAxcHg7CiAgICBtaW4taGVpZ2h0OiAyN3B4OwogICAgYmFja2dyb3VuZC1jb2xvcjogdHJhbnNwYXJlbnQ7Cn0KCiNlbnRyeTpzZWxlY3RlZCB7CiAgICBiYWNrZ3JvdW5kLWNvbG9yOiAjMDA1NTc3OwogICAgY29sb3I6ICNmZmZmZmY7Cn0KCiNlbnRyeTpob3ZlciB7CiAgICBiYWNrZ3JvdW5kLWNvbG9yOiAjMDA1NTc3OwogICAgY29sb3I6ICNmZmZmZmY7Cn0K
EOF
      '');

    xdg.configFile."bemenu/config.sh".source = (pkgs.runCommandLocal "bemenu-config.sh" { } ''
        ${pkgs.coreutils}/bin/base64 -d > $out <<'EOF'
ZXhwb3J0IEJFTUVOVV9PUFRTPSItLWlnbm9yZWNhc2UgXAotLXByb21wdCAnU2VsZWN0IGFuIG9wdGlvbicgXAotLWxpbmUtaGVpZ2h0IDI1IFwKLS1mbiAnQ2Fza2F5ZGlhQ292ZSBOZXJkIEZvbnQgMTAnIFwKLS10YiAnI0FDQTNFQicgXAotLXRmICcjMWUxZTJlJyBcCi0tZmIgJyMxZTFlMmUnIFwKLS1ocCAnOHB4JyBcCi0tZmYgJyNjZGQ2ZjQnIFwKLS1uYiAnIzFlMWUyZScgXAotLW5mICcjY2RkNmY0JyBcCi0tYWIgJyMxZTFlMmUnIFwKLS1hZiAnI2NkZDZmNCcgXAotLWhiICcjQUNBM0VCJyBcCi0taGYgJyMxZTFlMmUnIFwKLS1zYiAnI0FDQTNFQicgXAotLXNmICcjMWUxZTJlJyBcCi0tY2IgJyNBQ0EzRUInIFwKLS1jZiAnIzFlMWUyZScgXAotLWZiYiAnIzFlMWUyZScgXAotLWZiZiAnI0FDQTNFQicgXAotLWJvcmRlciA1IFwKLS1iZHIgIzAwMDAwMDAwIjs=
EOF
      '');

    home.file.".config/waybar".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/waybar";

    systemd.user.services.update-wallpaper = {
      Unit = {
        Description = "Update wallpaper";
        After = [ "graphical-session.target" ];
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

    home.file.".local/backgrounds".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.local/backgrounds";

    # Automount removable drives with a tray icon.
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
