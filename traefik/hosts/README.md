# Traefik Examples for External Services

## Routing to Services Outside Kubernetes

Traefik can route traffic to **any** backend, not just Kubernetes pods. This allows you to migrate services gradually.

### Example 1: VM with IP Address

If you have a web service running on `172.16.0.100:3000`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-vm-service
  namespace: default
spec:
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: v1
kind: Endpoints
metadata:
  name: my-vm-service  # Must match Service name
  namespace: default
subsets:
- addresses:
  - ip: 172.16.0.100  # Your VM IP
  ports:
  - port: 3000  # Port on VM
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-vm-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: myapp.xs4some.nl
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-vm-service
            port:
              number: 80
  tls:
  - hosts:
    - myapp.xs4some.nl
    secretName: myapp-tls
```

### Example 2: Multiple VMs (Load Balancing)

Route to multiple backend IPs:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: multi-vm-service
  namespace: default
subsets:
- addresses:
  - ip: 172.16.3.10
  - ip: 172.16.3.11
  - ip: 172.16.3.12
  ports:
  - port: 8080
```

### Example 3: Different Paths to Different VMs

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-backend
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: services.xs4some.nl
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: vm1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: vm2-service
            port:
              number: 80
```

### Example 4: WebSocket Support

For WebSocket applications:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: websocket-app
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.middlewares: default-websocket@kubernetescrd
spec:
  rules:
  - host: ws.xs4some.nl
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: websocket-service
            port:
              number: 80
```

### Example 5: Custom Headers

Add custom headers to requests:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-headers
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.middlewares: default-custom-headers@kubernetescrd
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: custom-headers
  namespace: default
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-Proto: "https"
    customResponseHeaders:
      X-Custom-Header: "MyValue"
```

## Benefits

1. **Gradual Migration**: Keep services on VMs while you migrate
2. **Centralized SSL**: One place for all SSL certificates
3. **Single Entry Point**: All services through Traefik
4. **No Service Changes**: VMs don't know they're behind Traefik

## Common Use Cases

- **Legacy Apps**: Old applications that can't be containerized yet
- **Databases**: Expose database admin panels (pgAdmin, phpMyAdmin)
- **IoT Devices**: Route to devices with web interfaces
- **Proxmox UI**: Expose Proxmox interface with SSL
- **Home Assistant**: Smart home interfaces
- **NAS**: Synology/QNAP web interfaces
