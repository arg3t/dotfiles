{
  pkgs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
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
            file_path=$(printf '%s\n' "$entry" | jq -r '.file_path')
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

  userConfig = {
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
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
