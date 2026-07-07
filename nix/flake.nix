{
  description = "Alpha Centauri flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, home-manager, impermanence, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      # Custom packages: nix build .#oh-my-pi
      packages.${system} = import ./pkgs {
        pkgs = nixpkgs.legacyPackages.${system};
      };

      # Overlay exposing them as pkgs.our.*
      overlays.default = final: prev: {
        our = import ./pkgs { pkgs = final; };
      };

      nixosConfigurations.ursa = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };

        modules = [
          { nixpkgs.overlays = [ self.overlays.default ]; }
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          ./hosts/ursa.nix
        ];
      };
    };
}
