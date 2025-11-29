# Traefik Ingress Controller

Traefik provides automatic SSL/TLS certificates via Let's Encrypt and routes HTTP/HTTPS traffic to your services.

## Features

- **Automatic SSL**: Let's Encrypt certificates with automatic renewal
- **HTTP to HTTPS redirect**: All HTTP traffic automatically redirected to HTTPS
- **Dashboard**: Web UI to monitor routes and services
- **NodePort**: Exposed on ports 30080 (HTTP) and 30443 (HTTPS)

## Configuration

Before deploying, update these files:

1. **config.yaml**: Change `your-email@example.com` to your email for Let's Encrypt
2. **dashboard-ingress.yaml**: Change `traefik.yourdomain.com` to your actual domain

## Deployment

```bash
# Deploy Traefik
kubectl apply -f namespace.yaml
kubectl apply -f rbac.yaml
kubectl apply -f config.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingressclass.yaml

# Optional: Expose dashboard (requires domain)
kubectl apply -f dashboard-ingress.yaml
```

## Verify Installation

```bash
# Check if Traefik is running
kubectl get pods -n traefik

# Check services
kubectl get svc -n traefik

# View logs
kubectl logs -n traefik -l app=traefik
```

## Access

- **HTTP**: http://YOUR_SERVER_IP:30080
- **HTTPS**: https://YOUR_SERVER_IP:30443
- **Dashboard**: https://traefik.yourdomain.com (after configuring ingress)

## Exposing Services

Traefik can route to any service - Kubernetes pods, external VMs, or other hosts.

### Directory Structure

```
traefik/
├── k8s/              # Core Traefik installation
└── hosts/            # Individual service configurations
    ├── example.yaml  # Template for new services
    └── README.md     # Examples and documentation
```

### Adding a New Service

1. Create a new YAML file in `hosts/` directory
2. Define Service + Endpoints (for VMs) or just Ingress (for K8s services)
3. Apply: `kubectl apply -f hosts/your-service.yaml`

Traefik will automatically:
1. Detect the new Ingress
2. Obtain a Let's Encrypt SSL certificate
3. Route traffic to your service
4. Redirect HTTP to HTTPS

See `hosts/README.md` for examples of routing to VMs, containers, and external services.

## Port Forwarding

If you want to access from your router:
- Forward port 80 → YOUR_SERVER_IP:30080
- Forward port 443 → YOUR_SERVER_IP:30443

## Let's Encrypt Rate Limits

For testing, use the staging server (uncomment in config.yaml):
```yaml
caServer: https://acme-staging-v02.api.letsencrypt.org/directory
```

Production rate limits:
- 50 certificates per domain per week
- 5 duplicate certificates per week
