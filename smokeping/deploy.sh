#!/usr/bin/env bash
# Deploy Smokeping to k3s cluster on proxmox

set -euo pipefail

REMOTE_HOST=${REMOTE_HOST:-root@proxmox}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📊 Deploying Smokeping to ${REMOTE_HOST}"
echo "=========================================="

# Copy k8s manifests to proxmox
echo "📦 Copying manifests to ${REMOTE_HOST}..."
ssh "${REMOTE_HOST}" "mkdir -p /tmp/smokeping-deploy"
scp -r "${SCRIPT_DIR}/k8s/"* "${REMOTE_HOST}:/tmp/smokeping-deploy/"

# Apply manifests
echo "🚀 Applying manifests..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/smokeping-deploy/namespace.yaml && \
  kubectl apply -f /tmp/smokeping-deploy/pvc.yaml && \
  kubectl apply -f /tmp/smokeping-deploy/configmap.yaml && \
  kubectl apply -f /tmp/smokeping-deploy/deployment.yaml && \
  kubectl apply -f /tmp/smokeping-deploy/ingress.yaml"

# Wait for deployment
echo "⏳ Waiting for Smokeping to be ready..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl wait --for=condition=available --timeout=180s deployment/smokeping -n smokeping"

# Get status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get all -n smokeping"

echo ""
echo "🌐 Access Smokeping at: https://smokeping.xs4some.nl"
echo ""
echo "📝 Next steps:"
echo "  1. Verify graphs are generating (may take a few minutes)"
echo "  2. Add backup CronJob if desired"
echo "  3. Stop LXC 104: pct stop 104"
echo "  4. After confirming K8s works, remove LXC: pct destroy 104"

# Cleanup
ssh "${REMOTE_HOST}" "rm -rf /tmp/smokeping-deploy"
