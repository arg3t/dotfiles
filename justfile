set dotenv-load := false

# Show available recipes
default:
    @just --list

# Show available recipes
list:
    @just --list

# Check the Nix flake
check:
    nix flake check ./nix

# Alias for check
test: check

# Refresh pinned sources. With no TARGET, run every nix/pkgs/*/update.sh and
# then update the pinned flake inputs. A named package TARGET refreshes only it.
# TARGET is a package (e.g. codex), `inputs`, or empty to update everything.
# Pass SKIP="pkg1 pkg2" to skip packages: just update SKIP="omniwm pi"
update target="" skip="":
    #!/usr/bin/env bash
    set -euo pipefail
    pkgs_dir="{{ justfile_directory() }}/nix/pkgs"

    skip_str="{{ skip }}"

    should_skip() {
      local pkg="$1"
      for s in $skip_str; do
        [ "$s" = "$pkg" ] && return 0
      done
      return 1
    }

    update_pkg() {
      should_skip "$1" && { echo "==> skipping package: $1" >&2; return; }
      echo "==> updating package: $1" >&2
      ( cd "$pkgs_dir/$1" && ./update.sh )
    }
    update_inputs() {
      echo "==> updating flake input: omp-gateway-bar" >&2
      nix flake update omp-gateway-bar --flake ./nix
    }
    list_pkgs() {
      for s in "$pkgs_dir"/*/update.sh; do basename "$(dirname "$s")"; done
    }

    case "{{ target }}" in
      "")
        while read -r pkg; do update_pkg "$pkg"; done < <(list_pkgs)
        update_inputs
        ;;
      inputs)
        update_inputs
        ;;
      *)
        if [ -x "$pkgs_dir/{{ target }}/update.sh" ]; then
          update_pkg "{{ target }}"
        else
          echo "update: unknown target '{{ target }}'" >&2
          echo "targets: inputs $(list_pkgs | tr '\n' ' ')" >&2
          exit 1
        fi
        ;;
    esac

# Format Nix files
fmt:
    nixfmt nix/**/*.nix

# Build custom packages with better Nix output
build:
    nom build ./nix#oh-my-pi

# Auto-detected nh backend + this machine's system config (one full-system
# config per OS). Pass args explicitly to override on exception machines.
default_backend := if os() == "macos" { "darwin" } else { "os" }
default_host    := if os() == "macos" { "vela" } else { "ursa" }

# Switch a NixOS or nix-darwin system configuration.
switch target=default_host backend=default_backend:
    nh {{ backend }} switch --hostname {{ target }} ./nix

# Switch a standalone Home Manager profile.
home-switch profile:
    home-manager switch -b hm-backup --flake ./nix#{{ profile }}


# Build the NixOS configuration for next boot (NixOS only)
boot:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{ os() }}" = "macos" ]; then
      echo "boot: nix-darwin has no boot generation; use 'just switch'" >&2
      exit 1
    fi
    nh os boot ./nix

# Remove old Nix generations and garbage while keeping recent rollbacks
clean:
    nh clean all --keep 5
