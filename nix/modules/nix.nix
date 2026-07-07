{ ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.trusted-users = [
    "root"
    "yeet"
    "@wheel"
  ];

  nix.settings.sandbox = true;
  nix.settings.builders-use-substitutes = true;
  nix.settings.auto-optimise-store = true;
}
