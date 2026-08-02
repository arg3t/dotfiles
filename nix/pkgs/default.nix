{ pkgs }:

{
  oh-my-pi = pkgs.callPackage ./oh-my-pi/package.nix { };
  podctl = pkgs.callPackage ./podctl/package.nix { };
  raycast = pkgs.callPackage ./raycast/package.nix { };
}
