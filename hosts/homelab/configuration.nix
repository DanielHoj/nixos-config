{ config, pkgs, lib, ... }:
# Lenovo ThinkCentre M75q Gen 2 Tiny (AMD Ryzen 5 Pro 5650GE, 64 GB) — headless
# homelab node: a NixOS hypervisor (Incus) running a Talos k8s test cluster that
# mirrors the Hetzner prod box. No desktop; the dev env comes from the `base`
# home profile (SSH in for the same shell/nvim/tmux/toolchains).
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/incus.nix
  ];

  networking.hostName = "homelab";

  # ZFS requires a unique 8-hex-digit host id. CHANGE before install:
  #   head -c 8 /etc/machine-id   (or `head -c4 /dev/urandom | od -A none -t x4`)
  networking.hostId = "deadbeef";
  boot.supportedFilesystems = [ "zfs" ];
  # Don't let ZFS ARC eat RAM the VMs need (64 GB box; cap ARC at 8 GB).
  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ];

  # Bootstrap password — change with `passwd` after first boot (SSH key is the
  # real access path; see modules/common.nix authorizedKeys).
  users.users.danielh.initialPassword = "changeme";

  # This box is the tailnet's gateway into the lab: forward/advertise routes
  # (subnet router) and offer itself as an exit node. Advertising the Incus
  # bridge subnet lets the laptops hit the Talos VM IPs (10.100.0.10-12)
  # directly over the tailnet — no LAN presence, no port-forwarding.
  # Both need one-time approval in the Tailscale admin console after enrolling.
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.extraUpFlags = [
    "--advertise-routes=10.100.0.0/24"  # Incus incusbr0 subnet (see modules/incus.nix)
    "--advertise-exit-node"
  ];

  # First install target; do not change casually.
  system.stateVersion = "25.05";
}
