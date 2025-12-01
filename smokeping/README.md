# Smokeping

Network latency monitoring and graphing tool using ICMP pings.

## Components

- **Namespace**: `smokeping`
- **Storage**: 2Gi PersistentVolumeClaim for RRD data
- **Domain**: `smokeping.xs4some.nl`
- **Image**: `linuxserver/smokeping:latest`
- **Ingress**: Traefik with automatic TLS via Let's Encrypt

## Monitored Targets

### DNS Servers
- Google (8.8.8.8)
- Cloudflare (1.1.1.1)
- Quad9 (9.9.9.9)
- OpenDNS (208.67.222.222)

### HTTP Services
- Github
- Discord
- Google
- Cloudflare
- Amazon
- Netflix

## Deployment

```bash
# Create namespace and storage
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/namespace.yaml"
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/pvc.yaml"

# Create configuration
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/configmap.yaml"

# Deploy Smokeping
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/deployment.yaml"

# Create ingress
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/ingress.yaml"
```

Or use the deploy script:
```bash
./deploy.sh
```

## Configuration

Target configuration is stored in a ConfigMap (`smokeping-targets`). To modify targets:

1. Edit `k8s/configmap.yaml`
2. Apply changes: `kubectl apply -f k8s/configmap.yaml`
3. Restart pod: `kubectl -n smokeping rollout restart deployment/smokeping`

## Access

The service is available at: **https://smokeping.xs4some.nl**

## Monitoring

```bash
# Check status
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get pods,svc -n smokeping"

# View logs
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl logs -n smokeping -l app=smokeping -f"

# Exec into pod
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl exec -it -n smokeping deployment/smokeping -- bash"
```

## Migration from LXC 104

This deployment replaces LXC container 104 with the same monitoring targets. Historical RRD data can be migrated if needed:

```bash
# Copy data from LXC to local
scp -r root@proxmox:/var/lib/lxc/104/rootfs/var/lib/smokeping/ /tmp/smokeping-data/

# Copy to K8s PVC (requires helper pod)
# See backup/restore procedures for PVC data migration
```

## Backup

To backup smokeping data:

```bash
# Add to backup system (similar to vaultwarden/gotify)
# Create cronjob using backup/k8s/backup-cronjob-template.yaml
```

## Security Notes

- Container requires `NET_RAW` capability for ICMP ping
- Runs as UID/GID 1000 (linuxserver.io default)
- Data persistence via PVC
