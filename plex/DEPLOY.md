Plex on k3s — deployment & troubleshooting
=========================================

Purpose
-------
This file documents the steps and commands used to migrate and deploy Plex Media Server into the k3s cluster on the Proxmox host, and the troubleshooting steps we followed (AppArmor / s6 permissions / hostPort). Keep this with the repo for future reference.

Quick context
-------------
- Node: Proxmox (k3s single-node)
- Node IP: 172.16.0.8 (example)
- KUBECONFIG on host: `/etc/rancher/k3s/k3s.yaml`
- Chart: `plexinc/pms-docker` (we installed from the release tarball)
- Values overrides: `plex/helm/values.yaml` in this repo

Common environment variables (run on the Proxmox host before kubectl/helm)

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Install / upgrade Helm chart (local chart directory)
-------------------------------------------------

1. Copy `values.yaml` to the host (we used `/root/plex/values.yaml`):

```bash
scp plex/helm/values.yaml root@proxmox:/root/plex/values.yaml
```

2. Download chart tarball (if upstream repo unreachable) and extract:

```bash
curl -L -o plex-chart.tgz "https://github.com/plexinc/pms-docker/releases/download/helm-chart-1.3.0/plex-media-server-1.3.0.tgz"
mkdir -p /root/plex/release && tar -xzf plex-chart.tgz -C /root/plex/release
```

3. Install or upgrade with your `values.yaml`:

```bash
helm upgrade --install plex /root/plex/release/plex-media-server -n plex --create-namespace -f /root/plex/values.yaml
```

Expose and bind to host
-----------------------
- The chart was configured to use `hostNetwork: true` and a `hostPort: 32400` in our values so Plex listens on the node's network directly for discovery and direct connections.
- Because of `hostPort`, keep `replicas: 1` — Kubernetes will fail to schedule a second pod that requests the same host port.

AppArmor / s6: the main issue we hit
-----------------------------------
- The container uses `s6` (`/usr/bin/s6-setuidgid`) to drop privileges. On systems with AppArmor and the default runtime profile, s6 invocations can be blocked, producing repeated:

  "./run: line 18: /usr/bin/s6-setuidgid: Permission denied"

- Two approaches:
  - Preferred (K8s v1.30+): set `spec.securityContext.appArmorProfile` to `Unconfined` or a local profile in the Pod spec/template so the control plane applies it properly.
    - Example patch (applies to the Deployment's pod template):
      ```bash
      kubectl -n plex patch deployment plex --type=merge -p '{"spec":{"template":{"spec":{"securityContext":{"appArmorProfile":{"type":"Unconfined"}}}}}}'
      kubectl -n plex rollout restart deployment plex
      ```
  - Fallback (older clusters): add the legacy annotation on the pod template:
    ```yaml
    podAnnotations:
      container.apparmor.security.beta.kubernetes.io/plex: unconfined
    ```
    This works until your cluster supports the new field, but produces a deprecation warning on newer clusters.

How we safely removed the deprecated annotation
----------------------------------------------
- To avoid accidental invalid patches, use `kubectl annotate` to remove an annotation key:

```bash
kubectl -n plex annotate deployment plex container.apparmor.security.beta.kubernetes.io/plex- --overwrite
kubectl -n plex rollout restart deployment plex
```

Forcibly recreate pods to pick up template changes
-------------------------------------------------
- If you change the pod template and need pods replaced immediately:

```bash
# Delete the running pod so the ReplicaSet creates a replacement
kubectl -n plex delete pod <running-pod-name>

# Alternatively scale to zero then back to one
kubectl -n plex scale deployment plex --replicas=0
kubectl -n plex scale deployment plex --replicas=1
```

Useful verification commands
----------------------------
- Check pod template annotations & securityContext:

```bash
kubectl -n plex get deployment plex -o yaml | sed -n '1,200p'
kubectl -n plex get deployment plex -o jsonpath="{.spec.template.spec.securityContext}"
```

- Check pods and logs:

```bash
kubectl -n plex get pods -o wide
kubectl -n plex logs deployment/plex --tail=200
kubectl -n plex logs pod/<pod-name> --tail=200
```

- Check AppArmor denials on the host (if present):

```bash
dmesg | grep -i apparmor | tail -n 200
journalctl -k | grep -i apparmor | tail -n 200
```

- Check host port listener:

```bash
ss -tulnp | grep 32400
```

Troubleshooting checklist
-------------------------
- If you see repeated s6 `Permission denied` errors in the container logs:
  1. Ensure the Deployment pod template has `appArmorProfile` set (prefer) or the annotation present.
  2. Recreate the pod so the new profile is effective (delete pod or scale 0/1).
  3. Inspect host AppArmor logs to confirm denials and the profile that caused them (profile name like `cri-containerd.apparmor.d`).
  4. If you can't use Unconfined, consider creating a local AppArmor profile on the node that allows the socket operations s6 needs and reference it with `localhostProfile`.

- If the pod fails to schedule with `no free ports`:
  - You have `hostPort: 32400` and more than one replica — set `replicas: 1`.

- File ownership issues: ensure host directories for `config` and `transcode` are owned by the same UID/GID Plex uses (we used `PLEX_UID=1000` / `PLEX_GID=1000` and ran `chown -R 1000:1000 /srv/plex/config /srv/plex/transcode`).

Notes and recommendations
-------------------------
- Prefer the `appArmorProfile` fields when your cluster supports them (Kubernetes v1.30+). The `kubectl explain pod.spec` output will show `appArmorProfile` if available.
- Avoid `hostPort` when possible (use NodePort/LoadBalancer/Ingress) if you want replica scaling; we used `hostPort` because we wanted Plex to be directly reachable on the node IP.
- Keep `plex/helm/values.yaml` in the repo updated with PLEX_CLAIM and PLEX_UID/GID values; copy it to the host when deploying.

Checklist for next migration
---------------------------
 - [ ] Create host dirs: `/srv/plex/config` and `/srv/plex/transcode`.
 - [ ] Create host dirs: `/srv/plex/config`, `/srv/plex/transcode`, and `/Media/Music` (or wherever you store music).
 - [ ] Stop Plex inside LXC and `rsync` or `tar` config to `/srv/plex/config`.
 - [ ] `chown -R 1000:1000 /srv/plex/config /srv/plex/transcode` (if using UID 1000).
 - [ ] Copy `values.yaml` to host and run Helm install/upgrade.
 - [ ] Ensure only one replica if using `hostPort`.
 - [ ] If s6 errors appear: apply `appArmorProfile` or annotation then recreate pods.

File: `plex/helm/values.yaml` (kept in this repo) is the source-of-truth for how the chart is configured.

If you want, I can also add a short `scripts/` helper to copy `values.yaml` to the host and run the `helm upgrade --install` command automatically.

---
Created by the migration session — keep this with the `plex/` folder for future reference.
