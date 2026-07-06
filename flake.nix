{
  description = "NixOS + niri configuration (VM eval, multi-host)";

  inputs = {
    # Current stable channel (25.05 went EOL ~Jan 2026). Track the branch ref
    # directly now that we're on a live, moving channel again.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Track niri-flake's main; its CI publishes the niri-unstable build for the
    # locked rev to niri.cachix.org, so tracking latest keeps the cache warm
    # (we consume niri-flake.packages.*, not the overlay — see desktop-niri.nix).
    niri-flake.url = "github:sodiboo/niri-flake";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirk modules for the bare-metal ThinkPad.
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Declarative disk partitioning for the bare-metal install.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri-flake, zen-browser, stylix, nixos-hardware, disko, ... }:
    let
      system = "x86_64-linux";

      # Overlay exposing nightly packages as pkgs.unstable.<name>
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev) system;
          config = {
            allowUnfree = true;
            # A node-based LSP tool depends on this pnpm; we accept it.
            permittedInsecurePackages = [ "pnpm-10.34.0" ];
          };
        };
      };

      # Modules every host shares: overlays, niri, Stylix theming, the common
      # base system, the niri desktop, keyd, and Home Manager for danielh.
      # Host-specific config (hardware, hostname, guest agents) is layered on
      # per host in hosts/<host>/.
      sharedModules = [
        { nixpkgs.overlays = [ unstableOverlay niri-flake.overlays.niri ]; }
        niri-flake.nixosModules.niri
        stylix.nixosModules.stylix
        ./modules/common.nix
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

      mkHost = hostModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit niri-flake; };
        modules = sharedModules ++ hostModules;
      };
    in
    {
      nixosConfigurations = {
        # QEMU eval VM.
        nixos-vm = mkHost [ ./hosts/nixos-vm/configuration.nix ];

        # ThinkPad T14 Gen 2i — bare-metal migration target.
        thinkpad = mkHost [
          ./hosts/thinkpad/configuration.nix
          # nixos-hardware only exposes gen-specific T14 Intel modules as flake
          # outputs; import the generic t14/intel dir directly (it pulls in the
          # t14 base + common-cpu-intel + common-gpu-intel).
          "${nixos-hardware}/lenovo/thinkpad/t14/intel"
          disko.nixosModules.disko
        ];
      };
    };
}
