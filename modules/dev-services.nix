{ pkgs, ... }:
# Workstation dev services carried over from the Arch setup: Docker (the daemon
# was enabled there). Shared across hosts so they're verifiable on the VM before
# the bare-metal migration. Projects run their own Docker Postgres instances for
# version/data isolation instead of enabling a system-wide PostgreSQL service.
{
  # --- Docker ---
  virtualisation.docker.enable = true;
  users.users.danielh.extraGroups = [ "docker" ];
  environment.systemPackages = [ pkgs.docker-compose ];  # `docker compose` v2
}
