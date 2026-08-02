{ pkgs, lib, ... }:

{
  imports = [
    ../home/base.nix
    ../home/env.nix
    ../home/scripts.nix
    ../home/shell.nix
    ../home/terminal.nix
    ../home/git.nix
    ../home/firefox.nix
    ../home/packages-cli.nix
    ../home/packages-dev.nix
    ../home/packages-nix.nix
    ../home/packages-editor.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "raycast" ];

  environment.systemPackages = with pkgs; [
    raycast
    zed-editor
    vscodium
  ];

  home-manager.users.yeet = {
    home.sessionVariables.TERMINAL = lib.mkForce "kitty";

    programs.alacritty.enable = lib.mkForce false;
    programs.kitty = {
      enable = true;
      font = {
        name = "CaskaydiaCove Nerd Font Mono";
        size = 10;
      };
      settings = {
        background_opacity = "1.0";
        hide_window_decorations = "yes";

        background = "#1e1e2e";
        foreground = "#cdd6f4";
        selection_background = "#f5e0dc";
        selection_foreground = "#1e1e2e";
        cursor = "#f5e0dc";
        cursor_text_color = "#1e1e2e";

        color0 = "#45475a";
        color1 = "#f38ba8";
        color2 = "#a6e3a1";
        color3 = "#f9e2af";
        color4 = "#89b4fa";
        color5 = "#f5c2e7";
        color6 = "#94e2d5";
        color7 = "#bac2de";
        color8 = "#585b70";
        color9 = "#f38ba8";
        color10 = "#a6e3a1";
        color11 = "#f9e2af";
        color12 = "#89b4fa";
        color13 = "#f5c2e7";
        color14 = "#94e2d5";
        color15 = "#a6adc8";
      };
      keybindings = {
        "alt+k" = "scroll_page_up";
        "alt+j" = "scroll_page_down";
        "alt+u" = "scroll_page_up";
        "alt+d" = "scroll_page_down";
        "alt+shift+k" = "change_font_size all +1.0";
        "alt+shift+j" = "change_font_size all -1.0";
        "shift+enter" = "send_text all \\x1b\\x0d";
      };
    };
  };

  services.aerospace = {
    enable = true;
    settings = {
      config-version = 2;
      auto-reload-config = true;
      automatically-unhide-macos-hidden-apps = true;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      accordion-padding = 30;
      persistent-workspaces = map toString (lib.range 1 10) ++ [ "S" ];

      gaps = {
        inner.horizontal = 5;
        inner.vertical = 5;
        outer.left = 5;
        outer.bottom = 5;
        outer.top = 5;
        outer.right = 5;
      };

      mode.main.binding = {
        alt-enter = "exec-and-forget open -na Kitty";
        alt-d = "exec-and-forget open -a Raycast";
        alt-q = "close";
        alt-f = "fullscreen";
        alt-shift-space = "layout floating tiling";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-comma = "focus-monitor --wrap-around left";
        alt-period = "focus-monitor --wrap-around right";
        alt-shift-comma = "move-node-to-monitor --wrap-around left";
        alt-shift-period = "move-node-to-monitor --wrap-around right";

        alt-r = "mode resize";
        alt-s = "summon-workspace S";
        alt-tab = "workspace-back-and-forth";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";
        alt-shift-s = "move-node-to-workspace S";
      };

      mode.resize.binding = {
        h = "resize width -50";
        j = "resize height +50";
        k = "resize height -50";
        l = "resize width +50";
        enter = "mode main";
        esc = "mode main";
      };

      on-window-detected = [
        { "if".app-id = "net.kovidgoyal.kitty"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "org.mozilla.firefox"; run = "move-node-to-workspace 2"; }
        { "if".app-id = "dev.zed.Zed"; run = "move-node-to-workspace 3"; }
        { "if".app-id = "com.vscodium"; run = "move-node-to-workspace 3"; }
        { "if".app-id = "com.apple.finder"; run = "layout floating"; }
        { "if".app-id = "com.apple.systempreferences"; run = "layout floating"; }
        { "if".app-id = "com.raycast.macos"; run = "layout floating"; }
      ];
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowShouldDragOnGesture = true;
    };
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;
      expose-group-apps = true;
      launchanim = false;
      mru-spaces = false;
      show-recents = false;
    };
    WindowManager = {
      EnableStandardClickToShowDesktop = false;
      EnableTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTopTilingByEdgeDrag = false;
      GloballyEnabled = false;
    };
  };

  users.users.yeet = {
    home = "/Users/yeet";
    shell = pkgs.zsh;
  };

  system.primaryUser = "yeet";

  programs.zsh.enable = true;

  system.stateVersion = 6;
}
