# Proxmox Host Configuration

This directory contains systemd service files and other configuration that needs to be installed directly on the Proxmox host (not in Kubernetes).

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
