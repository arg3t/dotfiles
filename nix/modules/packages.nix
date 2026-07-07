{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli2
    azure-cli
    github-cli

    git
    git-lfs
    curl
    wget
    ripgrep
    fd
    jq
    htop
    fzf
    eza
    tree
    unzip
    zip
    bat
    file
    tmux
    fastfetch
    magic-wormhole

    nix-forecast
    nix-health
    nix-info
    nix-update
    nixfmt
    nixpkgs-reviewFull
    nixpkgs-track
  ];
}
