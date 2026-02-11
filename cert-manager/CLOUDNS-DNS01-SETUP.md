# cert-manager ClouDNS DNS-01 Implementation

## Overview

This directory contains the resources to deploy cert-manager with ClouDNS DNS-01 ACME provider to replace the failing Traefik ACME setup.

**Status:** Ready to test  
**Cluster(s):** bluebox, proxmox  
**Domain:** xs4some.nl  
**ClouDNS Sub-Auth ID:** 81154

## Problem Statement

Traefik's built-in ACME with ClouDNS provider was returning "zone xs4some.nl not found for authFQDN" on both clusters. This suggests:
- ClouDNS API zone lookup issues with Lego library
- Sub-auth account limitations (zone ID constraint)
- DNS record propagation delays

**Solution:** Deploy cert-manager's webhook-based DNS-01 provider for ClouDNS, which offers:
- Better error visibility (cert-manager logs vs. Traefik debug)
- Separate secret management (not embedded in Traefik config)
- Native Kubernetes integration via ClusterIssuer resources
- Decoupled from ingress controller (no Traefik restarts needed)

## Directory Structure

```
cert-manager/
├── clusterissuer.yaml           # HTTP-01 issuer (existing)
├── cloudns-issuers.yaml         # DNS-01 issuers (NEW - staging + prod)
└── cloudns-webhook/
    ├── chart/                   # Vendored Helm chart
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   ├── .helmignore
    │   └── templates/
    │       ├── _helpers.tpl
    │       ├── apiservice.yaml
    │       ├── deployment.yaml
    │       ├── pki.yaml
    │       ├── rbac.yaml
    │       ├── secret-rbac.yaml
    │       └── service.yaml
    ├── values-override.yaml      # Configuration
    ├── render.sh                 # Generate cloudns-webhook.yaml
    ├── cloudns-webhook.yaml      # Generated manifests (ready to apply)
    ├── deploy.sh                 # One-command deployment
    └── README.md                 # Documentation
```

## Deployment

### Step 1: Update ClouDNS Password

Edit the secret manifest with your actual ClouDNS sub-auth password:

```bash
vim cloudns-issuers.yaml
# Change: auth_password: "CHANGE_ME" → auth_password: "your-real-password"
```

Or use the interactive deploy script (see Step 3).

### Step 2: Review Webhook Manifest

Review the generated webhook deployment:

```bash
cat cert-manager/cloudns-webhook/cloudns-webhook.yaml | grep -E "^(kind:|  name:)" | head -30
```

Expected resources:
- ServiceAccount, ClusterRole, ClusterRoleBinding (RBAC)
- Deployment, Service, APIService (webhook)
- Certificates, Issuers (for webhook TLS)

### Step 3: Deploy to Cluster

**Option A: Interactive Deployment (Recommended)**

```bash
cd cert-manager/cloudns-webhook
./deploy.sh bluebox    # or: proxmox
# Script will prompt for password interactively
```

**Option B: Manual Deployment**

```bash
# Create namespace
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Create secret (edit password first)
kubectl apply -f ../cloudns-issuers.yaml -n cert-manager

# Deploy webhook
kubectl apply -f cloudns-webhook.yaml

# Wait for deployment
kubectl rollout status deployment/cloudns-webhook -n cert-manager --timeout=2m

# Verify
kubectl get pod -n cert-manager -l app=cloudns-webhook
kubectl get clusterissuer
```

## Verification

### 1. Webhook Status

```bash
# Check deployment
kubectl get deployment -n cert-manager cloudns-webhook
kubectl logs -n cert-manager -l app=cloudns-webhook --tail=20

# Check webhook availability
kubectl get apiservice v1alpha1.acme.xs4some.nl -o yaml
```

### 2. ClusterIssuer Status

```bash
kubectl describe clusterissuer letsencrypt-dns01-cloudns-staging
kubectl describe clusterissuer letsencrypt-dns01-cloudns
```

Look for:
- `Status.Conditions[0].Type == Ready`
- `Status.Conditions[0].Status == True`

### 3. Test Certificate Issuance

Create a test Ingress:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-cloudns-dns01
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns01-cloudns-staging
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - test.xs4some.nl
    secretName: test-cloudns-tls
  rules:
  - host: test.xs4some.nl
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

Apply and monitor:

