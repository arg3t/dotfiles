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

  fonts.packages = [ pkgs.nerd-fonts.caskaydia-cove ];

  # nix-darwin takes ownership of /etc/nix/nix.conf after the initial
  # migration, so keep the flake features enabled in the generated file.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Without this the flake's own nixConfig is refused as "untrusted".
    trusted-users = [
      "root"
      "yigit.colakoglu"
    ];
  };

  home-manager.users."yigit.colakoglu" = { config, ... }: {
    home.sessionVariables.TERMINAL = lib.mkForce "kitty";

    # Hammerspoon reads ~/.hammerspoon/init.lua; keep it editable in place.
    home.file.".hammerspoon/init.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/init.lua";

    launchd.agents.hammerspoon = {
      enable = true;
      config = {
        Label = "org.hammerspoon.Hammerspoon";
        ProgramArguments = [
          "${pkgs.our.hammerspoon}/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon"
        ];
        RunAtLoad = true;
        KeepAlive = true;
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

        # Native title bar: without a tiling WM these are ordinary macOS
        # windows that need traffic lights and a drag handle.
        hide_window_decorations = "no";
        macos_quit_when_last_window_closed = "yes";

        # AeroSpace used to tile for us; kitty now does its own splitting.
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
        "alt+k" = "scroll_page_up";
        "alt+j" = "scroll_page_down";
        "alt+u" = "scroll_page_up";
        "alt+d" = "scroll_page_down";
        "alt+shift+k" = "change_font_size all +1.0";
        "alt+shift+j" = "change_font_size all -1.0";
        "shift+enter" = "send_text all \\x1b\\x0d";

        # Splits, replacing the window management AeroSpace used to provide.
        "cmd+d" = "launch --location=vsplit --cwd=current";
        "cmd+shift+d" = "launch --location=hsplit --cwd=current";
        "cmd+shift+f" = "toggle_layout stack";
        "ctrl+cmd+h" = "neighboring_window left";
        "ctrl+cmd+j" = "neighboring_window down";
        "ctrl+cmd+k" = "neighboring_window up";
        "ctrl+cmd+l" = "neighboring_window right";
      };
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      # Move a window by holding ctrl+cmd anywhere inside it.
      NSWindowShouldDragOnGesture = true;
    };
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;
      expose-group-apps = true;
      launchanim = false;
      # Keep desktop numbering stable so ctrl+<n> always means the same desktop.
      mru-spaces = false;
      show-recents = false;
    };
    WindowManager = {
      # Stage Manager fights with Spaces; native edge tiling stays enabled.
      GloballyEnabled = false;
      EnableStandardClickToShowDesktop = false;
    };
    # NOTE: `universalaccess` (Reduce Motion) is deliberately not managed here.
    # That domain is SIP-protected and `defaults write` fails during activation
    # unless the whole terminal is granted Full Disk Access. Toggle it by hand:
    # System Settings -> Accessibility -> Display -> Reduce motion.
  };

  users.users."yigit.colakoglu" = {
    home = "/Users/yigit.colakoglu";
    shell = pkgs.zsh;
  };

  system.primaryUser = "yigit.colakoglu";

  programs.zsh.enable = true;

  system.stateVersion = 6;
}
