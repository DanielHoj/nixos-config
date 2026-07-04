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
    # Host SSH key so the host can drive the VM over the port-forward.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINgxQ+TL2YRSEjor/6mXuOv6Sq57ncBjZQBjD+JXYm8t danielhoj1990@gmail.com"
    ];
  };
  programs.zsh.enable = true;

  # --- Bluetooth (for bare metal; inert in the VM with no adapter) ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --- SSH (host drives the VM via `ssh -p 2222 danielh@localhost`) ---
  services.openssh.enable = true;
  # Eval VM: let wheel run sudo without a password (so remote nixos-rebuild works).
  security.sudo.wheelNeedsPassword = false;

  # --- Bootstrap tools at system level ---
  # neovim from unstable: the nvim config targets 0.11+ APIs (vim.lsp.enable,
  # lsp/*.lua) and modern diffopt (inline:char) the stale stable pin lacks.
  environment.systemPackages = with pkgs; [ git unstable.neovim ];

  # First install target; do not change casually.
  system.stateVersion = "25.05";
}