```bash
kubectl apply -f test-ingress.yaml

# Monitor cert creation
kubectl describe certificate test-cloudns-tls
kubectl get certificate test-cloudns-tls -o yaml | grep -A 10 status

# Check webhook logs for DNS challenge progress
kubectl logs -n cert-manager -l app=cloudns-webhook -f

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f
```

**Expected flow:**
1. cert-manager detects Ingress with `cert-manager.io/cluster-issuer` annotation
2. Creates Certificate resource
3. Initiates DNS-01 challenge request with cert-manager
4. cert-manager calls webhook at APIService `v1alpha1.acme.xs4some.nl`
5. Webhook mounts `cloudns-api-secret` (auth_id, auth_password)
6. Webhook creates DNS record `_acme-challenge.test.xs4some.nl` in ClouDNS
7. ACME server validates DNS record
8. Cert issued, saved to secret `test-cloudns-tls`

### 4. Monitor DNS Record Creation

During challenge, verify DNS record appears in ClouDNS:

```bash
# From shell with nslookup/dig
nslookup _acme-challenge.test.xs4some.nl 8.8.8.8

# Or check ClouDNS dashboard
# Zone: xs4some.nl → Records → Look for _acme-challenge.test
```

## Troubleshooting

### Webhook pod stuck in ImagePullBackOff

```bash
kubectl describe pod -n cert-manager -l app=cloudns-webhook
# Check image: ixoncloud/cert-manager-webhook-cloudns:1.1.1
# Verify image exists (may need docker login if private registry)
```

### Certificate stuck in "Waiting for ACME server to verify DNS propagation"

Check webhook logs:

```bash
kubectl logs -n cert-manager -l app=cloudns-webhook --tail=50
```

Common issues:
- **"auth_id not found"** → cloudns-api-secret not created or missing `auth_id` key
- **"auth_password not found"** → cloudns-api-secret missing `auth_password` key
- **"zone xs4some.nl not found"** → ClouDNS API issue (verify sub-auth has zone access)
- **"propagation check failed"** → DNS record created but not resolvable globally

### ClusterIssuer status shows "Error"

```bash
kubectl describe clusterissuer letsencrypt-dns01-cloudns-staging
```

Check:
- Webhook is running: `kubectl get pod -n cert-manager cloudns-webhook`
- APIService is ready: `kubectl get apiservice v1alpha1.acme.xs4some.nl`
- Secret exists: `kubectl get secret -n cert-manager cloudns-api-secret`

## Transition from Traefik ACME

Once DNS-01 issuance works:

### 1. Update Ingresses

Replace Traefik resolver annotations with cert-manager issuer:

```yaml
# Before (Traefik):
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.tls: "true"

# After (cert-manager):
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns01-cloudns
```

### 2. Disable Traefik ACME

Edit Traefik config (or Helm values) to remove:

```yaml
# traefik/k8s/config.yaml - REMOVE:
certificatesResolvers:
  letsencrypt:
    acme:
      email: ...
      storage: ...
      dnsChallenge:
        provider: cloudns
      caServer: ...
```

Restart Traefik:

```bash
kubectl rollout restart deployment traefik -n kube-system
```

### 3. Migrate Existing Certs

Old ACME certs in `traefik-acme-storage` secret can be:
- Exported and imported as cert-manager secrets (manual)
- Left as-is and allowed to expire (certs will auto-renew with cert-manager)
- Removed once new certs are issued

## Testing Checklist

- [ ] Webhook pod running: `kubectl get pod -n cert-manager cloudns-webhook`
- [ ] APIService available: `kubectl get apiservice v1alpha1.acme.xs4some.nl`
- [ ] Secret created: `kubectl get secret -n cert-manager cloudns-api-secret`
- [ ] ClusterIssuers ready: `kubectl get clusterissuer`
- [ ] Test Ingress created with staging issuer
- [ ] Certificate issued: `kubectl get certificate test-cloudns-tls`
- [ ] TLS secret created: `kubectl get secret test-cloudns-tls`
- [ ] Domain resolvable via test cert

## References

- [mschirrmeister/cert-manager-webhook-cloudns](https://github.com/mschirrmeister/cert-manager-webhook-cloudns)
- [cert-manager DNS01 Webhook Docs](https://cert-manager.io/docs/concepts/webhooks/)
- [ClouDNS API Docs](https://www.cloudns.net/wiki/article/44/)
- [Helm Templating](https://helm.sh/docs/helm/helm_template/)
