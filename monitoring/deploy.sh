#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/k8s"

echo "Deploying monitoring stack..."

# Apply in order
kubectl apply -f "$K8S_DIR/namespace.yaml"
kubectl apply -f "$K8S_DIR/prometheus-rbac.yaml"
kubectl apply -f "$K8S_DIR/prometheus-config.yaml"
kubectl apply -f "$K8S_DIR/prometheus-rules.yaml"
kubectl apply -f "$K8S_DIR/prometheus.yaml"
kubectl apply -f "$K8S_DIR/secret-gotify.yaml"
kubectl apply -f "$K8S_DIR/alertmanager-config.yaml"
kubectl apply -f "$K8S_DIR/alertmanager.yaml"
kubectl apply -f "$K8S_DIR/kube-state-metrics.yaml"
kubectl apply -f "$K8S_DIR/ingress.yaml"

echo ""
echo "Waiting for pods to be ready..."
kubectl rollout status deployment/prometheus -n monitoring --timeout=120s
kubectl rollout status deployment/alertmanager -n monitoring --timeout=60s
kubectl rollout status deployment/kube-state-metrics -n monitoring --timeout=60s

echo ""
echo "Monitoring stack deployed!"
echo ""
echo "Access:"
echo "  - Prometheus: https://prometheus.xs4some.nl"
echo "  - Alertmanager: https://alertmanager.xs4some.nl"
echo ""
echo "NOTE: Make sure to update the Gotify token in secret-gotify.yaml before deploying"
