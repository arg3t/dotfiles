{
  description = "Alpha Centauri flake";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-style-plymouth = {
      url = "github:SergioRibera/s4rchiso-plymouth-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omp-gateway-bar = {
      url = "github:arg3t/omp-gateway-bar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ponytail = {
      url = "github:DietrichGebert/ponytail/v4.9.0";
      flake = false;
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      impermanence,
      nix-darwin,
      ...
    }@inputs:
    let
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";

      unstable-overlay = final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit (final) system;
          config.allowUnfree = true;
        };
        flameshot = final.unstable.flameshot;
      };
    in
    {
      packages.${linuxSystem} = import ./pkgs {
        pkgs = nixpkgs.legacyPackages.${linuxSystem};
      };

      packages.${darwinSystem} = import ./pkgs {
        pkgs = nixpkgs.legacyPackages.${darwinSystem};
      };

      overlays.default = final: prev: {
        our = import ./pkgs { pkgs = final; };
      };

      nixosConfigurations.ursa = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = {
          inherit inputs;
          username = "yeet";
          homeDirectory = "/home/yeet";
          standaloneHome = false;
        };

        modules = [
          {
            nixpkgs.overlays = [
              self.overlays.default
              unstable-overlay
              inputs.mac-style-plymouth.overlays.default
            ];
          }
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          inputs.nix-index-database.nixosModules.nix-index
          ./hosts/ursa.nix
        ];
      };

      nixosConfigurations.crux = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = {
          inherit inputs;
          username = "yeet";
          homeDirectory = "/home/yeet";
          standaloneHome = false;
        };

        modules = [
          {
            nixpkgs.overlays = [
              self.overlays.default
              unstable-overlay
              inputs.mac-style-plymouth.overlays.default
            ];
          }
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          inputs.nix-index-database.nixosModules.nix-index
          ./hosts/crux.nix
        ];
      };

      homeConfigurations.ara = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = linuxSystem;
          overlays = [ self.overlays.default ];
        };
        extraSpecialArgs = {
          inherit inputs;
          username = "yeet";
          homeDirectory = "/home/yeet";
          standaloneHome = true;
        };
        modules = [ ./hosts/ara.nix ];
      };

      homeConfigurations.lyra = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = linuxSystem;
          overlays = [ self.overlays.default ];
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
        };
        extraSpecialArgs = {
          inherit inputs;
          username = "yeet";
          homeDirectory = "/home/yeet";
          standaloneHome = true;
        };
        modules = [ ./hosts/lyra.nix ];
      };

      homeConfigurations.arca = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = linuxSystem;
          overlays = [ self.overlays.default ];
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
        };
        extraSpecialArgs = {
          inherit inputs;
          username = "yigit.colakoglu";
          homeDirectory = "/home/yigit.colakoglu";
          standaloneHome = true;
        };
        modules = [ ./hosts/lyra.nix ];
      };

      darwinConfigurations.vela = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = {
          inherit inputs;
          username = "yigit.colakoglu";
          homeDirectory = "/Users/yigit.colakoglu";
          standaloneHome = false;
        };
        modules = [
          {
            nixpkgs.overlays = [ self.overlays.default ];
          }
          home-manager.darwinModules.home-manager
          ./hosts/vela.nix
        ];
      };
    };
}
