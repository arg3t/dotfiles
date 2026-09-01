{ pkgs, config, lib, ... }:

let
  cfg = config.my.hyprland;

  colors = {
    surface0 = "rgba(49, 50, 68, 1.0)";
    lavender = "rgba(180, 190, 254, 1.0)";
    blue = "rgba(137, 180, 250, 1.0)";
    teal = "rgba(148, 226, 213, 1.0)";
    green = "rgba(166, 227, 161, 1.0)";
    peach = "rgba(250, 179, 135, 1.0)";
    red = "rgba(243, 139, 168, 1.0)";
  };

  flameshot-wrapped = pkgs.symlinkJoin {
    name = "flameshot-${pkgs.flameshot.version}";
    paths = [ pkgs.flameshot ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/flameshot \
        --set XDG_CURRENT_DESKTOP sway \
        --set QT_QPA_PLATFORM wayland \
        --set QT_AUTO_SCREEN_SCALE_FACTOR 0 \
        --set QT_SCREEN_SCALE_FACTORS 1
    '';
  };

  waybarSettings = builtins.fromJSON ''
    {
      "layer": "bottom",
      "position": "top",
      "height": 30,
      "spacing": 4,
      "reload_style_on_change": false,
      "reload_config_on_change": false,
      "modules-left": [
        "hyprland/workspaces"
      ],
      "modules-center": [],
      "modules-right": [
        "custom/dnd",
        "custom/bluetooth",
        "memory",
        "custom/cpu",
        "temperature",
        "custom/weather",
        "pulseaudio",
        "network",
        "custom/battery",
        "clock#time",
        "custom/empty",
        "clock#date"
      ],
      "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
          "empty": "",
          "default": ""
        },
        "persistent-workspaces": {
          "*": 10
        },
        "on-click": "activate"
      },
      "custom/bluetooth": {
        "format": "{}",
        "return-type": "json",
        "escape": false,
        "tooltip": true,
        "interval": 30,
        "exec": "$HOME/.config/waybar/scripts/bluetooth-devices bluetooth-json",
        "on-click": "dmenu-bluetooth",
        "on-click-right": "blueman-manager"
      },
      "memory": {
        "interval": 120,
        "format": "<span color=\"#aca3eb\"> </span> {}%",
        "max-length": 10
      },
      "custom/cpu": {
        "format": "{}",
        "return-type": "json",
        "escape": false,
        "tooltip": true,
        "interval": 5,
        "exec": "$HOME/.local/bin/status-bar/cpu"
      },
      "temperature": {
        "interval": 30,
        "critical-threshold": 80,
        "format": "<span color=\"#bf616a\">{icon}</span> {temperatureC}°C",
        "format-icons": [
          "",
          "",
          "",
          "",
          "",
          ""
        ]
      },
      "pulseaudio": {
        "format": "<span color=\"#a3be8c\">{icon}</span> {volume}%",
        "format-muted": "<span color=\"#a3be8c\"> </span>",
        "format-icons": {
          "default": [
            " ",
            " ",
            " "
          ]
        },
        "on-click": "pavucontrol"
      },
      "network": {
        "format-wifi": " ",
        "format-ethernet": " ",
        "format-disconnected": " ",
        "interval": 120,
        "tooltip-format": "{essid} ({signalStrength}%)",
        "on-click": "nm-connection-editor"
      },
      "custom/battery": {
        "format": "{}",
        "return-type": "json",
        "escape": false,
        "interval": 120,
        "signal": 12,
        "exec": "$HOME/.config/waybar/scripts/battery-with-bluetooth",
        "tooltip": true,
        "on-click": "$HOME/.config/waybar/scripts/bluetooth-devices battery-menu",
        "on-click-right": "$HOME/.config/waybar/scripts/bluetooth-devices power-menu"
      },
      "clock#time": {
        "interval": 30,
        "format": " {:%H:%M}"
      },
      "clock#date": {
        "interval": 240,
        "format": "󰃭 {:%h %e}"
      },
      "custom/weather": {
        "format": "{}",
        "return-type": "text",
        "tooltip": false,
        "interval": 3600,
        "exec": "$HOME/.local/bin/status-bar/weather"
      },
      "custom/empty": {
        "format": "​",
        "return-type": "text",
        "tooltip": false,
        "interval": 360000,
        "exec": "id"
      },
      "custom/dnd": {
        "format": "{}",
        "on-click": "makoctl mode -t dnd; notify-send -t 1 '''",
        "on-click-right": "makoctl restore",
        "exec": "~/.local/bin/status-bar/dunst",
        "return-type": "json",
        "escape": true
      }
    }
  '';
