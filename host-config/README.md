# Proxmox Host Configuration

This directory contains Ansible playbooks and configuration for setting up the Proxmox host and Kubernetes infrastructure.

## Prerequisites

- Proxmox host with IPv6 connectivity
- Ansible installed on the control machine
- SSH access to the Proxmox host

## Kubernetes Installation with Dual-Stack Support

The k3s installation is configured for dual-stack networking (IPv4 + IPv6):

### Important IPv6 Requirements

1. **IPv6 must be configured at install time** - The `--cluster-cidr` and `--service-cidr` cannot be changed after k3s is installed without completely reinstalling
2. **IPv6 forwarding must be enabled** on the host before installation
3. **MetalLB IPv6 pool must be in the same /64 subnet** as the node's network interface for Layer2 mode

### Network Configuration

- **Pod CIDR**: 
  - IPv4: `10.42.0.0/16`
  - IPv6: `fd00:10:42::/56`
- **Service CIDR**:
  - IPv4: `10.43.0.0/16`
  - IPv6: `fd00:10:43::/112`
- **LoadBalancer Pool**:
  - IPv4: `172.16.3.1-172.16.3.254` (254 addresses)
  - IPv6: `2a02:a457:f2c0:0:1::/80` (281 trillion addresses)

## Installation

### Full Infrastructure Deployment

To deploy everything from scratch (k3s + all workloads):

```bash
cd host-config/ansible
ansible-playbook -i inventory deploy-all.yaml
```

### Incremental Deployment

Deploy only infrastructure (k3s, MetalLB, cert-manager):

```bash
ansible-playbook -i inventory k8s-infra.yaml
```

Deploy only workloads (assumes infrastructure is already running):

```bash
ansible-playbook -i inventory deploy-workloads.yaml
```

Deploy individual components:

```bash
# Just k3s
ansible-playbook -i inventory k3s-install.yaml

# Individual workloads
ansible-playbook -i inventory -t traefik deploy-workloads.yaml
```

## Deployed Workloads

All workloads are configured with dual-stack LoadBalancer services:

- **Traefik** - Ingress controller (HTTP/HTTPS)
- **Vaultwarden** - Password manager
- **Gotify** - Notification server
- **DNS** - CoreDNS (standard and kids profiles)
- **MQTT** - Mosquitto broker
- **Monitoring** - Prometheus + Alertmanager

### IP Addressing Strategy

- **DNS services**: Use fixed IPv4/IPv6 addresses (configured via host_vars) so you can reference them in DHCP and upstream resolvers.
- **Application services** (Traefik, Vaultwarden, Gotify, MQTT): Use dynamic MetalLB IP assignment; clients reach them via DNS names and Ingress.

### Application IPv6 Configuration

For applications to work with dual-stack, they must listen on `::` (all interfaces, IPv4+IPv6) instead of `0.0.0.0` (IPv4 only):

- **Vaultwarden**: Uses `ROCKET_ADDRESS=::` environment variable
- **Most containers**: Default to listening on all interfaces

## DNS IPv6 Forwarding

The Proxmox host forwards IPv6 DNS queries to the Kubernetes DNS LoadBalancer service.

### Services

- **dns-forward-ipv6-udp.service**: Forwards UDP DNS queries (port 53)
- **dns-forward-ipv6-tcp.service**: Forwards TCP DNS queries (port 53)

### Installation

```bash
# Copy service files to Proxmox
scp host-config/dns-forward-ipv6-*.service root@proxmox:/etc/systemd/system/

# Enable and start services
ssh root@proxmox "systemctl daemon-reload && \
  systemctl enable dns-forward-ipv6-udp.service dns-forward-ipv6-tcp.service && \
  systemctl restart dns-forward-ipv6-udp.service dns-forward-ipv6-tcp.service"

# Check status
ssh root@proxmox "systemctl status dns-forward-ipv6-udp.service dns-forward-ipv6-tcp.service"
```

### Configuration Details

- **Bind address**: `2a02:a457:f2c0::8` (Proxmox host's IPv6 address)
- **Target**: `172.16.3.2:53` (Kubernetes DNS LoadBalancer service IP)
- **max-children=50**: Limits concurrent child processes to prevent zombie accumulation
- **KillMode=mixed**: Ensures proper cleanup of parent and child processes
- **TimeoutStopSec=10**: Allows 10 seconds for graceful shutdown

### Troubleshooting

Check for zombie processes:
```bash
ssh root@proxmox "ps aux | grep socat | wc -l"
```

Should show only 2-3 processes (1 parent per service + occasional children during active queries).

Check for reaping issues:
```bash
ssh root@proxmox "journalctl -u dns-forward-ipv6-udp.service --since '1 hour ago' | grep waitpid"
```

Should show no "waitpid" warnings if child reaping is working properly.

### Why This is Needed

Kubernetes services don't natively support IPv6, so socat forwards IPv6 DNS requests from external clients to the IPv4 LoadBalancer service inside the cluster.

### Known Issues & Fixes (2024-12-10)

**Problem**: Socat's `fork` mode with UDP creates child processes for each query. With high query volumes, the parent process's `waitpid()` mechanism couldn't keep up, leading to zombie process accumulation (300+ zombies over 7 days).

**Symptoms**: 
- "address already in use" DNS errors
- Container image pulls failing with ImagePullBackOff
- `waitpid(-1, {}, WNOHANG): no child has exited` warnings in journalctl

**Solution**: Added `max-children=50` parameter to limit concurrent children, preventing runaway accumulation while still handling burst traffic.
