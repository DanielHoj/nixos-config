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

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri-flake, zen-browser, stylix, ... }:
    let
      system = "x86_64-linux";

      # Overlay exposing nightly packages as pkgs.unstable.<name>
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev) system;
          config = {
            allowUnfree = true;
            # A node-based LSP tool depends on this pnpm; the eval VM can accept it.
            permittedInsecurePackages = [ "pnpm-10.34.0" ];
          };
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
          stylix.nixosModules.stylix
          ./hosts/nixos-vm/configuration.nix
          ./modules/desktop-niri.nix
          ./modules/keyd.nix
          ./modules/stylix.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Back up (don't clobber) any pre-existing unmanaged dotfile HM
            # wants to take over, e.g. atuin's runtime-created config.toml.
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit zen-browser; };
            home-manager.users.danielh = import ./home/danielh.nix;
          }
        ];
      };
    };
}
