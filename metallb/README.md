# MetalLB Load Balancer

MetalLB provides LoadBalancer services for bare-metal Kubernetes clusters.

## Prerequisites

- Kubernetes cluster with dual-stack networking enabled
- k3s installed with both IPv4 and IPv6 service CIDRs:
  ```bash
  --cluster-cidr=10.42.0.0/16,fd00:10:42::/56 \
  --service-cidr=10.43.0.0/16,fd00:10:43::/112
  ```

## Deployment

```bash
./deploy.sh
```

Or manually:

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Wait for pods to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Apply configuration
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/excludel2.yaml
kubectl apply -f k8s/ipaddresspool.yaml
kubectl apply -f k8s/l2advertisement.yaml
```

## Configuration

### IP Address Pool

The `ipaddresspool.yaml` defines the IP ranges that MetalLB can allocate:
- **IPv4**: `172.16.3.1-172.16.3.254` (254 addresses from 172.16.3.0/24 subnet)
- **IPv6**: `2a02:a457:f2c0:0:1::/80` (2^48 addresses = 281 trillion addresses)

The IPv6 range uses a /80 within the node's /64 subnet, providing ample address space for LoadBalancer services.

**Important for IPv6**: The IPv6 addresses must be in the same `/64` subnet as your node's network interface for Layer2 mode to work. This is required for NDP (Neighbor Discovery Protocol) to function properly.

### Layer2 Mode

MetalLB is configured in Layer2 mode, which:
- Works on any Ethernet network
- Doesn't require BGP router support
- Uses ARP (IPv4) and NDP (IPv6) to announce service IPs
- One node becomes the leader for each service IP

### Excluded Interfaces

The `excludel2.yaml` ConfigMap excludes virtual interfaces from Layer2 announcements:
- Docker, containerd, and other container interfaces
- Kubernetes CNI interfaces (Calico, Flannel, etc.)
- Virtual bridges and tunnel interfaces

## Using LoadBalancer Services

To create a dual-stack LoadBalancer service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    metallb.universe.tf/address-pool: default-pool
spec:
  type: LoadBalancer
  ipFamilyPolicy: PreferDualStack
  ipFamilies:
  - IPv4
  - IPv6
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

## Troubleshooting

### Check MetalLB Status

```bash
# Check pods
kubectl get pods -n metallb-system

# Check logs
kubectl logs -n metallb-system -l component=speaker
kubectl logs -n metallb-system -l component=controller

# Check IP assignments
kubectl get svc -A | grep LoadBalancer
```

### IPv6 Not Working

1. Verify your node's IPv6 address and subnet:
   ```bash
   ip -6 addr show
   ```

2. Ensure the IPv6 pool is in the same `/64` subnet

3. Check IPv6 forwarding is enabled:
   ```bash
   sysctl net.ipv6.conf.all.forwarding
   ```

4. Verify the application listens on IPv6 (`::`), not just IPv4 (`0.0.0.0`)

### Services Not Getting IPs

1. Check IPAddressPool is applied:
   ```bash
   kubectl get ipaddresspool -n metallb-system
   ```

2. Check L2Advertisement:
   ```bash
   kubectl get l2advertisement -n metallb-system
   ```

3. Check controller logs for errors:
   ```bash
   kubectl logs -n metallb-system -l component=controller --tail=50
   ```
