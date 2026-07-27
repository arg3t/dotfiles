{
  pkgs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = {
    home.packages = with pkgs; [
      nix-forecast
      nix-health
      nix-info
      nix-update
      nixfmt
      nh
      nix-diff
      nix-output-monitor
      nix-tree
      nvd
      nixpkgs-reviewFull
      nixpkgs-track
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
