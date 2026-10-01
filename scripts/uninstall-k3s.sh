#!/usr/bin/env bash
#
# uninstall-k3s.sh — Completely remove k3s and ALL cluster data.
#
# WARNING: this is destructive and irreversible. Every workload, volume,
# and secret on this node is deleted.
#
# Usage:  sudo ./scripts/uninstall-k3s.sh
#
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: run as root (sudo $0)" >&2
  exit 1
fi

if [[ ! -x /usr/local/bin/k3s-uninstall.sh ]]; then
  echo "k3s does not appear to be installed (no k3s-uninstall.sh). Nothing to do."
  exit 0
fi

echo ">> Uninstalling k3s and deleting all cluster state ..."
/usr/local/bin/k3s-uninstall.sh
echo ">> k3s removed."
