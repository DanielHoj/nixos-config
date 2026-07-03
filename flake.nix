{
  description = "NixOS + niri configuration (VM eval, multi-host)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri-flake, ... }:
    let
      system = "x86_64-linux";

      # Overlay exposing nightly packages as pkgs.unstable.<name>
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev) system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit niri-flake; };
        modules = [
          { nixpkgs.overlays = [ unstableOverlay niri-flake.overlays.niri ]; }
          niri-flake.nixosModules.niri
          ./hosts/nixos-vm/configuration.nix
          ./modules/desktop-niri.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.danielh = import ./home/danielh.nix;
          }
        ];
      };
    };
}
