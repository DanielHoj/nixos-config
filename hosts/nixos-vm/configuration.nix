{ config, pkgs, lib, ... }:
# VM-only host config. Shared base is in ../../modules/common.nix.
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-vm";

  # Eval VM bootstrap password (change with `passwd` after first login).
  users.users.danielh.initialPassword = "nixos";
  # Passwordless sudo so the host can drive `nixos-rebuild` over SSH.
  security.sudo.wheelNeedsPassword = false;

  # --- VM guest integration (clipboard + auto-resize) ---
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # First install target; do not change casually.
  system.stateVersion = "25.05";
}
