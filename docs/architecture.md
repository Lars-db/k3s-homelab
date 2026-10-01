# Architecture & design notes

This document explains the *why* behind the choices in this repo.

## Cluster distribution: k3s

[k3s](https://k3s.io) is a CNCF-certified Kubernetes distribution packaged as a
single ~70MB binary. On a Raspberry Pi 5 (4 cores, 8GB RAM) a full upstream
kubeadm install would waste resources on components we don't need.

The project runs a single server node that also schedules workloads (control-plane +
worker on one host).

## Reproducibility

The install script pins `K3S_VERSION`. An unpinned `curl https://get.k3s.io | sh`
installs whatever is latest, which means two "identical" installs weeks apart can
differ. Pinning makes the cluster a deterministic artifact.

The kubeconfig is written with mode `644` and copied into the invoking user's
`~/.kube/config` so day-to-day `kubectl` needs no `sudo`.

## Declarative workloads

Everything that runs on the cluster is a manifest under `manifests/`, applied
through a single Kustomization. This gives one entrypoint
(`kubectl apply -k manifests`) and makes drift visible: what's in Git is what
should be running.

Kustomize is chosen over Helm deliberately for the initial setup. Next step is adding Helm for CKAD practice.

## Workload hardening

The podinfo Deployment applies Pod Security "baseline"/"restricted" practices:

- `runAsNonRoot: true`, explicit non-root UID.
- `readOnlyRootFilesystem: true`.
- `allowPrivilegeEscalation: false` and all Linux capabilities dropped.
- `seccompProfile: RuntimeDefault`.
- CPU/memory **requests and limits** on every container, which also makes the
  HorizontalPodAutoscaler's CPU-utilization target meaningful.

## CI / safety

`.github/workflows/validate.yml` runs on every push and PR:

1. **kubeconform** renders the Kustomize output and validates every object
   against the Kubernetes 1.34 OpenAPI schemas (`-strict` rejects unknown fields).
2. **shellcheck** statically analyses the install/bootstrap scripts.

Neither job needs a live cluster, so CI is fast and free.

## Trade-offs & known limitations

- **Single node = single point of failure.** Acceptable for a homelab/demo; not
  for production. HA path is documented in the README roadmap.
- **No TLS on the ingress yet.** `podinfo.test` is plain HTTP over the LAN.
- **`make bootstrap` is a manual push.** The natural next step is GitOps
  (Argo CD) so the cluster pulls from this repo automatically.
