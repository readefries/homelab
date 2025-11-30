#!/usr/bin/env bash
set -euo pipefail

# Migration script to move Plex from LXC 105 into k8s
LXC_ID=105
HOST_PLEX_CONFIG=/srv/plex/config
HOST_PLEX_TRANSCODE=/srv/plex/transcode

echo "Stopping Plex inside LXC ${LXC_ID} (for DB consistency)..."
ssh root@proxmox "pct exec ${LXC_ID} -- systemctl stop plexmediaserver || true"

echo "Creating host directories..."
ssh root@proxmox "mkdir -p ${HOST_PLEX_CONFIG} ${HOST_PLEX_TRANSCODE} && chown -R 1000:1000 ${HOST_PLEX_CONFIG} ${HOST_PLEX_TRANSCODE} || true"

echo "Copying Plex config from LXC to host..."
ssh root@proxmox "pct exec ${LXC_ID} -- tar -C /var/lib/plexmediaserver -cf - . | tar -C ${HOST_PLEX_CONFIG} -xpf - || rsync -aHAX --numeric-ids --delete ${LXC_ID}:/var/lib/plexmediaserver/ ${HOST_PLEX_CONFIG}/"

echo "Applying Kubernetes manifests..."
scp -r /workspaces/homelab/k8s/plex root@proxmox:/tmp/plex-k8s
ssh root@proxmox "kubectl apply -f /tmp/plex-k8s/namespace.yaml && kubectl apply -f /tmp/plex-k8s/deployment.yaml && kubectl apply -f /tmp/plex-k8s/service.yaml"

echo "Waiting for pod to be ready (give it a minute)..."
ssh root@proxmox "kubectl -n plex wait --for=condition=available deployment/plex --timeout=120s || kubectl -n plex get pods -o wide"

echo "Plex migration applied. Test access at http://<host-ip>:32400/web"
echo "If everything is good, you can remove LXC ${LXC_ID} after verifying the library."
