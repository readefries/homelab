# Dev Container + Kind + Podman Setup

## Known Issue: Networking

When using Kind with Podman as the provider, the Kind cluster runs on the **host's Podman** network, but the dev container runs in a separate network namespace. This means kubectl inside the dev container cannot directly reach the Kind API server.

## Workaround Options

### Option 1: Rebuild Dev Container to Join Kind Network (Recommended after first setup)

After the Kind cluster is created, rebuild the dev container to join the `kind` network:

1. Add this to `.devcontainer/devcontainer.json`:
   ```json
   "runArgs": [
     "--network=kind"
   ]
   ```

2. Rebuild the container: `Dev Containers: Rebuild Container`

3. kubectl should now work directly

### Option 2: Port Forward from Host (Quick Test)

Run this on your **host machine** (outside the dev container):

```bash
# Forward the API server port
kubectl port-forward --address 0.0.0.0 -n kube-system service/kubernetes 6443:443 &
```

Then in the dev container, update kubeconfig:
```bash
# Update server address in ~/.kube/config to use host gateway
# Find your gateway IP
ip route | grep default
# Update kubeconfig server to https://GATEWAY_IP:6443
```

### Option 3: Use Host's kubectl (Simplest)

Instead of using kubectl inside the dev container, use it on your host machine which already has access to the Kind cluster.

## Current Setup

The postcreate script:
- Installs Podman and Kind
- Creates a Kind cluster using host's Podman
- Attempts to set up socat forwarding (doesn't work due to network isolation)

## Recommended Flow

1. **First time**: Run postcreate script, it creates the Kind cluster
2. **Rebuild container**: Add `"runArgs": ["--network=kind"]` to devcontainer.json and rebuild
3. **Deploy**: Run `cd dns && ./deploy.sh`

## Manual kubectl Setup (if needed)

If you need to manually fix kubectl access:

```bash
# Get the Kind container IP
export CONTAINER_HOST="unix:///run/podman/podman.sock"
KIND_IP=$(podman inspect dev-cluster-control-plane --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)

# Update kubeconfig
sed -i "s|https://[0-9.]*:[0-9]*|https://${KIND_IP}:6443|g" ~/.kube/config

# Test (will only work if networks are connected)
kubectl cluster-info
```
