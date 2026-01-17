#!/bin/bash
set -e

echo "Deploying MetalLB..."

# Install MetalLB using the official manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

echo "Waiting for MetalLB controller to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb,component=controller \
  --timeout=90s

echo "Waiting for MetalLB speaker to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb,component=speaker \
  --timeout=90s

echo "Applying MetalLB configuration..."
kubectl apply -f k8s/excludel2.yaml
kubectl apply -f k8s/ipaddresspool.yaml
kubectl apply -f k8s/l2advertisement.yaml

echo "MetalLB deployment complete!"
echo ""
echo "LoadBalancer IP pools configured:"
echo "  IPv4: 172.16.3.1-172.16.3.254 (254 addresses)"
echo "  IPv6: 2a02:a457:f2c0:0:1::/80 (281 trillion addresses)"
