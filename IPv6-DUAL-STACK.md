# IPv6 Dual-Stack Configuration Summary

This document summarizes all the changes made to enable IPv6 dual-stack support across the homelab.

## Key Configuration Changes

### 1. Kubernetes Cluster
- **k3s installation** with dual-stack CIDRs:
  - Pod CIDR: `10.42.0.0/16,fd00:10:42::/56`
  - Service CIDR: `10.43.0.0/16,fd00:10:43::/112`
- **IPv6 forwarding** enabled on host: `net.ipv6.conf.all.forwarding = 1`

### 2. MetalLB LoadBalancer
- **IPv4 Pool**: `172.16.3.1-172.16.3.254` (254 addresses)
- **IPv6 Pool**: `2a02:a457:f2c0:0:1::/80` (281 trillion addresses)
- **Critical requirement**: IPv6 pool must be in same /64 subnet as node's interface for Layer2 NDP to work

### 3. Service Configuration
All LoadBalancer services now include:
```yaml
spec:
  type: LoadBalancer
  ipFamilyPolicy: PreferDualStack
  ipFamilies:
  - IPv4
  - IPv6
```

**Note**: Removed `loadBalancerIP` field as it conflicts with dual-stack configuration.

## Updated Workloads

### Services with LoadBalancer + IPv6

1. **Traefik** (`traefik/k8s/service.yaml`)
   - HTTP (80) and HTTPS (443)
   - Already configured correctly

2. **Vaultwarden** (`vaultwarden/k8s/service.yaml`)
   - HTTP (80)
   - Application configured to listen on `::` via `ROCKET_ADDRESS=::`

3. **Gotify** (`gotify/k8s/deployment.yaml`)
   - HTTP (80)
   - Service updated to LoadBalancer with dual-stack

4. **DNS** (`dns/k8s/dns-loadbalancer.yaml`)
   - 4 LoadBalancer services for CoreDNS (standard + kids, each with 2 IPs)
   - UDP and TCP on port 53

5. **MQTT** (`mqtt/k8s/service-lb.yaml`)
   - TCP port 1883
   - Updated with dual-stack

### Application-Level IPv6 Support

For applications to accept IPv6 connections, they must bind to `::` instead of `0.0.0.0`:

- **Vaultwarden**: Set via environment variables:
  - `ROCKET_ADDRESS: "::"`
  - `WEBSOCKET_ADDRESS: "::"`
- **Most other apps**: Default configurations already bind to all interfaces

## Ansible Automation

### New Ansible Roles Created

All located in `host-config/ansible/roles/`:

1. **k3s-install** - Updated to enable IPv6 forwarding and install k3s with dual-stack
2. **metallb** - Updated to deploy with new IPv6-aware configuration
3. **traefik** - Deploy Traefik ingress controller
4. **vaultwarden** - Deploy Vaultwarden password manager
5. **gotify** - Deploy Gotify notification server
6. **dns** - Deploy CoreDNS services
7. **mqtt** - Deploy Mosquitto MQTT broker
8. **monitoring** - Deploy Prometheus + Alertmanager

### Playbooks

- **deploy-all.yaml** - Complete infrastructure + all workloads
- **deploy-workloads.yaml** - Just workloads (assumes k8s infrastructure exists)
- **k8s-infra.yaml** - Just k8s infrastructure (k3s, MetalLB, cert-manager)

## Testing

Verify IPv6 connectivity:

```bash
# Test Traefik
curl -v http://[2a02:a457:f2c0:0:1::1]/

# Test Vaultwarden
curl -v http://[2a02:a457:f2c0:0:1::2]/

# Test DNS
dig @2a02:a457:f2c0:0:1::3 google.com

# Check service IPs
kubectl get svc -A -o wide | grep LoadBalancer
```

## Important Notes

### Why ping6 doesn't work
MetalLB Layer2 mode responds to ARP/NDP but doesn't respond to ICMP ping. This is expected behavior - the services are reachable on their TCP/UDP ports even though ping fails.

### Subnet Requirements
- IPv6 LoadBalancer IPs **must** be in the same /64 subnet as the node's network interface
- For example, if node has `2a02:a457:f2c0:0::ab/64`, LoadBalancer pool must use `2a02:a457:f2c0:0::/64` range
- Different /64 subnets (like `2a02:a457:f2c0:3::/64`) will not work with Layer2 mode

### Changing CIDRs
The cluster-cidr and service-cidr **cannot be changed** after k3s installation. To change them, you must:
1. Uninstall k3s completely: `/usr/local/bin/k3s-uninstall.sh`
2. Reinstall with new CIDRs

## Files Modified

### Configuration Files
- `metallb/k8s/ipaddresspool.yaml` - IPv6 pool updated to /80 range
- `traefik/k8s/service.yaml` - Already had dual-stack
- `vaultwarden/k8s/service.yaml` - Created with dual-stack
- `vaultwarden/k8s/deployment.yaml` - Added ROCKET_ADDRESS=::
- `gotify/k8s/deployment.yaml` - Service updated to LoadBalancer
- `dns/k8s/dns-loadbalancer.yaml` - Updated to dual-stack
- `mqtt/k8s/service-lb.yaml` - Updated to dual-stack

### Ansible
- `host-config/ansible/roles/k3s-install/tasks/main.yaml` - Added IPv6 forwarding and dual-stack CIDRs
- `host-config/ansible/roles/metallb/tasks/main.yaml` - Updated to use new config files
- Created 6 new workload deployment roles
- Created 2 new playbooks (deploy-all.yaml, deploy-workloads.yaml)

### Documentation
- `metallb/README.md` - Added IPv6 requirements and troubleshooting
- `host-config/README.md` - Added dual-stack configuration details
- `metallb/deploy.sh` - Updated output messages
