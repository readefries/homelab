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

## Example: Exposing a Service

Create an Ingress for your service:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  namespace: my-namespace
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: myapp.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
  tls:
  - hosts:
    - myapp.yourdomain.com
    secretName: myapp-tls
```

Traefik will automatically:
1. Obtain a Let's Encrypt SSL certificate
2. Route traffic to your service
3. Redirect HTTP to HTTPS

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
