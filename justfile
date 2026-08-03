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
# Switch a NixOS or nix-darwin system configuration.
switch target backend:
    nh {{ backend }} switch --hostname {{ target }} ./nix

# Switch a standalone Home Manager profile.
home-switch profile:
    home-manager switch --flake ./nix#{{ profile }}

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
