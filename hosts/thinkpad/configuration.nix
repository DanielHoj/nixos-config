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

  # WiFi/Bluetooth (AX201) + CPU microcode firmware.
  hardware.enableRedistributableFirmware = true;

  # --- Laptop power / thermal ---
  # TLP for battery longevity (charge stops at 80%). Note: TLP and
  # power-profiles-daemon are mutually exclusive — TLP is set-and-forget.
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      # Preserve battery health: keep charge in the 75–80% band.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  services.thermald.enable = true;   # Intel Tiger Lake thermal management
  services.fwupd.enable = true;      # LVFS firmware updates (ThinkPad)

  # --- Fingerprint reader (login / sudo / swaylock) ---
  # Enroll once after first boot: `fprintd-enroll` then `fprintd-verify`.
  services.fprintd.enable = true;

  # First install target; do not change casually.
  system.stateVersion = "25.05";
}
