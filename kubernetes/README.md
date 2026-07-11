# Kubernetes / Flux (GitOps)

The app is defined **once** and promoted test → prod via thin overlays:

```
kubernetes/
├── clusters/
│   ├── homelab/apps.yaml   # Flux entrypoint → apps/homelab (+ flux-system/ at bootstrap)
│   └── hetzner/apps.yaml    # Flux entrypoint → apps/hetzner
└── apps/
    ├── base/               # the app: namespace + deployment + service (defined once)
    ├── homelab/            # test overlay  (1 replica, tested image tag)
    └── hetzner/            # prod overlay  (2 replicas, promoted image tag)
```

Each cluster runs its own Flux, watching **this repo** but only its own path.

## Bootstrap (homelab first)
With the cluster's kubeconfig active (`talhelper gencommand kubeconfig` from
`../talos`):

```sh
flux bootstrap github \
  --owner=DanielHoj \
  --repository=nixos-config \
  --branch=main \
  --path=kubernetes/clusters/homelab \
  --personal
```

Flux commits its controllers + a `GitRepository` named `flux-system` into
`clusters/homelab/`, then reconciles `apps.yaml` → deploys `apps/homelab`.
Repeat with `--path=kubernetes/clusters/hetzner` on the prod cluster.

## The promote flow
1. Build + push your app image (tag it).
2. Bump `newTag` in `apps/homelab/kustomization.yaml`, commit → Flux deploys to test.
3. Verify on the homelab cluster.
4. Bump the same tag in `apps/hetzner/kustomization.yaml`, commit → Flux deploys to prod.

Same manifests, same platform (Talos), only the overlay differs — that's the parity.

## Secrets (public repo!)
Do **not** commit plaintext Secrets. Use **sops-nix + Flux's sops decryption**
or **sealed-secrets**. Add a `kubernetes/infrastructure/` tree (same base+overlay
shape) for shared cluster services (cert-manager, ingress-nginx, MetalLB,
sealed-secrets) and a second Flux Kustomization per cluster to reconcile it.

## CNI note
Talos ships flannel by default (fine to start). If prod uses Cilium, set
`cluster.network.cni.name = none` in `../talos/patches/common.yaml` and install
Cilium here as the first infrastructure component — keep it identical in both.
