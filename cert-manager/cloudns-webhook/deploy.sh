#!/usr/bin/env bash

# Deploy cert-manager ClouDNS webhook and DNS-01 issuers
set -e

WORKSPACE="/workspaces/homelab"
CLUSTER="${1:-floki}"

if [ "$CLUSTER" = "floki" ]; then
    KUBECTL="kubectl"
elif [ "$CLUSTER" = "proxmox" ]; then
    KUBECTL="ssh root@proxmox kubectl"
else
    echo "Usage: $0 [floki|proxmox]"
    exit 1
fi

echo "=== Deploying ClouDNS webhook to $CLUSTER ==="

# 1. Create cert-manager namespace if needed
echo "[1/4] Ensuring cert-manager namespace exists..."
$KUBECTL create namespace cert-manager --dry-run=client -o yaml | $KUBECTL apply -f -

# 2. Deploy secret and issuers from file
echo "[2/4] Creating ClouDNS API secret and issuers..."
$KUBECTL apply -f $WORKSPACE/cert-manager/cloudns-issuers.yaml

# 3. Deploy webhook
echo "[3/4] Deploying ClouDNS webhook..."
$KUBECTL apply -f $WORKSPACE/cert-manager/cloudns-webhook/cloudns-webhook.yaml

# Wait for webhook deployment
echo "  Waiting for webhook to be ready..."
$KUBECTL rollout status deployment/cloudns-webhook -n cert-manager --timeout=2m

echo
echo "=== Deployment complete ==="
echo
echo "Next steps:"
echo "1. Verify webhook is running: kubectl get pod -n cert-manager -l app=cloudns-webhook"
echo "2. Check issuer status: kubectl get clusterissuer"
echo "3. Update Ingress annotations to use: cert-manager.io/cluster-issuer: letsencrypt-dns01-cloudns-staging"
echo "4. Once staging certs work, switch to: cert-manager.io/cluster-issuer: letsencrypt-dns01-cloudns"
echo
echo "Note: The ClouDNS password is already in cloudns-issuers.yaml. Edit that file"
echo "before running this script if you need to change credentials."
