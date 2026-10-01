#!/usr/bin/env bash
#
# bootstrap.sh — Apply all cluster manifests to the running k3s cluster.
#
# Idempotent: safe to run repeatedly. Uses kustomize (built into kubectl).
#
# Usage:  ./scripts/bootstrap.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ">> Using cluster:"
kubectl config current-context
kubectl get nodes

echo ">> Applying manifests (kustomize) ..."
kubectl apply -k "${REPO_ROOT}/manifests"

echo ">> Waiting for podinfo rollout ..."
kubectl -n demo rollout status deployment/podinfo --timeout=120s

echo
echo ">> Done. Resources in 'demo' namespace:"
kubectl -n demo get deploy,svc,ingress,hpa

echo
NODE_IP="$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"
echo ">> podinfo is reachable via the Traefik ingress."
echo "   Add this to /etc/hosts on your client, then open http://podinfo.local :"
echo "   ${NODE_IP}  podinfo.local"
