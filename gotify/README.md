# Gotify

Simple notification server for sending push notifications.

## Components

- **Namespace**: `gotify`
- **Storage**: 1Gi PersistentVolumeClaim for data persistence
- **Domain**: `gotify.xs4some.nl`
- **Image**: `gotify/server:latest`
- **Ingress**: Traefik with automatic TLS via Let's Encrypt

## Deployment

```bash
# Create namespace and storage
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/namespace.yaml"
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/pvc.yaml"

# Deploy Gotify
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/deployment.yaml"

# Create ingress
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f k8s/ingress.yaml"
```

Or use the deploy script:
```bash
./deploy.sh
```

## Configuration

Default credentials (change after first login):
- Username: `admin`
- Password: `admin`

### Access

The service is available at: **https://gotify.xs4some.nl**

## Setting Up Backup Notifications

1. Log in to Gotify web UI
2. Click "Apps" → "Create Application"
3. Name it "Backup Alerts" and save
4. Copy the application token
5. Create a Kubernetes secret:

```bash
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl -n vaultwarden create secret generic gotify-backup-alert \
  --from-literal=webhook-url=https://gotify.xs4some.nl/message \
  --from-literal=token=YOUR_APP_TOKEN_HERE"
```

6. Update your backup CronJob to include the alert env vars:

```yaml
env:
- name: ALERT_WEBHOOK
  valueFrom:
    secretKeyRef:
      name: gotify-backup-alert
      key: webhook-url
- name: ALERT_TOKEN
  valueFrom:
    secretKeyRef:
      name: gotify-backup-alert
      key: token
```

## Monitoring

```bash
# Check status
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get pods,svc -n gotify"

# View logs
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl logs -n gotify -l app=gotify -f"

# Exec into pod
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl exec -it -n gotify deployment/gotify -- sh"
```

## API Usage

Send a test notification:
```bash
curl -X POST "https://gotify.xs4some.nl/message?token=YOUR_APP_TOKEN" \
  -F "title=Test" \
  -F "message=This is a test notification" \
  -F "priority=5"
```

For the backup-runner integration, it sends JSON payloads like:
```json
{
  "service": "backup-runner",
  "message": "Backup failed: reason here",
  "target": "/backups/vaultwarden/",
  "timestamp": 1234567890
}
```

You'll need to adapt this to Gotify's format. See below for the backup-runner update.

## Mobile Apps

- **Android**: [Gotify Android](https://github.com/gotify/android)
- **iOS**: Use ntfy or other compatible apps (Gotify doesn't have official iOS app)

## Backup

Gotify data is stored in the PVC. To backup:
```bash
kubectl -n gotify exec deployment/gotify -- tar czf - /app/data
```

Or add to the backup system with a new CronJob.
