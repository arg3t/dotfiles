{ pkgs, username ? "yeet", standaloneHome ? false, ... }:

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
             { key = "Return", mods = "Shift", chars = "\u001b\r" },
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

    programs.tmux = {
      enable = true;
      plugins = [
        {
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig = "set -g @catppuccin_flavor 'mocha'";
        }
      ];
      extraConfig = ''
        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",$TERM:RGB"
        
        #
        
        # Use | and - to split panes
        bind | split-window -h
        bind \\ split-window -h
        bind - split-window -v
        unbind '"'
        unbind %
        
        # Use vim-style keys to navigate between panes
        # Make it easier to reload the config
        bind r source-file ~/.config/tmux/tmux.conf
        
        set -g base-index 1
        setw -g pane-base-index 1
        
        # command prefix
        unbind C-b
        set-option -g prefix C-a
        
        # vi keybinds
        bind v copy-mode
        set-window-option -g mode-keys vi
        bind-key -T copy-mode-vi v send -X begin-selection
        bind-key -T copy-mode-vi V send -X select-line
        bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel 'wl-copy'
        
        # Tmux naviagation
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
            | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        is_ctrl_l_tui="ps -o state= -o comm= -t '#{pane_tty}' \
            | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?(g?(view|n?vim?x?)(diff)?|omp)$'"
        
        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_ctrl_l_tui" 'send-keys C-l'
        
        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"
        
        bind-key -n 'C-Space' if-shell "$is_vim" 'send-keys C-Space' 'select-pane -t:.+'
        
        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l
        bind-key -T copy-mode-vi 'C-Space' select-pane -t:.+
        
        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",*256col*:Tc"
        
        set -g mouse on
        
      '';
    };
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
