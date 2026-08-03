{
  pkgs,
  lib,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  # Filtered at download time rather than at display time, so `rsync --delete`
  # also removes any copy synced before the exclusion existed.
  excludedBackgrounds = lib.optionals pkgs.stdenv.isDarwin [ "think-different.png" ];

  # Carries its own newline and indentation so that hosts with nothing to
  # exclude generate exactly the script they did before.
  excludeClause = lib.optionalString (excludedBackgrounds != [ ]) (
    "\n      case \"$(basename \"$file_path\")\" in "
    + lib.concatMapStringsSep "|" (name: "'${name}'") excludedBackgrounds
    + ") continue ;; esac"
  );

  syncBackgrounds = pkgs.writeShellApplication {
    name = "sync-backgrounds";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      findutils
      jq
      rsync
    ];
    text = ''
      set -eu

      token="91b02038daa74af88a8c"
      base_url="https://drive.yigit.run"
      target="$HOME/.local/backgrounds"
      work_root="$HOME/.local/state/backgrounds-sync"
      tmp="$work_root/backgrounds.tmp"

      rm -rf "$tmp"
      mkdir -p "$tmp"

      fetch_dir() {
        dir_path="$1"
        encoded_path=$(jq -rn --arg path "$dir_path" '$path|@uri')
        json=$(curl --fail --silent --show-error --location \
          "$base_url/api/v2.1/share-links/$token/dirents/?path=$encoded_path&thumbnail_size=48")

        printf '%s\n' "$json" | jq -c '.dirent_list[]' | while IFS= read -r entry; do
          is_dir=$(printf '%s\n' "$entry" | jq -r '.is_dir')
          if [ "$is_dir" = "true" ]; then
            child_path=$(printf '%s\n' "$entry" | jq -r '.folder_path')
            fetch_dir "$child_path"
          else
            file_path=$(printf '%s\n' "$entry" | jq -r '.file_path')${excludeClause}
            rel_path=''${file_path#/}
            dest="$tmp/$rel_path"
            mkdir -p "$(dirname "$dest")"
            encoded_file_path=$(jq -rn --arg path "$file_path" '$path|@uri')
            curl --fail --silent --show-error --location \
              --output "$dest" \
              "$base_url/d/$token/files/?p=$encoded_file_path&dl=1"
          fi
        done
      }

      fetch_dir "/"

      mkdir -p "$target"
      rsync -a --delete "$tmp/" "$target/"
      find "$target" -type f | sort > "$work_root/manifest"
    '';
  };

  setDarwinBackground = pkgs.writeShellApplication {
    name = "set-darwin-background";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
    ];
    text = ''
      set -eu

      backgrounds="$HOME/.local/backgrounds"
      state="$HOME/.local/state/backgrounds-sync/current"

      apply() {
        /usr/bin/osascript - "$1" <<'APPLESCRIPT'
      on run argv
        tell application "System Events"
          repeat with desktopItem in desktops
            set picture of desktopItem to item 1 of argv
          end repeat
        end tell
      end run
      APPLESCRIPT
      }

      # System Events only reaches the space that is currently visible on each
      # display, so Hammerspoon re-applies the same image on every space change.
      if [ "''${1:-}" = "--reapply" ] && [ -f "$state" ]; then
        wallpaper=$(cat "$state")
        # A wallpaper that has since been excluded or removed falls through to
        # a fresh pick instead of leaving the stale image on screen.
        if [ -f "$wallpaper" ]; then
          apply "$wallpaper"
          exit 0
        fi
      fi

      hour=$(date +%H)

      if [ "$hour" -lt 6 ] || [ "$hour" -ge 19 ]; then
        period=evening
      elif [ "$hour" -ge 12 ]; then
        period=afternoon
      else
        period=morning
      fi

      period_dir="$backgrounds/$period"
      [ -d "$period_dir" ] || exit 0

      wallpaper=$(find "$period_dir" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' -o -iname '*.webp' \) \
        | sort | shuf -n 1)
      [ -n "$wallpaper" ] || exit 0

      mkdir -p "$(dirname "$state")"
      printf '%s\n' "$wallpaper" > "$state"
      apply "$wallpaper"
    '';
  };

  linuxConfig = {
    systemd.user.services.sync-backgrounds = {
      Unit = {
        Description = "Sync wallpapers from Seafile";
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${syncBackgrounds}/bin/sync-backgrounds";
      };
    };

    systemd.user.timers.sync-backgrounds = {
      Unit.Description = "Sync wallpapers from Seafile periodically";
      Timer = {
        OnStartupSec = "1min";
        OnUnitActiveSec = "6h";
        Persistent = true;
        Unit = "sync-backgrounds.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  darwinConfig = {
    home.packages = [
      syncBackgrounds
      setDarwinBackground
    ];

    launchd.agents.sync-backgrounds = {
      enable = true;
      config = {
        Label = "org.yigit.sync-backgrounds";
        ProgramArguments = [ "${syncBackgrounds}/bin/sync-backgrounds" ];
        RunAtLoad = true;
        StartInterval = 21600;
        ProcessType = "Background";
        StandardOutPath = "/tmp/sync-backgrounds.log";
        StandardErrorPath = "/tmp/sync-backgrounds.error.log";
      };
    };

    launchd.agents.rotate-background = {
      enable = true;
      config = {
        Label = "org.yigit.rotate-background";
        ProgramArguments = [ "${setDarwinBackground}/bin/set-darwin-background" ];
        RunAtLoad = true;
        StartInterval = 600;
        ProcessType = "Background";
        StandardOutPath = "/tmp/rotate-background.log";
        StandardErrorPath = "/tmp/rotate-background.error.log";
      };
    };
  };

  userConfig = if pkgs.stdenv.isDarwin then darwinConfig else linuxConfig;
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
