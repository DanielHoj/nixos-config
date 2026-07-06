{ config, pkgs, lib, ... }:
# Base system config shared by every host (VM + bare metal). Host-specific bits
# (hostname, initial password, guest agents, hardware) live in hosts/<host>/.
{
  # --- Boot (UEFI, systemd-boot) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Cap kept generations so the 1 GiB ESP can't fill with old kernels.
  boot.loader.systemd-boot.configurationLimit = 10;

  # --- Nix / flakes ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  # Disk hygiene: dedup the store + prune old generations weekly.
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # --- Networking ---
  networking.networkmanager.enable = true;

  # --- Locale / time ---
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";
  console.keyMap = "us";

  # --- Compressed RAM swap (matches the current machine; no disk swap) ---
  zramSwap.enable = true;

  # --- External drives: mount NTFS + exFAT USB sticks / SD cards ---
  boot.supportedFilesystems = [ "ntfs" "exfat" ];

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

  # --- Desktop integration services ---
  services.upower.enable = true;    # battery status (waybar) + power events
  services.udisks2.enable = true;   # removable-drive mounting (backs udiskie)
  services.gvfs.enable = true;      # trash, MTP (phones), network shares (yazi)
  programs.nix-ld.enable = true;    # run foreign/FHS dynamic binaries (dev tooling)

  # --- SSH (key-only; the authorized key above is the sole way in) ---
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;

  # --- Bootstrap tools at system level ---
  # neovim from unstable: the nvim config targets 0.11+ APIs (vim.lsp.enable,
  # lsp/*.lua) and modern diffopt (inline:char).
  environment.systemPackages = with pkgs; [ git unstable.neovim ];
}
