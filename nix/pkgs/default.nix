{ pkgs }:

{
  oh-my-pi = pkgs.callPackage ./oh-my-pi/package.nix { };
  herdr = pkgs.callPackage ./herdr/package.nix { };
  opencode = pkgs.callPackage ./opencode/package.nix { };
  pi = pkgs.callPackage ./pi/package.nix { };
  podctl = pkgs.callPackage ./podctl/package.nix { };
  hammerspoon = pkgs.callPackage ./hammerspoon/package.nix { };
  omniwm = pkgs.callPackage ./omniwm/package.nix { };
  supercmd = pkgs.callPackage ./supercmd/package.nix { };
  lolcrab = pkgs.callPackage ./lolcrab/package.nix { };
}
