{ pkgs, lib, inputs, ... }:

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
    ../home/backgrounds.nix
  ];

  environment.systemPackages = with pkgs; [
    our.supercmd
    our.hammerspoon
    inputs.omp-gateway-bar.packages.${pkgs.system}.default
    zed-editor
    vscodium
  ];

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  fonts.packages = [ pkgs.nerd-fonts.caskaydia-cove ];

  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "yigit.colakoglu"
    ];
  };

  home-manager.users."yigit.colakoglu" = { config, ... }: {
    home.packages = with pkgs; [
      codex
      claude-code
    ];

    home.sessionVariables.TERMINAL = lib.mkForce "kitty";

    home.file.".hammerspoon/init.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/init.lua";
    home.file.".hammerspoon/config.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/config.lua";

    home.file.".hammerspoon/modules".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/modules";

    xdg.configFile."kitty/quick-access-terminal.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/kitty/quick-access-terminal.conf";

    launchd.agents.hammerspoon = {
      enable = true;
      config = {
        Label = "org.hammerspoon.Hammerspoon";
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "${pkgs.our.hammerspoon}/Applications/Hammerspoon.app"
        ];
        RunAtLoad = true;
        ProcessType = "Interactive";
      };
    };

    programs.alacritty.enable = lib.mkForce false;
    programs.kitty = {
      enable = true;
      font = {
        name = "CaskaydiaCove Nerd Font Mono";
        size = 10;
      };
      settings = {
        background_opacity = "1.0";

        hide_window_decorations = "no";
        macos_quit_when_last_window_closed = "yes";

        remember_window_size = "no";
        initial_window_width = "120c";
        initial_window_height = "34c";

        enabled_layouts = "splits,stack";

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
        "cmd+k" = "scroll_page_up";
        "cmd+j" = "scroll_page_down";
        "alt+u" = "scroll_page_up";
        "alt+d" = "scroll_page_down";
        "cmd+shift+k" = "change_font_size all +1.0";
        "cmd+shift+j" = "change_font_size all -1.0";
        "shift+enter" = "send_text all \\x1b\\x0d";

        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+x" = "copy_and_clear_or_interrupt";

        # Cmd behaves as Alt/Meta in the terminal: Cmd+x -> ESC+x (\x1b<char>).
        # Exceptions: cmd+j/k and cmd+shift+j/k are scroll/resize (above), and
        # copy/paste stay on ctrl+shift+c/v. Former cmd split binds were dropped.
        "cmd+a" = "send_text all \\x1ba";
        "cmd+b" = "send_text all \\x1bb";
        "cmd+c" = "send_text all \\x1bc";
        "cmd+d" = "send_text all \\x1bd";
        "cmd+e" = "send_text all \\x1be";
        "cmd+f" = "send_text all \\x1bf";
        "cmd+g" = "send_text all \\x1bg";
        "cmd+h" = "send_text all \\x1bh";
        "cmd+i" = "send_text all \\x1bi";
        "cmd+l" = "send_text all \\x1bl";
        "cmd+m" = "send_text all \\x1bm";
        "cmd+n" = "send_text all \\x1bn";
        "cmd+o" = "send_text all \\x1bo";
        "cmd+p" = "send_text all \\x1bp";
        "cmd+q" = "send_text all \\x1bq";
        "cmd+r" = "send_text all \\x1br";
        "cmd+s" = "send_text all \\x1bs";
        "cmd+t" = "send_text all \\x1bt";
        "cmd+u" = "send_text all \\x1bu";
        "cmd+v" = "send_text all \\x1bv";
        "cmd+w" = "send_text all \\x1bw";
        "cmd+x" = "send_text all \\x1bx";
        "cmd+y" = "send_text all \\x1by";
        "cmd+z" = "send_text all \\x1bz";
        "cmd+0" = "send_text all \\x1b0";
        "cmd+1" = "send_text all \\x1b1";
        "cmd+2" = "send_text all \\x1b2";
        "cmd+3" = "send_text all \\x1b3";
        "cmd+4" = "send_text all \\x1b4";
        "cmd+5" = "send_text all \\x1b5";
        "cmd+6" = "send_text all \\x1b6";
        "cmd+7" = "send_text all \\x1b7";
        "cmd+8" = "send_text all \\x1b8";
        "cmd+9" = "send_text all \\x1b9";
        "cmd+period" = "send_text all \\x1b.";
        "cmd+comma" = "send_text all \\x1b,";
        "cmd+slash" = "send_text all \\x1b/";
        "cmd+minus" = "send_text all \\x1b-";
        "cmd+backspace" = "send_text all \\x1b\\x7f";
        "ctrl+cmd+h" = "neighboring_window left";
        "ctrl+cmd+j" = "neighboring_window down";
        "ctrl+cmd+k" = "neighboring_window up";
        "ctrl+cmd+l" = "neighboring_window right";
      };
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      # Fast key repeat matching Hyprland (repeat_delay = 180, repeat_rate = 40).
      # Units are ~15ms; InitialKeyRepeat = 12 -> 180ms, KeyRepeat = 2 -> ~30ms/repeat.
      InitialKeyRepeat = 12;
      KeyRepeat = 2;
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
      GloballyEnabled = false;
      EnableStandardClickToShowDesktop = false;
    };
  };

  users.users."yigit.colakoglu" = {
    home = "/Users/yigit.colakoglu";
    shell = pkgs.zsh;
  };

  system.primaryUser = "yigit.colakoglu";

  programs.zsh.enable = true;

  system.stateVersion = 6;
}
