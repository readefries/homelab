# Prometheus Monitoring Stack

Self-hosted monitoring with Prometheus, Alertmanager, and kube-state-metrics.

## Components

- **Prometheus** - Metrics collection and storage (30 day retention)
- **Alertmanager** - Alert routing and notifications to Gotify
- **kube-state-metrics** - Kubernetes object metrics

## Deployment

```bash
./deploy.sh
```

## Access

- Prometheus: https://prometheus.xs4some.nl
- Alertmanager: https://alertmanager.xs4some.nl

## Configure Gotify Integration

1. Open Gotify: https://gotify.xs4some.nl
2. Create a new Application called "Prometheus Alerts"
3. Copy the app token
4. Update `k8s/alertmanager-config.yaml`:
   ```yaml
   url: 'http://gotify.gotify.svc.cluster.local:80/message?token=YOUR_TOKEN_HERE'
   ```
5. Re-apply and restart:
   ```bash
   kubectl apply -f k8s/alertmanager-config.yaml
   kubectl rollout restart deployment/alertmanager -n monitoring
   ```

## Alerts Configured

| Alert | Severity | Description |
|-------|----------|-------------|
| PodNotReady | warning | Pod not ready for 5+ minutes |
| PodRestartingFrequently | warning | Pod restarted 5+ times in 1 hour |
| DeploymentReplicasMismatch | warning | Deployment replicas don't match |
| ContainerWaiting | warning | Container stuck (CrashLoopBackOff, etc.) |
| NodeNotReady | critical | K8s node not ready |
| ServiceDown | critical | Service has no endpoints |
| PVCPending | warning | PVC pending for 5+ minutes |
| CertificateExpiringSoon | warning | TLS cert expires in < 7 days |
| DNSPodNotReady | critical | DNS pod not ready for 2+ minutes |

## Scrape Targets

Prometheus automatically discovers:
- Kubernetes API server
- Kubernetes nodes (kubelet)
- Pods with `prometheus.io/scrape: "true"` annotation
- Kube-state-metrics
- Traefik (at traefik.traefik.svc.cluster.local:9100)

## Adding Custom Scrape Targets

Add annotation to your pods:
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```
