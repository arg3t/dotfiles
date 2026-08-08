{
  pkgs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = {
    programs.alacritty = {
      enable = true;
      settings = builtins.fromTOML ''
        [window]
          opacity = 1
          decorations = "None"

        [font]
          normal.family = "CaskaydiaCove Nerd Font Mono"
          bold.family = "CaskaydiaCove Nerd Font Mono"
          italic.family = "CaskaydiaCove Nerd Font Mono"
          bold_italic.family = "CaskaydiaCove Nerd Font Mono"

          size =  10

        [keyboard]
          bindings = [
             { key = "K", mods = "Alt", action = "ScrollHalfPageUp" },
             { key = "J", mods = "Alt", action = "ScrollHalfPageDown" },
             { key = "U", mods = "Alt", action = "ScrollPageUp" },
             { key = "D", mods = "Alt", action = "ScrollPageDown" },

             { key = "K", mods = "Alt|Shift", action = "IncreaseFontSize" },
             { key = "J", mods = "Alt|Shift", action = "DecreaseFontSize" },
             { key = "Return", mods = "Shift", chars = "\\u001b\\r" },
          ]

        [colors.primary]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        dim_foreground = "#7f849c"
        bright_foreground = "#cdd6f4"

        [colors.cursor]
        text = "#1e1e2e"
        cursor = "#f5e0dc"

        [colors.vi_mode_cursor]
        text = "#1e1e2e"
        cursor = "#b4befe"

        [colors.search.matches]
        foreground = "#1e1e2e"
        background = "#a6adc8"

        [colors.search.focused_match]
        foreground = "#1e1e2e"
        background = "#a6e3a1"

        [colors.footer_bar]
        foreground = "#1e1e2e"
        background = "#a6adc8"

        [colors.hints.start]
        foreground = "#1e1e2e"
        background = "#f9e2af"

        [colors.hints.end]
        foreground = "#1e1e2e"
        background = "#a6adc8"

        [colors.selection]
        text = "#1e1e2e"
        background = "#f5e0dc"

        [colors.normal]
        black = "#45475a"
        red = "#f38ba8"
        green = "#a6e3a1"
        yellow = "#f9e2af"
        blue = "#89b4fa"
        magenta = "#f5c2e7"
        cyan = "#94e2d5"
        white = "#bac2de"

        [colors.bright]
        black = "#585b70"
        red = "#f38ba8"
        green = "#a6e3a1"
        yellow = "#f9e2af"
        blue = "#89b4fa"
        magenta = "#f5c2e7"
        cyan = "#94e2d5"
        white = "#a6adc8"

        [[colors.indexed_colors]]
        index = 16
        color = "#fab387"

        [[colors.indexed_colors]]
        index = 17
        color = "#f5e0dc"

      '';
    };

    home.packages = [ pkgs.alacritty.terminfo ];

    programs.tmux = {
      enable = true;
      plugins = [
        {
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig = "set -g @catppuccin_flavor 'mocha'";
        }
      ];
      extraConfig = builtins.readFile ../../.config/tmux/tmux.conf;
    };
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
