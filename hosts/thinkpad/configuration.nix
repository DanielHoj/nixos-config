{ config, pkgs, lib, ... }:
# ThinkPad T14 Gen 2i (Intel i7-1185G7, Iris Xe, AX201). CPU/GPU/SSD/backlight
# tuning comes from nixos-hardware.nixosModules.lenovo-thinkpad-t14-intel
# (wired in flake.nix). Partitioning is declarative in ./disko.nix.
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "thinkpad";

  # Bootstrap password — CHANGE with `passwd` immediately after first boot.
  users.users.danielh.initialPassword = "changeme";

  # --- Laptop power / firmware ---
  services.power-profiles-daemon.enable = true;  # battery/balanced/performance profiles
  services.fwupd.enable = true;                   # LVFS firmware updates (ThinkPad)

  # First install target; do not change casually.
  system.stateVersion = "25.05";
}
