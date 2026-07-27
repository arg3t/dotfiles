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

# Format Nix files
fmt:
    nixfmt nix/**/*.nix

# Build custom packages with better Nix output
build:
    nom build ./nix#oh-my-pi

# Update flake inputs and check the result
update:
    nix flake update ./nix
    nix flake check ./nix

# Switch to the NixOS configuration for this machine
switch:
    nh os switch ./nix

# Build the NixOS configuration for next boot
boot:
    nh os boot ./nix

# Remove old Nix generations and garbage while keeping recent rollbacks
clean:
    nh clean all --keep 5
