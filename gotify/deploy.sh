#!/usr/bin/env bash
# Deploy Gotify to k3s cluster on proxmox

set -euo pipefail

REMOTE_HOST=${REMOTE_HOST:-root@proxmox}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔔 Deploying Gotify to ${REMOTE_HOST}"
echo "======================================"

# Copy k8s manifests to proxmox
echo "📦 Copying manifests to ${REMOTE_HOST}..."
ssh "${REMOTE_HOST}" "mkdir -p /tmp/gotify-deploy"
scp -r "${SCRIPT_DIR}/k8s/"* "${REMOTE_HOST}:/tmp/gotify-deploy/"

# Apply manifests
echo "🚀 Applying manifests..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/gotify-deploy/namespace.yaml && \
  kubectl apply -f /tmp/gotify-deploy/pvc.yaml && \
  kubectl apply -f /tmp/gotify-deploy/deployment.yaml && \
  kubectl apply -f /tmp/gotify-deploy/ingress.yaml"

# Wait for deployment
echo "⏳ Waiting for Gotify to be ready..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl wait --for=condition=available --timeout=120s deployment/gotify -n gotify"

# Get status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get all -n gotify"

echo ""
echo "🌐 Access Gotify at: https://gotify.xs4some.nl"
echo "🔑 Default login: admin / admin"
echo ""
echo "⚠️  IMPORTANT: Change the default password after first login!"
echo ""
echo "📱 Next steps:"
echo "  1. Log in and change admin password"
echo "  2. Create an application for backup alerts"
echo "  3. Copy the application token"
echo "  4. Create secret: kubectl -n vaultwarden create secret generic gotify-backup-alert \\"
echo "       --from-literal=webhook-url=https://gotify.xs4some.nl/message \\"
echo "       --from-literal=token=YOUR_APP_TOKEN"

# Cleanup
ssh "${REMOTE_HOST}" "rm -rf /tmp/gotify-deploy"
