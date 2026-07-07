# Custom packages, callPackage'd nixpkgs-style.
# Add new packages as pkgs/<name>/package.nix and list them here.
{ pkgs }:

{
  oh-my-pi = pkgs.callPackage ./oh-my-pi/package.nix { };
}
