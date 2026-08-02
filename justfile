set dotenv-load := false

nh_target := if os() == "macos" { "darwin" } else { "os" }
nh_host := if os() == "macos" { "--hostname vela" } else { "" }

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

# Update the pinned OMP Gateway Bar input
update:
    nix flake update omp-gateway-bar --flake ./nix

# Format Nix files
fmt:
    nixfmt nix/**/*.nix

# Build custom packages with better Nix output
build:
    nom build ./nix#oh-my-pi

# Switch to the nix-darwin (macOS) or NixOS configuration for this machine
switch:
    nh {{ nh_target }} switch {{ nh_host }} ./nix

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
