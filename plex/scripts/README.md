Plex scripts
===========

This folder contains helper scripts for deploying Plex with Helm to the Proxmox k3s node.

deploy.sh
---------
- Copies `plex/helm/values.yaml` to the remote Proxmox host and runs the `helm upgrade --install` command using the chart located on the remote host.
- Usage examples:

```bash
# Default (uses root@proxmox and /root/plex)
./deploy.sh

# Specify host and remote dir
./deploy.sh --host root@proxmox --remote-dir /root/plex

# Use environment variables
REMOTE_HOST=root@proxmox REMOTE_DIR=/root/plex ./deploy.sh
```

Notes
-----
- The script assumes you can SSH to the remote host (key authentication recommended).
- The script runs `helm` on the remote host and uses `KUBECONFIG=/etc/rancher/k3s/k3s.yaml` there.
