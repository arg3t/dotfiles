{ pkgs, ... }:

# Headless dev server profile: ara's CLI/dev environment without the desktop
# modules. Drops firefox (GUI), backgrounds (wallpaper sync), and linux-theme
# (gtk/qt/dconf — its activation exits non-zero on a box with no dconf D-Bus
# service). Everything here activates cleanly over plain SSH.
{
  imports = [
    ../home/base.nix
    ../home/env.nix
    ../home/scripts.nix
    ../home/shell.nix
    ../home/terminal.nix
    ../home/git.nix
    ../home/packages-cli.nix
    ../home/packages-dev.nix
    ../home/packages-nix.nix
    ../home/packages-editor.nix
  ];

  # AI coding CLIs, matching vela. claude-code is unfree; the lyra/arca
  # home configurations allow it in flake.nix.
  home.packages = with pkgs; [
    claude-code
    codex
  ];
}
