# k3s-homelab

A reproducible, single-node [k3s](https://k3s.io) Kubernetes cluster running on
a Raspberry Pi 5, with all install steps and workloads defined as code.

The goal is a cluster you can **destroy and rebuild from scratch in minutes**,
where the Git repository is the source of truth for everything that runs on it.

---

## Why this exists

Clicking commands into a terminal until a cluster works is not repeatable. This
repo treats the cluster as cattle, not a pet:

- **Pinned, scripted install** — same k3s version, same flags, every time.
- **Declarative workloads** — plain Kubernetes manifests, applied with
  `kubectl -k` (Kustomize). No hidden state.
- **Validated in CI** — every push lints the shell scripts and validates the
  manifests against the Kubernetes API schemas, so a broken YAML never lands.
- **One-command lifecycle** — `make install`, `make bootstrap`, `make uninstall`.

---

## Topology

```
┌──────────────────────── Raspberry Pi 5 (arm64, 8GB) ────────────────────────┐
│                                                                              │
│   k3s server (control-plane + worker)                                        │
│   ├── Traefik          ← bundled ingress controller                          │
│   ├── metrics-server   ← bundled, powers the HPA                             │
│   └── namespace: demo                                                        │
│        └── podinfo  (Deployment x2 → HPA 2–5, Service, Ingress)              │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
        host: podinfo.test  ──▶  Traefik  ──▶  Service  ──▶  podinfo pods
```

---

## Repository layout

```
k3s-homelab/
├── scripts/
│   ├── install-k3s.sh     # pinned, reproducible k3s install
│   ├── uninstall-k3s.sh   # full teardown (destructive)
│   └── bootstrap.sh       # apply all manifests + wait for rollout
├── manifests/
│   ├── kustomization.yaml # single entrypoint: kubectl apply -k manifests
│   ├── 00-namespaces.yaml
│   └── podinfo/           # demo app: deployment, service, hpa, ingress
├── .github/workflows/
│   └── validate.yml       # CI: kubeconform + shellcheck
├── docs/
│   └── architecture.md    # design decisions & trade-offs
├── Makefile               # make help
└── README.md
```

---

## Quick start

> Prerequisites: a Linux host (tested on Raspberry Pi OS / Ubuntu 24.04 arm64),
> `curl`, and `kubectl` (installed automatically with k3s).

```bash
# 1. Install the cluster (pins k3s version, writes a readable kubeconfig)
make install            # == sudo ./scripts/install-k3s.sh

# 2. Point kubectl at the cluster
export KUBECONFIG=$HOME/.kube/config
kubectl get nodes

# 3. Deploy the workloads
make bootstrap          # == ./scripts/bootstrap.sh

# 4. Reach the app (add the printed line to /etc/hosts on your client)
#    <node-ip>  podinfo.test
curl http://podinfo.test
```

Tear it all down with `make uninstall` (removes k3s and every bit of state).

---

## Design decisions

| Decision | Why |
|----------|-----|
| **k3s over full kubeenetes** | Single binary, low memory footprint — ideal for a Pi. Still fully CNCF-conformant. |
| **Pinned k3s version** | Reproducibility. An unpinned `get.k3s.io` install drifts over time. |
| **Kustomize, not Helm** | Zero extra tooling (built into kubectl), and the manifests stay readable. |
| **podinfo as the demo app** | Small, multi-arch, and exposes real endpoints (`/healthz`, `/readyz`) so probes and the HPA are meaningful. |
| **CI validation** | `kubeconform` catches schema errors and `shellcheck` catches script bugs before they reach the cluster. |
| **Hardened pod spec** | `runAsNonRoot`, read-only root FS, dropped capabilities — baseline Pod Security. |

See [`docs/architecture.md`](docs/architecture.md) for the longer version.

---

## Next steps / roadmap

This is intentionally a lean foundation. Natural extensions:

- **GitOps** — hand `manifests/` to Argo CD or Flux so the cluster self-syncs
  from this repo instead of a manual `make bootstrap`.
- **TLS** — cert-manager + a real domain for HTTPS ingress.
- **Observability** — kube-prometheus-stack for metrics and dashboards.
- **Secrets** — Sealed Secrets or External Secrets so secrets can live in Git safely.
