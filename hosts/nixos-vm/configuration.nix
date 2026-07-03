{ config, pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # --- Boot (UEFI) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Nix / flakes ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # --- Networking ---
  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  # --- Locale / time ---
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";
  console.keyMap = "us";

  # --- User ---
  users.users.danielh = {
    isNormalUser = true;
    description = "danielh";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
    # CHANGE this after first login with `passwd`.
    initialPassword = "nixos";
  };
  programs.zsh.enable = true;

  # --- SSH (convenient for pasting/config transfer during eval) ---
  services.openssh.enable = true;

  # --- Bootstrap tools at system level ---
  environment.systemPackages = with pkgs; [ git neovim ];

  # First install target; do not change casually.
  system.stateVersion = "25.05";
}
