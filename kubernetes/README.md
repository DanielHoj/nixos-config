# Kubernetes / Flux (GitOps)

Each cluster runs its own Flux, watching **this repo** but only its own
`clusters/<cluster>/` path. Shared infrastructure and the app are defined
**once** and promoted test → prod via thin overlays.

```
kubernetes/
├── clusters/
│   ├── homelab/            # Flux entrypoints for the test cluster
│   │   ├── infrastructure.yaml   # infra-controllers → infra-configs
│   │   └── apps.yaml             # apps (dependsOn infra-configs)
│   └── hetzner/            # same two entrypoints for prod
├── infrastructure/
│   ├── controllers/       # cert-manager + ingress-nginx + metallb (HelmReleases)
│   │                      #   identical on both clusters — the parity point
│   └── configs/
│       ├── base/          # ClusterIssuers (Let's Encrypt staging + prod)
│       ├── homelab/       # base + homelab MetalLB pool (LAN range)
│       └── hetzner/       # base + hetzner MetalLB pool (failover IPs)
└── apps/
    ├── base/              # the app: namespace + deployment + service (once)
    ├── homelab/           # test overlay  (1 replica, tested image tag)
    └── hetzner/           # prod overlay  (2 replicas, promoted image tag)
```

## Reconciliation order

`flux bootstrap ... --path=clusters/<cluster>` applies **every** Flux
Kustomization in that dir. They self-order via `dependsOn`:

```
infra-controllers  (cert-manager / ingress-nginx / metallb operators + CRDs)
      │  dependsOn
      ▼
infra-configs      (ClusterIssuers, MetalLB pool — need the CRDs above)
      │  dependsOn
      ▼
apps               (the app's Ingress needs the controller + an issuer)
```

Without the ordering, e.g. a `ClusterIssuer` would fail to apply before
cert-manager's CRDs exist.

## Bootstrap (homelab first)

With the cluster's kubeconfig active (`talhelper gencommand kubeconfig` from
`../talos`):

**1. Create the SOPS age key the cluster decrypts with.** Generate a
**dedicated** cluster key (not the host/admin key), store the private half as a
Secret in `flux-system`, and add the **public** half to `../.sops.yaml`:

```sh
age-keygen -o homelab-cluster.agekey            # prints the public key too
kubectl create namespace flux-system            # (bootstrap makes this too; ok if it exists)
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey=homelab-cluster.agekey
# then: uncomment &homelab-cluster in ../.sops.yaml with the public key,
#       `sops updatekeys` any existing kubernetes/**/*.sops.yaml, commit.
```

Keep `homelab-cluster.agekey` out of git (it's covered by `../talos/.gitignore`
patterns only if placed there — store it in your password manager). The admin
key still decrypts everything for editing.

**2. Bootstrap Flux:**

```sh
flux bootstrap github \
  --owner=DanielHoj \
  --repository=nixos-config \
  --branch=main \
  --path=kubernetes/clusters/homelab \
  --personal
```

Flux commits its controllers + a `GitRepository` named `flux-system` into
`clusters/homelab/`, then reconciles infrastructure → apps.

Repeat both steps on the prod cluster with a **separate** `hetzner-cluster`
age key and `--path=kubernetes/clusters/hetzner`.

## Secrets (public repo — never commit plaintext)

Secrets are **sops-encrypted** (same age scheme as the NixOS hosts — see the
repo-root `../modules/sops.nix`). Name encrypted files `*.sops.yaml`; the
`../.sops.yaml` rule encrypts them to the admin key + the cluster keys, and the
Flux Kustomizations (`decryption.provider: sops`, `secretRef: sops-age`) decrypt
them in-cluster at apply time.

Create one:

```sh
cat > kubernetes/apps/base/db-secret.sops.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata: { name: db, namespace: myapp }
stringData:
  password: super-secret
EOF
sops --encrypt --in-place kubernetes/apps/base/db-secret.sops.yaml
# add it to the relevant kustomization.yaml resources, commit → Flux decrypts it.
```

## The promote flow
1. Build + push your app image (tag it).
2. Bump `newTag` in `apps/homelab/kustomization.yaml`, commit → Flux deploys to test.
3. Verify on the homelab cluster.
4. Bump the same tag in `apps/hetzner/kustomization.yaml`, commit → Flux deploys to prod.

Same manifests, same platform (Talos), same infrastructure — only the overlay
differs. That's the parity.

## Notes
- **Chart versions** in `infrastructure/controllers/*` are pinned but should be
  verified against upstream at bootstrap (marked `pin-and-verify`).
- **MetalLB ranges** are placeholders — set the homelab range to a free block
  outside your router's DHCP pool; set hetzner to your assigned failover IP(s).
- **CNI:** Talos ships flannel (fine to start). To match a Cilium prod, set
  `cluster.network.cni.name = none` in `../talos/patches/common.yaml` and add
  Cilium as the first controller here — keep it identical on both clusters.
