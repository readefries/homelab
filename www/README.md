# Static Website

This directory contains the Kubernetes manifests and container configuration for deploying the static website serving multiple domains.

## Overview

The website serves content for:
- `xs4some.nl` and `www.xs4some.nl`
- `readefries.nl` and `www.readefries.nl`
- `de.readefries.nl` (Frisian language version from `/fy` folder)

## Components

### Container Image
- **Containerfile**: Builds nginx container with static content from GitHub repository
- **nginx.conf**: Nginx configuration with language-based routing logic

### Kubernetes Resources
- **deployment.yaml**: Deployment with 2 replicas and Service
- **ingress.yaml**: Traefik IngressRoutes for all domains with TLS
- **pvc.yaml**: PersistentVolumeClaim (optional, for future use)

## Deployment

### Prerequisites
- Kubernetes cluster with kubectl configured
- Traefik ingress controller installed
- Let's Encrypt cert resolver configured in Traefik

### Deploy
```bash
./deploy.sh
```

Or manually:
```bash
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

## Building Container Image

To rebuild the container image:
```bash
podman build -t ghcr.io/readefries/static-page/staticpage:latest -f Containerfile .
podman push ghcr.io/readefries/static-page/staticpage:latest
```

## Monitoring

Check deployment status:
```bash
kubectl get pods -l app=website
kubectl get svc website
kubectl get ingressroute
```

View logs:
```bash
kubectl logs -l app=website -f
```

## Configuration

### Language Routing
The nginx configuration routes traffic based on domain:
- `de.readefries.nl` and `readefries.nl` → serves content from `/fy/` folder
- Other domains → serves content from root folder

### Resources
- CPU: 50m request, 200m limit
- Memory: 64Mi request, 128Mi limit
