# ClouDNS Webhook for cert-manager

Helm chart + manifests for deploying cert-manager DNS-01 webhook provider for ClouDNS.

## Files

- **chart/** — Vendored Helm chart from [mschirrmeister/cert-manager-webhook-cloudns](https://github.com/mschirrmeister/cert-manager-webhook-cloudns)
- **values-override.yaml** — Custom Helm values (groupName, secretName, fullnameOverride, authIdType=sub-auth-id)
- **render.sh** — Script to render chart template into cloudns-webhook.yaml
- **cloudns-webhook.yaml** — Generated manifests (ServiceAccount, ClusterRole, Deployment, Service, APIService, Certificates, Issuers)
- **deploy.sh** — Interactive deployment script
- **../cloudns-issuers.yaml** — DNS-01 ClusterIssuers (staging + production)

## Quick Start

### 1. Update Credentials

Edit `cloudns-issuers.yaml` with your ClouDNS password:

```bash
vim ../cloudns-issuers.yaml
# Update: auth_password: "AMFFtY%qp1A$6S" (if needed)
```

### 2. Deploy

```bash
./deploy.sh floki    # or: ./deploy.sh proxmox
```

The script will:
- Create cert-manager namespace
- Apply cloudns-issuers.yaml (secret + ClusterIssuers)
- Deploy webhook (deployment, service, APIService)
- Wait for webhook to be ready

### 3. Verify

```bash
kubectl get pod -n cert-manager -l app=cloudns-webhook
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-dns01-cloudns-staging
```

### 4. Test with an Ingress

Update your Ingress to use the staging issuer first:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns01-cloudns-staging
spec:
  tls:
  - hosts:
    - example.xs4some.nl
    secretName: example-tls
  rules:
  - host: example.xs4some.nl
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example
            port:
              number: 80
```

Monitor cert issuance:

```bash
kubectl describe certificate example-tls
kubectl logs -n cert-manager -l app=cloudns-webhook --tail=50 -f
```

Once staging works, switch annotation to `letsencrypt-dns01-cloudns`.

## Configuration

**Sub-Auth ID:** 81154  
**Zone:** xs4some.nl  
**Group Name:** acme.xs4some.nl (used in ClusterIssuer webhook.groupName)  
**Secret Name:** cloudns-api-secret (in cert-manager namespace)

Edit `values-override.yaml` to adjust groupName or other settings; re-run `./render.sh` to update manifests.

## Webhook Environment Variables

The webhook reads ClouDNS credentials from environment variables set via the secret:

- `CLOUDNS_AUTH_ID_FILE` → `/creds/auth_id` (from secret key: auth_id)
- `CLOUDNS_AUTH_PASSWORD_FILE` → `/creds/auth_password` (from secret key: auth_password)
- `GROUP_NAME` → acme.xs4some.nl
- `CLOUDNS_AUTH_ID_TYPE` → sub-auth-id

## Disabling Traefik ACME

Once ClouDNS DNS-01 is working with cert-manager, disable Traefik's ACME provider:

1. Remove Traefik's `certificatesResolvers.letsencrypt` config
2. Remove `--certificatesresolvers.letsencrypt.*` CLI flags
3. Restart Traefik
4. Update Ingresses to use `cert-manager.io/cluster-issuer` instead of Traefik resolver

This avoids conflicts and allows cert-manager to manage all certificates.

## References

- [cert-manager-webhook-cloudns](https://github.com/mschirrmeister/cert-manager-webhook-cloudns)
- [cert-manager Webhook API Docs](https://cert-manager.io/docs/concepts/webhooks/)
- [cert-manager DNS Providers](https://cert-manager.io/docs/configuration/acme/dns01/)
