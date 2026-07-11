{ config, pkgs, lib, ... }:
# Tailscale — a WireGuard mesh so every host is reachable by its stable tailnet
# name (MagicDNS) from anywhere, no port-forwarding. This is how the laptops
# reach the *headless* homelab: `ssh danielh@homelab` just works off-LAN.
#
# Defaults here are for a leaf/client node. The homelab overrides
# useRoutingFeatures + extraUpFlags to also be a subnet router + exit node
# (see hosts/homelab/configuration.nix).
{
  services.tailscale = {
    enable = true;
    # Open the WireGuard UDP port so peers can establish direct (non-relayed)
    # connections. checkReversePath is loosened below for the same reason.
    openFirewall = true;
    # "client" lets this node USE exit nodes / accept advertised subnet routes
    # (e.g. the homelab's Incus subnet). The homelab bumps this to "both" to
    # also forward/advertise. "none" would disable both directions.
    useRoutingFeatures = "client";
    # Tailscale SSH: authenticate SSH by tailnet identity (ACL-gated) instead of
    # keys. Coexists with the key-only openssh in common.nix; handy for headless.
    extraUpFlags = [ "--ssh" ];

    # Headless enrollment without an interactive `tailscale up`: point this at a
    # tailnet auth key once sops-nix lands, and the node joins on first boot.
    # Until then, enroll once by hand:  sudo tailscale up --ssh
    #   authKeyFile = config.sops.secrets.tailscale-authkey.path;
  };

  # Trust traffic arriving over the tailnet (peers are authenticated by
  # WireGuard); lets SSH/services listen to tailnet peers without extra rules.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  # Required for exit-node / subnet-router forwarding to survive rpfilter;
  # harmless on pure clients.
  networking.firewall.checkReversePath = "loose";

  # Keep the CLI on PATH for manual `tailscale status` / enrollment.
  environment.systemPackages = [ pkgs.tailscale ];
}
