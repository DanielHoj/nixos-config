# Talos clusters (talhelper)

Declarative Talos configs for the two clusters, kept in parity:

```
talos/
├── patches/common.yaml     # shared machine-config — applied to BOTH clusters
├── homelab/talconfig.yaml  # test cluster (Incus VMs on the ThinkCentre)
└── hetzner/talconfig.yaml   # prod cluster (bare-metal Hetzner)
```

Both point at the same `patches/common.yaml` and pin the **same** `talosVersion`
and `kubernetesVersion`, so the homelab is a faithful mirror of prod. Change a
setting once → it applies to test, then prod.

## Bootstrap flow (per cluster, homelab first)

```sh
cd talos/homelab

# 1. Generate cluster secrets ONCE (CA, tokens). Keep it OUT of git — either
#    gitignored (default) or sops-encrypt it (talsecret.sops.yaml).
talhelper gensecret > ../talsecret.yaml

# 2. Render per-node machine configs into ./clusterconfig/ (gitignored).
talhelper genconfig

# 3. Boot the Talos VMs (Incus), then apply each node's config in maintenance mode.
talhelper gencommand apply | sh          # or run the printed talosctl apply-config cmds

# 4. Bootstrap etcd on the first control-plane, then fetch kubeconfig.
talhelper gencommand bootstrap | sh
talhelper gencommand kubeconfig | sh
```

Then hand the cluster to Flux — see `../kubernetes/README.md`.

## Secrets (public repo!)
`talsecret.yaml` and `clusterconfig/` are gitignored. For a nicer flow, encrypt
the secret with sops (`talsecret.sops.yaml`) and let `talhelper` decrypt it — so
even the secret can live in git safely.

## Homelab VMs
The homelab nodes are Incus VMs on `incusbr0` (10.100.0.0/24 — see
`../modules/incus.nix`). Boot Talos via the [windsorcli/talos-incus](https://github.com/windsorcli/talos-incus)
images or the `metal-amd64.iso`, size them (2 vCPU / 4–8 GB each is plenty),
and set the IPs to match `homelab/talconfig.yaml`.
