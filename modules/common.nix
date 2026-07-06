{ config, pkgs, lib, ... }:
# Base system config shared by every host (VM + bare metal). Host-specific bits
# (hostname, initial password, guest agents, hardware) live in hosts/<host>/.
{
  # --- Boot (UEFI, systemd-boot) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Nix / flakes ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # --- Networking ---
  networking.networkmanager.enable = true;

  # --- Locale / time ---
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";
  console.keyMap = "us";

  # --- Compressed RAM swap (matches the current machine; no disk swap) ---
  zramSwap.enable = true;

  # --- User ---
  users.users.danielh = {
    isNormalUser = true;
    description = "danielh";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
    # Host SSH key so a workstation can drive this box over SSH.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINgxQ+TL2YRSEjor/6mXuOv6Sq57ncBjZQBjD+JXYm8t danielhoj1990@gmail.com"
    ];
  };
  programs.zsh.enable = true;

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --- SSH ---
  services.openssh.enable = true;

  # --- Bootstrap tools at system level ---
  # neovim from unstable: the nvim config targets 0.11+ APIs (vim.lsp.enable,
  # lsp/*.lua) and modern diffopt (inline:char).
  environment.systemPackages = with pkgs; [ git unstable.neovim ];
}
