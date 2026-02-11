#!/bin/bash
set -e

cd /workspaces/homelab/cert-manager/cloudns-webhook

# Render Helm chart using the override values
helm template cloudns-webhook ./chart \
  --namespace cert-manager \
  -f values-override.yaml \
  --create-namespace \
  > cloudns-webhook.yaml

echo "✓ Rendered cloudns-webhook.yaml"

# Show summary
echo
echo "--- Manifest Summary ---"
grep "^kind:" cloudns-webhook.yaml | sort | uniq -c
echo
echo "Manifests saved to: cloudns-webhook.yaml"
echo "To apply: kubectl apply -f cloudns-webhook.yaml"