in
{
  options.my.hyprland = {
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "eDP-1,preferred,auto,1" ];
      description = "Hyprland `monitor=` lines for this host.";
    };
    workspaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Host-specific `workspace=` rules (e.g. monitor pinning).";
    };
    exec = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Host-specific `exec-once` entries.";
    };
    battery = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Host has a battery; show battery in waybar and on the hyprlock screen (disable on desktops).";
    };
  };

  config = {
    programs.hyprland.enable = true;

    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    services.gnome.gnome-keyring.enable = true;
    services.gnome.gcr-ssh-agent.enable = true;
    programs.ssh.startAgent = false;

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
      alacritty.terminfo
      bemenu
      j4-dmenu-desktop
      cliphist
      alsa-utils
      grim
      slurp
      wl-clipboard
      libnotify
      eww
      pavucontrol
      networkmanagerapplet
      xfce4-power-manager
      nemo
      glib
      lf
      flameshot-wrapped
      zathura
      syshud
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
    ];

    home-manager.users.yeet = { config, ... }: {
      xdg.configFile."hypr/profile.jpg".source = ../../.config/hypr/profile.jpg;
      xdg.configFile."waybar/scripts/bluetooth-devices" = {
        source = ../../.config/waybar/scripts/bluetooth-devices;
        executable = true;
      };
      xdg.configFile."waybar/scripts/battery-with-bluetooth" = {
        source = ../../.config/waybar/scripts/battery-with-bluetooth;
        executable = true;
      };

      xdg.configFile."flameshot/flameshot.ini".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/flameshot/flameshot.ini";
      xdg.configFile."wofi/config".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/wofi/config";
      xdg.configFile."wofi/style.css".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/wofi/style.css";
      xdg.configFile."bemenu/config.sh".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/bemenu/config.sh";
      home.file.".config/eww".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/eww";

      wayland.windowManager.hyprland = {
        enable = true;
        package = null;
        portalPackage = null;
        systemd.enable = true;
        configType = "hyprlang";
        settings = {
          "$terminal" = "alacritty";
          "$menu" = "j4-dmenu-desktop --dmenu=/home/yeet/.local/bin/dmenu";
          "$browser" = "firefox";
          "$mainMod" = "SUPER";
          "$switch_script" = "~/.local/bin/switch_workspace.sh";

          monitor = cfg.monitors;

          env = [
            "XCURSOR_SIZE,18"
            "HYPRCURSOR_SIZE,18"
            "XDG_CURRENT_DESKTOP,Hyprland"
            "XDG_SESSION_TYPE,wayland"
            "XDG_SESSION_DESKTOP,Hyprland"
          ];

          general = {
            gaps_in = 5;
            gaps_out = 5;
            border_size = 1;
            "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
            "col.inactive_border" = "rgba(31324499)";
            resize_on_border = false;
            allow_tearing = false;
            layout = "master";
          };

          decoration = {
            rounding = 0;
            active_opacity = 1.0;
            inactive_opacity = 0.95;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          animations.enabled = false;
          dwindle.preserve_split = true;
          master.mfact = 0.55;

          input = {
            kb_layout = "us,tr";
            repeat_delay = 180;
            repeat_rate = 40;
            follow_mouse = 1;
            sensitivity = 0;
            kb_options = "caps:escape";
            touchpad.natural_scroll = false;
          };

          device = {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          };

          bind = [
            "$mainMod, Return, exec, $terminal"
            "$mainMod, Q, killactive,"
            "$mainMod SHIFT, Q, exec, dmenu-logout"
            "$mainMod, X, exec, hyprlock"
            "$mainMod, D, exec, $menu"
            "$mainMod, T, exec, dmenu-toolkit"
            "$mainMod SHIFT, R, exec, dmenu-refresh"
            "$mainMod ALT, K, exec, kbmap_toggle"
            "$mainMod SHIFT, I, exec, screensaver_toggle -t"
            "$mainMod SHIFT, N, exec, dunst_toggle.sh -t"
            "$mainMod, f, fullscreen,"
            "$mainMod SHIFT, Space, togglefloating,"
            "$mainMod, J, cyclenext,"
            "$mainMod, K, cyclenext, prev"
            "$mainMod SHIFT, J, swapnext,"
            "$mainMod SHIFT, K, swapnext, prev"
            "$mainMod, H, resizeactive, -20 0"
            "$mainMod, L, resizeactive, 20 0"
            "$mainMod CTRL, J, resizeactive, 0 10"
            "$mainMod CTRL, K, resizeactive, 0 -10"
            "$mainMod, 1, exec, $switch_script switch 1"
            "$mainMod, 2, exec, $switch_script switch 2"
            "$mainMod, 3, exec, $switch_script switch 3"
            "$mainMod, 4, exec, $switch_script switch 4"
            "$mainMod, 5, exec, $switch_script switch 5"
            "$mainMod, 6, exec, $switch_script switch 6"
            "$mainMod, 7, exec, $switch_script switch 7"
            "$mainMod, 8, exec, $switch_script switch 8"
            "$mainMod, 9, exec, $switch_script switch 9"
            "$mainMod, 0, exec, $switch_script switch 10"
            "$mainMod SHIFT, 1, exec, $switch_script move 1"
            "$mainMod SHIFT, 2, exec, $switch_script move 2"
            "$mainMod SHIFT, 3, exec, $switch_script move 3"
            "$mainMod SHIFT, 4, exec, $switch_script move 4"
            "$mainMod SHIFT, 5, exec, $switch_script move 5"
            "$mainMod SHIFT, 6, exec, $switch_script move 6"
            "$mainMod SHIFT, 7, exec, $switch_script move 7"
            "$mainMod SHIFT, 8, exec, $switch_script move 8"
            "$mainMod SHIFT, 9, exec, $switch_script move 9"
            "$mainMod SHIFT, 0, exec, $switch_script move 10"
            "$mainMod, period, focusmonitor, +1"
            "$mainMod, comma, focusmonitor, -1"
            "$mainMod SHIFT, period, movewindow, mon:+1"
            "$mainMod SHIFT, comma, movewindow, mon:-1"
            "$mainMod, S, exec, $switch_script togglespecial scratchterm"
            "$mainMod SHIFT, F, togglespecialworkspace, scratchfile"
            "$mainMod, C, exec, sh -c 'cliphist list | dmenu -l 8 | cliphist decode | wl-copy'"
            ", PRINT, exec, flameshot gui"
          ];

          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          bindel = [
            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ];

          bindl = [
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPrev, exec, playerctl previous"
            ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ];

          workspace = [
            "special:0_scratchterm, on-created-empty:alacritty --class 'scratchterm', persistent:false"
            "special:1_scratchterm, on-created-empty:alacritty --class 'scratchterm', persistent:false"
            "special:2_scratchterm, on-created-empty:alacritty --class 'scratchterm', persistent:false"
            "special:3_scratchterm, on-created-empty:alacritty --class 'scratchterm', persistent:false"
            "special:4_scratchterm, on-created-empty:alacritty --class 'scratchterm', persistent:false"
            "11, on-created-empty:alacritty"
            "1, on-created-empty:alacritty"
            "2, on-created-empty:firefox"
            "special:scratchfile, on-created-empty:nemo --class=scratchfile --name=scratchfile, persistent:false"
          ] ++ cfg.workspaces;

          windowrule = [
            "match:class ^(scratchterm)$, float on, size monitor_w*0.575 monitor_h*0.625, center on"
            "match:class ^(scratchfile)$, float on, size monitor_w*0.575 monitor_h*0.625, workspace special:scratchfile"
            "match:class ^(Alacritty)$, workspace m~0 silent"
            "match:class ^(Brave-browser)$, workspace m~2 silent"
            "match:class ^(firefox)$, workspace m~2 silent"
            "match:class ^(Firefox)$, workspace m~2 silent"
            "match:class ^(chromium)$, workspace m~2 silent"
            "match:class ^(Chromium)$, workspace m~2 silent"
            "match:class ^(tabbed-surf)$, workspace m~2 silent"
            "match:class ^(Tor Browser)$, workspace m~2 silent"
            "match:class ^(discord)$, workspace 9 silent"
            "match:class ^(Mattermost)$, workspace 9 silent"
            "match:class ^(Signal)$, workspace 9 silent"
            "match:class ^(TelegramDesktop)$, workspace 9 silent"
            "match:class ^(thunderbird)$, workspace 8 silent"
            "match:class ^(org.mozilla.Thunderbird)$, workspace 8 silent"
            "match:class ^(spotify)$, workspace 10 silent"
            "match:class ^(Spotify)$, workspace 10 silent"
            "match:class ^(VirtualBox Manager)$, workspace 15 silent"
            "match:class ^(VirtualBox Machine)$, workspace 15 silent"
            "match:class ^(neovide)$, workspace 13 silent"
            "match:class ^(Cursor)$, workspace 13 silent"
            "match:class ^(Code)$, workspace 13 silent"
            "match:class ^(dev.zed.Zed)$, workspace 13 silent"
            "match:class ^(Zathura)$, pin on"
            "match:class ^(stalonetray)$, pin on"
            "match:class ^(Qemu-system-x86_64)$, pin on, float on"
            "match:class ^(obsidian)$, workspace 4 silent"
            "match:title ^(Reminder)$, pin on"
            "match:class flameshot, match:title flameshot, move 0 0"
            "match:class flameshot, match:title flameshot, pin on"
            "match:class flameshot, match:title flameshot, fullscreen_state 3 3"
            "match:class flameshot, match:title flameshot, float on"
            "match:class machete, float on, size monitor_w*0.875 monitor_h*0.7, center on"
            "match:class typstff, fullscreen_state 0 3"
            "match:class firefox, match:title .*Bitwarden.*, float on"
          ];

          exec-once = [
            "systemctl --user start hyprpolkitagent"
            "syshud -p \"top right\" -l audio_in,audio_out,backlight"
            "xfce4-power-manager"
            "mako"
            "wl-paste --type text --watch cliphist store"
            "discord &"
            "thunderbird &"
          ] ++ cfg.exec;

          debug.disable_logs = true;
        };
      };

      programs.hyprlock = {
        enable = true;
        settings = {
          background = [{
            monitor = "";
            path = "screenshot";
            color = colors.surface0;
            blur_passes = 2;
            contrast = 1;
            brightness = 0.5;
            vibrancy = 0.2;
            vibrancy_darkness = 0.2;
          }];

          general.hide_cursor = false;

          input-field = [{
            monitor = "";
            size = "325, 60";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.35;
            dots_center = true;
            outer_color = colors.surface0;
            inner_color = colors.surface0;
            font_color = colors.lavender;
            fail_color = colors.red;
            fade_on_empty = false;
            rounding = -1;
            check_color = colors.lavender;
            placeholder_text = "Input Password...";
            hide_input = false;
            position = "0, -160";
            halign = "center";
            valign = "center";
          }];

          label = [
            {
              monitor = "";
              text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
              color = colors.lavender;
              font_size = 22;
              font_family = "CaskaydiaCove Nerd Font";
              position = "0, 300";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:1000] echo "$(date +"%-I:%M")"'';
              color = colors.blue;
              font_size = 95;
              font_family = "CaskaydiaCove Nerd Font";
              position = "0, 200";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:1000] echo "$(~/.local/bin/lockscreen/media)"'';
              color = colors.green;
              font_size = 18;
              font_family = "CaskaydiaCove Nerd Font";
              position = "0, 50";
              halign = "center";
              valign = "bottom";
            }
            {
              monitor = "";
              text = ''cmd[update:1000] echo "$(~/.local/bin/lockscreen/whoami)"'';
              color = colors.red;
              font_size = 14;
              font_family = "CaskaydiaCove Nerd Font";
              position = "0, -10";
              halign = "center";
              valign = "top";
            }
          ] ++ lib.optional cfg.battery {
              monitor = "";
              text = ''cmd[update:1000] echo "$(~/.local/bin/lockscreen/battery)"'';
              color = colors.peach;
              font_size = 16;
              font_family = "CaskaydiaCove Nerd Font Mono";
              position = "-60, -10";
              halign = "right";
              valign = "top";
          } ++ [
            {
              monitor = "";
              text = ''cmd[update:1000] echo "$(~/.local/bin/lockscreen/network)"'';
              color = colors.teal;
              font_size = 24;
              font_family = "CaskaydiaCove Nerd Font Mono";
              position = "-20, -3";
              halign = "right";
              valign = "top";
            }
          ];

          image = [
            {
              monitor = "";
              path = "~/.config/hypr/profile.jpg";
              size = 175;
              border_size = 2;
              border_color = colors.blue;
              position = "0, -10";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              path = "~/.local/share/logos/hypr.png";
              size = 75;
              border_size = 2;
              border_color = colors.teal;
              position = "-50, 50";
              halign = "right";
              valign = "bottom";
            }
          ];
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 150;
              on-timeout = "brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
            }
            {
              timeout = 150;
              on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
              on-resume = "brightnessctl -rd rgb:kbd_backlight";
            }
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 450;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
            }
          ] ++ lib.optional cfg.battery {
              timeout = 1800;
              on-timeout = "systemctl suspend";
            };
        };
      };

      services.awww.enable = true;

      services.mako = {
        enable = true;
        settings = {
          font = "CaskaydiaCove Nerd Font 10";
          markup = true;
          sort = "-time";
          layer = "overlay";
          anchor = "top-right";
          width = 400;
          height = 100;
          margin = 5;
          padding = 10;
          border-radius = 0;
          default-timeout = 5000;
          ignore-timeout = false;
          max-visible = -1;
          border-size = 0;
          background-color = "#1E1E2E";
          text-color = "#CDD6F4";
          border-color = "#B7A6F1";
          progress-color = "#B7A6F1";
          icon-path = "/usr/share/icons/Adwaita/";
          max-icon-size = 32;
          on-button-left = "dismiss";
          on-button-middle = "invoke-default-action";
          on-button-right = "dismiss-all";
          format = "<b>%a</b>\\n%s\\n%b";
          "urgency=low".default-timeout = 5000;
          "urgency=normal".default-timeout = 5000;
          "urgency=critical" = {
            border-color = "#FAB387";
            default-timeout = 0;
            ignore-timeout = true;
          };
          "mode=dnd".invisible = true;
        };
      };

      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings.mainBar = waybarSettings // lib.optionalAttrs (!cfg.battery) {
          modules-right = builtins.filter (m: m != "custom/battery") waybarSettings.modules-right;
        };
        style = ''
    @define-color rosewater #f5e0dc;
    @define-color flamingo #f2cdcd;
    @define-color pink #f5c2e7;
    @define-color mauve #cba6f7;
    @define-color red #f38ba8;
    @define-color maroon #eba0ac;
    @define-color peach #fab387;
    @define-color yellow #f9e2af;
    @define-color green #a6e3a1;
    @define-color teal #94e2d5;
    @define-color sky #89dceb;
    @define-color sapphire #74c7ec;
    @define-color blue #89b4fa;
    @define-color lavender #b4befe;
    @define-color text #cdd6f4;
    @define-color subtext1 #bac2de;
    @define-color subtext0 #a6adc8;
    @define-color overlay2 #9399b2;
    @define-color overlay1 #7f849c;
    @define-color overlay0 #6c7086;
    @define-color surface2 #585b70;
    @define-color surface1 #45475a;
    @define-color surface0 #313244;
    @define-color base #1e1e2e;
    @define-color mantle #181825;
    @define-color crust #11111b;

    * {
        border: none;
        border-radius: 0;
        font-family: "CaskaydiaCove Nerd Font", "Font Awesome 6 Free";
        font-size: 12px;
        min-height: 0;
    }

    window#waybar {
        color: #ffffff;
        transition-property: background-color;
        transition-duration: .5s;
        background: transparent;
    }

    window > box {
        margin: 5px;
        margin-bottom: 0px;
        background-color: shade(@base, 1);
        color: white;
    }

    window#waybar.hidden {
        opacity: 1;
    }

    #workspaces button {
        background-color: transparent;
        color: #ffffff;
        padding: 3px;
        padding-right: 6px;
    }

    #workspaces button:hover {
      background-color: shade(@mauve, 0.4);
      box-shadow: none;
      text-shadow: none;
      transition: background-color 0.1s;
    }

    #workspaces button.active {
        background-color: #ACA3EB;
        color: shade(@base, 1);
    }

    #workspaces button.urgent {
        background-color: #e78284;
        color: shade(@base, 1);
    }

    /* Status modules */
    .modules-right .module {
        color: #ffffff;
        border-right: 2px solid #AAAAAA;
        /* Otherwise nerdfont icons are offset */
        padding-left: 7px;
        padding-right: 10px;
        margin: 5px 0px;
    }

    #custom-empty {
      padding: 0;
      margin: 5px 0px 5px 4px;
    }

    #custom-dnd {
      color: #88c0d0;
    }

    #network {
      color: #88c0d0;
    }

    #clock {
        color: shade(@base, 1);
        margin: 0 0 0 4px;
        padding: 3px 5px;
        border: 0;
    }

    .date {
        background-color: #88c0d0;
    }

    .time {
        background-color: #bf616a;
    }

    #temperature.critical {
        background-color: #eb4d4b;
        color: #ffffff;
    }

    @keyframes blink {
        to {
            background-color: #ffffff;
            color: #000000;
        }
    }
        '';
      };

      systemd.user.services.update-wallpaper = {
        Unit = {
          Description = "Update wallpaper";
          After = [
            "graphical-session.target"
            "sync-backgrounds.service"
            "awww.service"
          ];
          Wants = [ "awww.service" ];
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
  };
}
