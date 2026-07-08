{ config, pkgs, lib, ... }:
# NixOS as a declarative hypervisor for the homelab. Incus (LXD fork) hosts the
# Talos VMs that form the k8s test cluster mirroring the Hetzner prod box, plus
# a web UI. The Talos VM lifecycle itself is driven outside Nix (incus + the
# talhelper repo); this module just provides the substrate + declarative init.
#
# Prereqs: enable SVM/AMD-V in the ThinkCentre BIOS; a ZFS pool `tank` must exist
# (see hosts/homelab/disko.nix) so the `tank/incus` storage source is present.
{
  networking.nftables.enable = true;   # Incus requires the nftables firewall backend

  virtualisation.incus = {
    enable = true;
    ui.enable = true;                  # web dashboard at https://<host>:8443

    # Declarative Incus init. NOTE: preseed is *additive* — it creates these
    # resources but never removes them if you later delete them from here.
    preseed = {
      storage_pools = [{
        name = "default";
        driver = "zfs";
        config.source = "tank/incus";
      }];
      networks = [{
        name = "incusbr0";
        type = "bridge";
        config = {
          "ipv4.address" = "10.100.0.1/24";
          "ipv4.nat" = "true";
          "ipv6.address" = "none";
        };
      }];
      profiles = [{
        name = "default";
        devices = {
          eth0 = { name = "eth0"; network = "incusbr0"; type = "nic"; };
          root = { path = "/"; pool = "default"; type = "disk"; };
        };
      }];
    };
  };

  # Drive Incus without sudo.
  users.users.danielh.extraGroups = [ "incus-admin" ];

  # talosctl / kubectl / talhelper on the host for cluster bootstrap + management.
  environment.systemPackages = with pkgs; [
    incus
    talosctl
    kubectl
    kubernetes-helm
    fluxcd
  ];
}
