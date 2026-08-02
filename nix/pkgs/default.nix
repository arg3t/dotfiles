{ pkgs }:

{
  oh-my-pi = pkgs.callPackage ./oh-my-pi/package.nix { };
  podctl = pkgs.callPackage ./podctl/package.nix { };
  maccy = pkgs.callPackage ./maccy/package.nix { };
}
