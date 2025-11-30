#!/usr/bin/env bash
# deploy.sh - helper to copy values.yaml to the Proxmox host and run helm upgrade
# Usage: ./deploy.sh [--host root@proxmox] [--remote-dir /root/plex] [--chart /root/plex/release/plex-media-server]

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VALUES_SRC="$HERE/../helm/values.yaml"

# Defaults
REMOTE_HOST=${REMOTE_HOST:-root@proxmox}
REMOTE_DIR=${REMOTE_DIR:-/root/plex}
REMOTE_CHART=${REMOTE_CHART:-/root/plex/release/plex-media-server}
RELEASE_NAME=${RELEASE_NAME:-plex}
NAMESPACE=${NAMESPACE:-plex}

function usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --host user@host      Remote host to copy values to (default: ${REMOTE_HOST})
  --remote-dir /path    Remote directory to copy values into (default: ${REMOTE_DIR})
  --chart /path         Remote chart directory to install from (default: ${REMOTE_CHART})
  --release name        Helm release name (default: ${RELEASE_NAME})
  --namespace ns        Kubernetes namespace (default: ${NAMESPACE})
  --help                Show this help

Environment variables accepted:
  REMOTE_HOST, REMOTE_DIR, REMOTE_CHART, RELEASE_NAME, NAMESPACE

Example:
  REMOTE_HOST=root@proxmox REMOTE_DIR=/root/plex ./deploy.sh
EOF
}

while [[ ${#} -gt 0 ]]; do
  case "${1}" in
    --host) REMOTE_HOST="$2"; shift 2;;
    --remote-dir) REMOTE_DIR="$2"; shift 2;;
    --chart) REMOTE_CHART="$2"; shift 2;;
    --release) RELEASE_NAME="$2"; shift 2;;
    --namespace) NAMESPACE="$2"; shift 2;;
    --help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

if [ ! -f "$VALUES_SRC" ]; then
  echo "values.yaml not found at $VALUES_SRC" >&2
  exit 1
fi

echo "Copying $VALUES_SRC to ${REMOTE_HOST}:${REMOTE_DIR}/values.yaml"
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${REMOTE_HOST}" "mkdir -p '${REMOTE_DIR}'"
scp "$VALUES_SRC" "${REMOTE_HOST}:${REMOTE_DIR}/values.yaml"

echo "Running helm upgrade --install ${RELEASE_NAME} ${REMOTE_CHART} -n ${NAMESPACE} -f ${REMOTE_DIR}/values.yaml"
ssh -t "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml; helm upgrade --install ${RELEASE_NAME} ${REMOTE_CHART} -n ${NAMESPACE} --create-namespace -f ${REMOTE_DIR}/values.yaml"

echo "Deployment initiated. Monitor with: kubectl -n ${NAMESPACE} get pods -o wide"
