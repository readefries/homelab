# DNS Over HTTPS with Ad Blocking

Privacy-focused DNS setup with device-specific ad/content filtering.

## Architecture

```
Kid Devices  → DoH :30054 → CoreDNS → Unbound → Root Servers
                             ↓ Blocks: porn, gambling, fakenews
                             
Adult Devices → DoH :30055 → CoreDNS → Unbound → Root Servers
                              ↓ Blocks: gambling, fakenews
```

- **CoreDNS**: Ad/content blocking using Steven Black's hosts lists
- **Unbound**: Recursive DNS resolver (queries root servers directly)
- **DoH**: Encrypted DNS queries over HTTPS

## Deploy

```bash
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f unbound-config.yaml -f unbound.yaml
kubectl apply -f coredns-kids.yaml -f coredns-standard.yaml
kubectl apply -f doh-kids.yaml -f doh-standard.yaml
```

## Use It

Configure devices to use DoH:

**Kid devices:** `http://10.89.0.3:30054/dns-query`  
**Adult devices:** `http://10.89.0.3:30055/dns-query`

Test with curl:
```bash
curl -H 'accept: application/dns-json' \
  'http://10.89.0.3:30054/dns-query?name=google.com&type=A'
```

## Check Status

```bash
kubectl get pods -n dns-system
kubectl logs -n dns-system deployment/coredns-kids
```

## Update Blocklists

Blocklists download automatically on pod restart:
```bash
kubectl rollout restart deployment/coredns-kids -n dns-system
```

Or change URLs in `coredns-kids.yaml` / `coredns-standard.yaml`