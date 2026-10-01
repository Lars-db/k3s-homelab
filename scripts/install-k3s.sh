#!/usr/bin/env bash
#
# install-k3s.sh — Install a single-node k3s cluster reproducibly.
#
# Pins the k3s version so every install is identical, and writes a
# world-readable kubeconfig so non-root users can run kubectl.
#
# Usage:  sudo ./scripts/install-k3s.sh
#
set -euo pipefail

# --- Configuration -----------------------------------------------------------
# Pin the k3s version for reproducible installs. Bump deliberately.
K3S_VERSION="${K3S_VERSION:-v1.34.5+k3s1}"

# kubeconfig mode 644 lets the invoking user read it without sudo.
K3S_KUBECONFIG_MODE="${K3S_KUBECONFIG_MODE:-644}"

# Extra server flags. Traefik (ingress) and metrics-server stay enabled.
INSTALL_FLAGS=(
  "--write-kubeconfig-mode=${K3S_KUBECONFIG_MODE}"
)

# --- Guards ------------------------------------------------------------------
if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: run as root (sudo $0)" >&2
  exit 1
fi

echo ">> Installing k3s ${K3S_VERSION} ..."
curl -sfL https://get.k3s.io \
  | INSTALL_K3S_VERSION="${K3S_VERSION}" \
    INSTALL_K3S_EXEC="server ${INSTALL_FLAGS[*]}" \
    sh -

echo ">> Waiting for node to become Ready ..."
for _ in $(seq 1 60); do
  if k3s kubectl get nodes 2>/dev/null | grep -q " Ready "; then
    break
  fi
  sleep 2
done

k3s kubectl get nodes -o wide

# Make kubeconfig available to the invoking (sudo) user.
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
if [[ -n "${TARGET_HOME}" ]]; then
  install -d -o "${TARGET_USER}" -m 700 "${TARGET_HOME}/.kube"
  install -o "${TARGET_USER}" -m 600 /etc/rancher/k3s/k3s.yaml "${TARGET_HOME}/.kube/config"
  echo ">> kubeconfig copied to ${TARGET_HOME}/.kube/config (owner ${TARGET_USER})"
fi

echo ">> Done. Verify with:  kubectl get nodes"
