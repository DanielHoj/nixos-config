{ config, pkgs, lib, ... }:
# Declarative secrets via sops-nix. Encrypted values live in secrets/*.yaml
# (safe to commit — this is a public repo). At activation each host decrypts
# with its own SSH ed25519 host key (converted to an age key), so no plaintext
# and no per-host key material ever hits the repo. See .sops.yaml for policy.
{
  # The default file each `sops.secrets.<name>` reads from.
  sops.defaultSopsFile = ../secrets/secrets.yaml;

  # Decrypt using THIS host's SSH host key. The matching age public key must be
  # a recipient in .sops.yaml (add new hosts there, then `sops updatekeys`).
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Declared secrets are decrypted to /run/secrets/<name> (root-only tmpfs).
  # tailscale-authkey backs services.tailscale.authKeyFile once a real reusable
  # key is stored — enrol the headless homelab with zero interaction.
  sops.secrets.tailscale-authkey = { };

  # Editing/enrolment tooling on every host: `sops secrets/secrets.yaml` to
  # edit; `ssh-to-age` to derive a freshly-installed host's recipient key.
  environment.systemPackages = with pkgs; [ sops age ssh-to-age ];
}
