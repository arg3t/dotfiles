{ pkgs }:

{
  oh-my-pi = pkgs.callPackage ./oh-my-pi/package.nix { };
  podctl = pkgs.callPackage ./podctl/package.nix { };
  hammerspoon = pkgs.callPackage ./hammerspoon/package.nix { };
  supercmd = pkgs.callPackage ./supercmd/package.nix { };
}
