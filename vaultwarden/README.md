# Vaultwarden

Vaultwarden (formerly Bitwarden_RS) is a lightweight, self-hosted password manager compatible with Bitwarden clients.

## Components

- **Namespace**: `vaultwarden`
- **Storage**: 5Gi PersistentVolumeClaim for data persistence
- **Domain**: `vaultwarden.xs4some.nl`
- **Image**: `vaultwarden/server:latest`
- **Ingress**: Traefik with automatic TLS via Let's Encrypt

## Deployment

```bash
# Create namespace and storage
ssh root@proxmox "kubectl apply -f k8s/namespace.yaml"
ssh root@proxmox "kubectl apply -f k8s/pvc.yaml"

# Deploy Vaultwarden
ssh root@proxmox "kubectl apply -f k8s/deployment.yaml"

# Create ingress
ssh root@proxmox "kubectl apply -f k8s/ingress.yaml"
```

## Configuration

Key environment variables in `deployment.yaml`:

- `DOMAIN`: Set to your public URL
- `SIGNUPS_ALLOWED`: Disabled by default (set to "false")
- `INVITATIONS_ALLOWED`: Enabled for admin invites
- `SHOW_PASSWORD_HINT`: Disabled for security

### Access

The service is available at: **https://vaultwarden.xs4some.nl**

## Monitoring

```bash
# Check status
ssh root@proxmox "kubectl get pods,svc -n vaultwarden"

# View logs
ssh root@proxmox "kubectl logs -n vaultwarden -l app=vaultwarden -f"

# Exec into pod
ssh root@proxmox "kubectl exec -it -n vaultwarden deployment/vaultwarden -- sh"
```

## Backup

Create backups of the PVC data:

```bash
# Create backup
ssh root@proxmox "kubectl run backup --image=alpine -n vaultwarden --rm -it --restart=Never --overrides='{\"spec\":{\"containers\":[{\"name\":\"backup\",\"image\":\"alpine\",\"command\":[\"tar\",\"czf\",\"-\",\"-C\",\"/data\",\".\"],\"volumeMounts\":[{\"name\":\"data\",\"mountPath\":\"/data\"}]}],\"volumes\":[{\"name\":\"data\",\"persistentVolumeClaim\":{\"claimName\":\"vaultwarden-data\"}}]}}' > vaultwarden-backup-\$(date +%Y%m%d).tar.gz"
```

## Data Location

Data is stored in the PersistentVolume mounted at `/data` and includes:
- `db.sqlite3` - Main database
- `rsa_key.pem` - Encryption key
- `icon_cache/` - Cached website icons
- `attachments/` - File attachments (if any)
