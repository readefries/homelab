#!/bin/bash

# This script sets up port forwarding to the Kind cluster
# Run this after the dev container starts if kubectl can't connect

export CONTAINER_HOST="unix:///run/podman/podman.sock"

# Get the Kind container IP
CONTAINER_IP=$(podman inspect dev-cluster-control-plane --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)

if [ -z "$CONTAINER_IP" ]; then
    echo "❌ Kind cluster not found. Please run the postcreate script first."
    exit 1
fi

echo "Kind cluster IP: $CONTAINER_IP"

# Kill existing socat processes
sudo pkill -f "socat.*6443" 2>/dev/null || true

# Start port forwarding
echo "Setting up port forward: 127.0.0.1:6443 -> $CONTAINER_IP:6443"
sudo socat TCP-LISTEN:6443,fork,reuseaddr TCP:${CONTAINER_IP}:6443 &

sleep 2

# Update kubeconfig
if [ -f ~/.kube/config ]; then
    sed -i "s|https://[0-9.]*:[0-9]*|https://127.0.0.1:6443|g" ~/.kube/config
    echo "✅ Updated kubeconfig"
fi

echo "✅ Port forwarding active"
echo "Test with: kubectl cluster-info"
