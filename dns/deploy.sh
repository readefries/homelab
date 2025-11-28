#!/bin/bash

set -e

echo "🚀 Deploying DNS System (Pi-hole + Unbound + DoH)"
echo "=================================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check cluster connectivity
echo "📡 Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✅ Connected to cluster"
echo ""

# Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Deploy Unbound (recursive DNS)
echo "🌐 Deploying Unbound recursive DNS server..."
kubectl apply -f k8s/unbound-config.yaml
kubectl apply -f k8s/unbound.yaml

# Wait for Unbound to be ready
echo "⏳ Waiting for Unbound to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/unbound -n dns-system

# Deploy Pi-hole
echo "🛡️  Deploying Pi-hole ad-blocker..."
kubectl apply -f k8s/pihole.yaml

# Wait for Pi-hole to be ready
echo "⏳ Waiting for Pi-hole to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment/pihole -n dns-system

# Deploy DoH server
echo "🔐 Deploying DNS over HTTPS (DoH) server..."
kubectl apply -f k8s/doh-server.yaml

# Wait for DoH server to be ready
echo "⏳ Waiting for DoH server to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/doh-server -n dns-system

# Deploy Ingress
echo "🌍 Deploying DoH Ingress..."
kubectl apply -f k8s/doh-ingress.yaml

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Getting service status..."
kubectl get all -n dns-system

echo ""
echo "=================================================="
echo "🎉 DNS System is deployed!"
echo ""
echo "Access Information:"
echo "-------------------"

# Get Pi-hole web interface details
PIHOLE_SERVICE=$(kubectl get svc pihole-dns -n dns-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
if [ "$PIHOLE_SERVICE" == "pending" ] || [ -z "$PIHOLE_SERVICE" ]; then
    echo "Pi-hole Web UI: http://localhost:8080 (use port-forward)"
    echo "  Run: kubectl port-forward -n dns-system svc/pihole-web 8080:80"
else
    echo "Pi-hole Web UI: http://$PIHOLE_SERVICE"
fi

echo "Pi-hole Admin Password: admin (change this!)"
echo ""

# Get DoH endpoint
echo "DoH Endpoint: https://doh.local.example.com/dns-query"
echo "  Or via NodePort: https://localhost:30053/dns-query"
echo "  Run: kubectl port-forward -n dns-system svc/doh-server-nodeport 30053:443"
echo ""

echo "DNS Server (for local network):"
if [ "$PIHOLE_SERVICE" == "pending" ] || [ -z "$PIHOLE_SERVICE" ]; then
    echo "  Port-forward: kubectl port-forward -n dns-system svc/pihole-dns 5353:53"
    echo "  Then use: 127.0.0.1:5353"
else
    echo "  IP: $PIHOLE_SERVICE:53"
fi

echo ""
echo "Configuration Details:"
echo "----------------------"
echo "• Unbound: Queries DNS root servers directly"
echo "• Pi-hole: Uses Unbound as upstream, blocks ads/trackers"
echo "• DoH Server: Provides encrypted DNS queries to Pi-hole"
echo ""
echo "Test DoH with curl:"
echo "  curl -H 'accept: application/dns-json' 'http://localhost:30053/dns-query?name=example.com&type=A'"
echo ""
