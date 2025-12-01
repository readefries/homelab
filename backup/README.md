Backup runner image and CronJob template

Files added:
- `Containerfile` - builds an image based on `ubuntu:24.04` with `node` and the `@filen/cli` installed.
- `backup-runner.sh` - main script that tars `TARGET_DIR` and uploads via `filen upload` to `FILEN_DEST`, with automatic pruning of old backups.
- `checkdates.py` - helper script to parse backup dates and identify files older than `RETENTION_DAYS`.
- `k8s/backup-cronjob-template.yaml` - simple template for creating a per-service CronJob using the image.

Quick build (on host where you build images):
```bash
podman build -t ghcr.io/readefries/backup-runner-filen:latest .
podman push ghcr.io/readefries/backup-runner-filen:latest
```

Then create a per-service CronJob by copying `k8s/backup-cronjob-template.yaml` and replacing placeholders:
- `BACKUP_NAME_PLACEHOLDER` -> e.g. `vaultwarden-backup`
- `NAMESPACE_PLACEHOLDER` -> `vaultwarden`
- `CRON_SCHEDULE_PLACEHOLDER` -> `0 3 * * *` (daily at 03:00)
- `PVC_NAME_PLACEHOLDER` -> `vaultwarden-data`
- `REPOSITORY_PLACEHOLDER` -> your registry (e.g. `ghcr.io/readefries`)
- `FILEN_DEST_PLACEHOLDER` -> e.g. `/backups/vaultwarden/`

Important: do not commit your Filen secrets. The backup job expects the Filen auth config as an environment variable:
```bash
# Create secret with Filen auth config
kubectl -n vaultwarden create secret generic filen-auth \
  --from-file=.filen-cli-auth-config=/path/to/.filen-cli-auth-config

# If using private GHCR images, create image pull secret:
kubectl -n vaultwarden create secret docker-registry ghcr-creds \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT
```

Environment variables:
- `TARGET_DIR` - path to backup (required)
- `FILEN_DEST` - remote Filen path (required, e.g. `/backups/vaultwarden/`)
- `RETENTION_DAYS` - days to keep backups, older files are pruned (default: 30)
- `FILEN_AUTH_CONFIG` - Filen CLI auth config content (injected from secret)
- `ALERT_WEBHOOK` - optional webhook URL for failure alerts
- `ALERT_TOKEN` - optional bearer token for webhook
- `DEBUG` - set to `1` for verbose output
- `PRUNE_DRY_RUN` - set to `1` to test pruning without deleting

Note: Ubuntu 24.04 base is required for glibc 2.39 compatibility with the latest Filen CLI and its dependencies.

## Restore and Testing

See [RESTORE.md](RESTORE.md) for comprehensive restore procedures and testing.

Quick test:
```bash
# Test that backups can be restored
./test-restore.sh vaultwarden /backups/vaultwarden/

# Restore to a copy PVC for safe verification (recommended)
./restore-to-copy.sh vaultwarden /backups/vaultwarden/backup-20251201-030000.tar.gz

# Or manually via kubectl
kubectl -n vaultwarden create job vaultwarden-restore-test \
  --from=cronjob/vaultwarden-backup -- /bin/bash -c "filen list /backups/vaultwarden/"
```

The `restore-to-copy.sh` script will:
1. Create a temporary PVC
2. Restore the backup to it
3. Create a verification pod for you to inspect the data
4. Provide commands to copy to production if data looks good
