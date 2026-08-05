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
  # Home Manager owns the user completion setup. Avoid a duplicate system
  # compinit in /etc/static/zshrc before the Home Manager .zshrc starts.
  programs.zsh.enableCompletion = false;

  environment.systemPackages = with pkgs; [
    our.supercmd
    our.hammerspoon
    our.omniwm
    inputs.omp-gateway-bar.packages.${pkgs.system}.default
    zed-editor
    vscodium
  ];

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  fonts.packages = [ pkgs.nerd-fonts.caskaydia-cove ];

  # Strict declarative Homebrew: anything not listed here gets uninstalled on
  # activation. Dependencies of listed packages are kept automatically.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };
    brews = [
      "python@3.10"
      "thrift"
      "ykman"
    ];
    casks = [
      "bettercapture"
      "macshot"
    ];
  };

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

    home.sessionVariables.TERMINAL = lib.mkForce "ghostty";

    home.file.".hammerspoon/init.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/init.lua";
    home.file.".hammerspoon/config.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/config.lua";

    home.file.".hammerspoon/modules".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/hammerspoon/modules";

    # OmniWM atomic-rewrites and live-reloads ~/.config/omniwm/settings.toml, so
    # a store symlink cannot manage it (OmniWM replaces the link with a real
    # file). Seed it from the repo snapshot only when absent; OmniWM owns it
    # after. A git pre-commit hook (.githooks/pre-commit) snapshots the live
    # file back into the repo on every commit; see dotsGitHooks below.
    home.activation.seedOmniwmSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      target="$HOME/.config/omniwm/settings.toml"
      source="$HOME/.dots/.config/omniwm/settings.toml"
      if [ ! -e "$target" ] && [ -e "$source" ]; then
        run mkdir -p "$(dirname "$target")"
        run cp "$source" "$target"
        run chmod u+w "$target"
      fi
    '';

    # SuperCmd keeps hotkeys in the same settings.json it rewrites at runtime
    # with recents, launch counts and frecency scores. A whole-file symlink
    # would churn the repo on every launch, so the repo tracks only the keybind
    # subset (.config/supercmd/keybinds.json) and this merges those keys into
    # the live file. Quit SuperCmd before switching; a running instance can
    # rewrite settings.json from memory and drop the merge.
    home.activation.applySupercmdKeybinds = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      live="$HOME/Library/Application Support/SuperCmd/settings.json"
      source="$HOME/.dots/.config/supercmd/keybinds.json"
      if [ -e "$source" ]; then
        run mkdir -p "$(dirname "$live")"
        [ -e "$live" ] || echo '{}' > "$live"
        if ${pkgs.jq}/bin/jq -e . "$live" >/dev/null 2>&1; then
          tmp="$live.hm-new"
          run ${pkgs.jq}/bin/jq --slurpfile k "$source" \
            'reduce ($k[0] | to_entries[]) as $e (.; .[$e.key] = $e.value)' \
            "$live" > "$tmp"
          run mv "$tmp" "$live"
        else
          echo "applySupercmdKeybinds: $live is not valid JSON; skipping" >&2
        fi
      fi
    '';

    # Point the ~/.dots repo at its tracked hooks so the pre-commit snapshot
    # hook is active. Scoped to this repo; a global core.hooksPath would hijack
    # every other repo.
    home.activation.dotsGitHooks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      repo="$HOME/.dots"
      if [ -d "$repo/.git" ]; then
        run ${pkgs.git}/bin/git -C "$repo" config --local core.hooksPath .githooks
      fi
    '';

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

    # macOS resets hidutil key remaps on reboot, and nix-darwin only reapplies
    # remapCapsLockToEscape at activation. Reapply it at login so caps->escape
    # survives reboots.
    launchd.agents.capsLockToEscape = {
      enable = true;
      config = {
        Label = "org.local.capslock-to-escape";
        ProgramArguments = [
          "/usr/bin/hidutil"
          "property"
          "--set"
          ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}''
        ];
        RunAtLoad = true;
      };
    };

    # OmniWM owns window layout and workspaces. nix installs the signed bundle
    # and runs it under launchd; its settings.toml is the writable symlink above.
    launchd.agents.omniwm = {
      enable = true;
      config = {
        Label = "org.nixos.omniwm";
        Program = "${pkgs.our.omniwm}/Applications/OmniWM.app/Contents/MacOS/OmniWM";
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/omniwm.log";
        StandardErrorPath = "/tmp/omniwm.err.log";
      };
    };

    # Ghostty replaces kitty. pkgs.ghostty is Linux-only, so use the signed
    # ghostty-bin bundle; home-manager writes ~/.config/ghostty/config.
    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty-bin;

      # Exact catppuccin-mocha palette carried over from the old kitty colors.
      themes.mocha = {
        background = "1e1e2e";
        foreground = "cdd6f4";
        cursor-color = "f5e0dc";
        cursor-text = "1e1e2e";
        selection-background = "f5e0dc";
        selection-foreground = "1e1e2e";
        palette = [
          "0=#45475a"
          "1=#f38ba8"
          "2=#a6e3a1"
          "3=#f9e2af"
          "4=#89b4fa"
          "5=#f5c2e7"
          "6=#94e2d5"
          "7=#bac2de"
          "8=#585b70"
          "9=#f38ba8"
          "10=#a6e3a1"
          "11=#f9e2af"
          "12=#89b4fa"
          "13=#f5c2e7"
          "14=#94e2d5"
          "15=#a6adc8"
        ];
      };

      settings = {
        theme = "mocha";
        font-family = "CaskaydiaCove Nerd Font Mono";
        font-size = 10;
        background-opacity = 1;
        window-save-state = "never";
        clipboard-read = "allow";
        clipboard-write = "allow";
        quit-after-last-window-closed = true;
        confirm-close-surface = false;

        keybind =
          # Scroll and font size, carried over from kitty.
          [
            "cmd+k=scroll_page_up"
            "cmd+j=scroll_page_down"
            "alt+u=scroll_page_up"
            "alt+d=scroll_page_down"
            "cmd+shift+k=increase_font_size:1"
            "cmd+shift+j=decrease_font_size:1"
            "shift+enter=text:\\x1b\\r"
            "ctrl+shift+c=copy_to_clipboard"
            "ctrl+shift+v=paste_from_clipboard"
            "ctrl+cmd+h=goto_split:left"
            "ctrl+cmd+j=goto_split:down"
            "ctrl+cmd+k=goto_split:up"
            "ctrl+cmd+l=goto_split:right"
          ]
          # Cmd behaves as Alt/Meta: cmd+<key> sends ESC+<key>. cmd+j/k are
          # excluded above (scroll), copy/paste stay on ctrl+shift.
          ++ map (c: "cmd+${c}=text:\\x1b${c}") [
            "a"
            "b"
            "c"
            "d"
            "e"
            "f"
            "g"
            "h"
            "i"
            "l"
            "m"
            "n"
            "o"
            "p"
            "q"
            "r"
            "s"
            "t"
            "u"
            "v"
            "w"
            "x"
            "y"
            "z"
          ]
          # Digits need the physical `digit_N` trigger, not logical `cmd+N`:
          # Ghostty ships default `cmd+digit_N=goto_tab:N` bindings that shadow
          # the logical form, so `cmd+1` would switch tabs instead of sending
          # ESC+1. The physical trigger overrides that default. See
          # github.com/ghostty-org/ghostty/discussions/8541.
          ++ map (d: "cmd+digit_${d}=text:\\x1b${d}") [
            "0"
            "1"
            "2"
            "3"
            "4"
            "5"
            "6"
            "7"
            "8"
            "9"
          ]
          ++ [
            "cmd+period=text:\\x1b."
            "cmd+comma=text:\\x1b,"
            "cmd+slash=text:\\x1b/"
            "cmd+minus=text:\\x1b-"
            "cmd+backspace=text:\\x1b\\x7f"
          ];
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
    # OmniWM requires "Displays have separate Spaces" ON, i.e. spans-displays
    # OFF. Takes effect after logout.
    spaces.spans-displays = false;
    WindowManager = {
      GloballyEnabled = false;
      EnableStandardClickToShowDesktop = false;
    };
    # macshot is sandboxed, so its prefs live in
    # ~/Library/Containers/com.sw33tlie.macshot.macshot/Data/Library/Preferences.
    # `defaults write` still reaches that container through cfprefsd, which is
    # what CustomUserPreferences uses. Only the capture hotkey is declared here;
    # the rest of the domain is runtime state that macshot owns.
    # hotkeyKeyCode 7 = X, hotkeyModifiers 2560 = shift (512) + option (2048),
    # i.e. Option+Shift+X.
    CustomUserPreferences."com.sw33tlie.macshot.macshot" = {
      hotkeyKeyCode = 7;
      hotkeyModifiers = 2560;
    };
  };

  users.users."yigit.colakoglu" = {
    home = "/Users/yigit.colakoglu";
    shell = pkgs.zsh;
  };

  system.primaryUser = "yigit.colakoglu";

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  programs.zsh.enable = true;

  system.stateVersion = 6;
}
