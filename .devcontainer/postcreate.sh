#!/usr/bin/env bash

set -euo pipefail

# Install Podman if not already installed
echo "Installing Podman..."
if ! command -v podman &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y podman
fi

# Configure Podman to use the host's Podman socket
export CONTAINER_HOST="unix:///run/podman/podman.sock"
if ! grep -q "CONTAINER_HOST" ~/.bashrc 2>/dev/null; then
    echo 'export CONTAINER_HOST="unix:///run/podman/podman.sock"' >> ~/.bashrc
fi

# Install Kind (Kubernetes in Docker)
echo "Installing Kind..."
if ! command -v kind &> /dev/null; then
    curl -sSfLo /tmp/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x /tmp/kind
    sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
fi

# Check if cluster already exists
CLUSTER_EXISTS=false
if KIND_EXPERIMENTAL_PROVIDER=podman kind get clusters 2>/dev/null | grep -q "dev-cluster"; then
    echo "✅ Kind cluster 'dev-cluster' already exists"
    CLUSTER_EXISTS=true
fi

# Create cluster if it doesn't exist
if [ "$CLUSTER_EXISTS" = false ]; then
    echo "Creating Kind cluster with Podman..."
    KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name dev-cluster --wait 5m
    echo "✅ Kind cluster created successfully"
fi

# Fix kubeconfig permissions
sudo chown -R vscode:vscode ~/.kube 2>/dev/null || true

# Update kubeconfig with the correct cluster IP (after rebuild on kind network)
if [ -f ~/.kube/config ]; then
    CONTAINER_IP=$(podman inspect dev-cluster-control-plane --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        sed -i "s|https://[0-9.]*:[0-9]*|https://${CONTAINER_IP}:6443|g" ~/.kube/config
        echo "✅ Updated kubeconfig to use cluster IP: $CONTAINER_IP"
    fi
fi

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Kind cluster is running and kubectl is configured."
echo "Test with: kubectl cluster-info"
echo ""
echo "To deploy the DNS stack:"
echo "  cd dns"
echo "  ./deploy.sh"
echo ""

