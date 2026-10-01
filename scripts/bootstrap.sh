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
# Filter to IPv4 only -- an unfiltered jsonpath can return both the node's
# IPv4 and IPv6 InternalIP, and Traefik's LoadBalancer Service here is
# IPv4-only, so an IPv6 entry in /etc/hosts would be unreachable.
NODE_IP="$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' '\n' | grep -v ':' | head -1)"
echo ">> podinfo is reachable via the Traefik ingress."
echo "   Add this to /etc/hosts on your client, then open http://podinfo.test :"
echo "   ${NODE_IP}  podinfo.test"
echo "   (avoid .local -- Chromium browsers resolve it via mDNS, not /etc/hosts)"
