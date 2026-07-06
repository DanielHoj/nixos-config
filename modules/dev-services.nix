{ config, pkgs, lib, ... }:
# Workstation dev services carried over from the Arch setup: Docker (the daemon
# was enabled there) and a local PostgreSQL for development. Shared across hosts
# so they're verifiable on the VM before the bare-metal migration.
{
  # --- Docker ---
  virtualisation.docker.enable = true;
  users.users.danielh.extraGroups = [ "docker" ];
  environment.systemPackages = [ pkgs.docker-compose ];  # `docker compose` v2

  # --- PostgreSQL (local dev) ---
  # Default local auth is peer, so `psql` as danielh maps to the danielh role
  # with no password. Superuser for convenient local development.
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "danielh" ];
    ensureUsers = [{
      name = "danielh";
      ensureClauses.superuser = true;
    }];
  };
}
