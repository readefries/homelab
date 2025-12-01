#!/usr/bin/env bash
# Cleanup restore-to-copy resources
# Usage: ./cleanup-restore-copy.sh <namespace> <timestamp>

set -euo pipefail

NAMESPACE=${1:-vaultwarden}
TIMESTAMP=${2:-}

# If first arg looks like a timestamp (YYYYMMDD-HHMMSS), treat it as timestamp with default namespace
if [[ "$NAMESPACE" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
  TIMESTAMP="$NAMESPACE"
  NAMESPACE="vaultwarden"
fi

if [ -z "$TIMESTAMP" ]; then
  echo "Usage: $0 [namespace] <timestamp>"
  echo ""
  echo "Examples:"
  echo "  $0 20251201-150630                    # Uses vaultwarden namespace"
  echo "  $0 vaultwarden 20251201-150630        # Explicit namespace"
  echo ""
  echo "Without timestamp, lists all restore-copy resources:"
  echo "  $0 vaultwarden"
  exit 1
fi

SERVICE_NAME=$(echo "$NAMESPACE" | cut -d'-' -f1)

if [ -z "$TIMESTAMP" ]; then
  echo "=== Restore Copy Resources in ${NAMESPACE} ==="
  echo ""
  
  echo "Deployments:"
  kubectl -n "$NAMESPACE" get deployments -l app.kubernetes.io/name=restore-verify 2>/dev/null || echo "  (none)"
  echo ""
  
  echo "Jobs:"
  kubectl -n "$NAMESPACE" get jobs -l app.kubernetes.io/name=restore-copy 2>/dev/null || echo "  (none)"
  echo ""
  
  echo "PVCs:"
  kubectl -n "$NAMESPACE" get pvc -l app.kubernetes.io/name=restore-copy 2>/dev/null || echo "  (none)"
  echo ""
  
  echo "To delete specific resources, provide timestamp:"
  echo "  $0 ${NAMESPACE} TIMESTAMP"
  echo ""
  echo "To delete ALL restore-copy resources:"
  read -p "Delete all restore-copy resources? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting all restore-copy resources..."
    kubectl -n "$NAMESPACE" delete deployments -l app.kubernetes.io/name=restore-verify 2>/dev/null || true
    kubectl -n "$NAMESPACE" delete jobs -l app.kubernetes.io/name=restore-copy 2>/dev/null || true
    kubectl -n "$NAMESPACE" delete pvc -l app.kubernetes.io/name=restore-copy 2>/dev/null || true
    echo "✓ Cleanup complete"
  else
    echo "Cancelled"
  fi
  exit 0
fi

# Delete specific resources by timestamp
RESTORE_PVC="${SERVICE_NAME}-data-restore-${TIMESTAMP}"
RESTORE_JOB="${SERVICE_NAME}-restore-job-${TIMESTAMP}"
VERIFY_DEPLOY="${SERVICE_NAME}-restore-verify-${TIMESTAMP}"
WEB_DEPLOY="${SERVICE_NAME}-restore-web-${TIMESTAMP}"
WEB_SERVICE="${SERVICE_NAME}-restore-web-${TIMESTAMP}"
WEB_INGRESS="${SERVICE_NAME}-restore-web-${TIMESTAMP}"

echo "=== Cleaning up restore-copy resources ==="
echo "Namespace: ${NAMESPACE}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

echo "Resources to delete:"
echo "  • Deployment: ${VERIFY_DEPLOY}"
echo "  • Deployment: ${WEB_DEPLOY}"
echo "  • Service: ${WEB_SERVICE}"
echo "  • Ingress: ${WEB_INGRESS}"
echo "  • Job: ${RESTORE_JOB}"
echo "  • PVC: ${RESTORE_PVC}"
echo ""

read -p "Proceed with deletion? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "Deleting verify deployment..."
kubectl -n "$NAMESPACE" delete deployment "${VERIFY_DEPLOY}" 2>/dev/null && echo "✓ Deleted verify deployment" || echo "⚠ Verify deployment not found"

echo "Deleting web deployment..."
kubectl -n "$NAMESPACE" delete deployment "${WEB_DEPLOY}" 2>/dev/null && echo "✓ Deleted web deployment" || echo "⚠ Web deployment not found"

echo "Deleting web service..."
kubectl -n "$NAMESPACE" delete service "${WEB_SERVICE}" 2>/dev/null && echo "✓ Deleted web service" || echo "⚠ Web service not found"

echo "Deleting web ingress..."
kubectl -n "$NAMESPACE" delete ingress "${WEB_INGRESS}" 2>/dev/null && echo "✓ Deleted web ingress" || echo "⚠ Web ingress not found"

echo "Deleting job..."
kubectl -n "$NAMESPACE" delete job "${RESTORE_JOB}" 2>/dev/null && echo "✓ Deleted job" || echo "⚠ Job not found"

echo "Deleting PVC..."
kubectl -n "$NAMESPACE" delete pvc "${RESTORE_PVC}" 2>/dev/null && echo "✓ Deleted PVC" || echo "⚠ PVC not found"

echo ""
echo "✓ Cleanup complete"
