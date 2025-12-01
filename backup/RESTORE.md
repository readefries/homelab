# Backup Restore Guide

## Overview

This guide covers how to restore data from Filen backups created by the backup-runner.

## Prerequisites

- Access to Filen CLI with authentication configured
- `kubectl` access to the target namespace
- Backup file name/path from Filen

## Restore Process

### 1. List Available Backups

```bash
# List backups for a service
filen list /backups/vaultwarden/

# With JSON output for scripting
filen list /backups/vaultwarden/ --json
```

### 2. Download Backup

```bash
# Download to local system
filen download /backups/vaultwarden/backup-20251201-030000.tar.gz ./backup-20251201-030000.tar.gz

# Or download to a temporary location
mkdir -p /tmp/restore
cd /tmp/restore
filen download /backups/vaultwarden/backup-20251201-030000.tar.gz ./backup.tar.gz
```

### 3. Restore Methods

#### Method A: Restore to Copy (Recommended for Testing)

This method restores to a separate PVC/location so you can verify the backup before touching production data.

```bash
# First, create a temporary PVC for restore testing
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vaultwarden-data-restore
  namespace: vaultwarden
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

# Create restore job to the copy PVC
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: vaultwarden-restore-to-copy
  namespace: vaultwarden
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      imagePullSecrets:
      - name: ghcr-creds
      containers:
      - name: restore
        image: ghcr.io/readefries/backup-runner-filen:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          set -e
          echo "Downloading backup from Filen..."
          filen download /backups/vaultwarden/backup-20251201-030000.tar.gz /tmp/backup.tar.gz
          
          echo "Extracting backup to /restore..."
          cd /restore
          tar -xzf /tmp/backup.tar.gz
          
          echo "Restore complete!"
          echo "Restored data is in /restore"
          ls -lah /restore
          
          echo ""
          echo "To inspect, run:"
          echo "  kubectl -n vaultwarden exec -it deploy/vaultwarden-restore-verify -- /bin/bash"
        env:
        - name: FILEN_AUTH_CONFIG
          valueFrom:
            secretKeyRef:
              name: filen-auth
              key: .filen-cli-auth-config
        volumeMounts:
        - name: restore-data
          mountPath: /restore
      volumes:
      - name: restore-data
        persistentVolumeClaim:
          claimName: vaultwarden-data-restore
EOF

# Monitor the restore
kubectl -n vaultwarden logs -f job/vaultwarden-restore-to-copy

# Create a verification pod to inspect the restored data
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vaultwarden-restore-verify
  namespace: vaultwarden
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vaultwarden-restore-verify
  template:
    metadata:
      labels:
        app: vaultwarden-restore-verify
    spec:
      containers:
      - name: verify
        image: vaultwarden/server:latest
        command: ["sleep", "infinity"]
        env:
        - name: DATA_FOLDER
          value: /data
        volumeMounts:
        - name: restore-data
          mountPath: /data
          readOnly: true
      volumes:
      - name: restore-data
        persistentVolumeClaim:
          claimName: vaultwarden-data-restore
EOF

# Wait for pod to be ready
kubectl -n vaultwarden wait --for=condition=ready pod -l app=vaultwarden-restore-verify

# Inspect the restored data
kubectl -n vaultwarden exec -it deploy/vaultwarden-restore-verify -- /bin/bash

# Inside the pod, you can:
# - Check database: sqlite3 /data/db.sqlite3 "SELECT COUNT(*) FROM users;"
# - Verify files: ls -la /data/
# - Check config: cat /data/config.json

# When satisfied, copy to production or delete
# To copy to production (CAREFUL):
# kubectl -n vaultwarden scale deployment vaultwarden --replicas=0
# kubectl -n vaultwarden exec deploy/vaultwarden-restore-verify -- tar -czf - -C /data . | \
#   kubectl -n vaultwarden exec -i PRODUCTION_POD -- tar -xzf - -C /data

# Cleanup test resources
kubectl -n vaultwarden delete job vaultwarden-restore-to-copy
kubectl -n vaultwarden delete deployment vaultwarden-restore-verify
kubectl -n vaultwarden delete pvc vaultwarden-data-restore
```

#### Method B: Restore to Production (Direct)

This method restores directly to the production PVC. **Use only after testing with Method A.**

This method uses a Kubernetes job to download and restore directly to the PVC.

```bash
# Create restore job (example for vaultwarden)
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: vaultwarden-restore
  namespace: vaultwarden
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      imagePullSecrets:
      - name: ghcr-creds
      containers:
      - name: restore
        image: ghcr.io/readefries/backup-runner-filen:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          set -e
          echo "Downloading backup from Filen..."
          filen download /backups/vaultwarden/backup-20251201-030000.tar.gz /tmp/backup.tar.gz
          
          echo "Stopping any existing data (optional - ensure app is scaled down first)"
          
          echo "Extracting backup to /data..."
          cd /data
          tar -xzf /tmp/backup.tar.gz
          
          echo "Restore complete!"
          ls -la /data
        env:
        - name: FILEN_AUTH_CONFIG
          valueFrom:
            secretKeyRef:
              name: filen-auth
              key: .filen-cli-auth-config
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: vaultwarden-data
EOF

# Monitor the restore job
kubectl -n vaultwarden logs -f job/vaultwarden-restore

# Clean up after successful restore
kubectl -n vaultwarden delete job vaultwarden-restore
```

#### Method C: Manual Restore (Local Download)

1. **Scale down the application** to prevent data corruption:
   ```bash
   kubectl -n vaultwarden scale deployment vaultwarden --replicas=0
   ```

2. **Download and extract locally**:
   ```bash
   cd /tmp/restore
   filen download /backups/vaultwarden/backup-20251201-030000.tar.gz ./backup.tar.gz
   tar -xzf backup.tar.gz
   ```

3. **Copy to target location** (various methods):

   **Option 1: Via temporary pod**
   ```bash
   # Create a temporary pod with the PVC mounted
   kubectl run -n vaultwarden restore-helper \
     --image=ubuntu:24.04 \
     --restart=Never \
     --overrides='
   {
     "spec": {
       "containers": [{
         "name": "restore-helper",
         "image": "ubuntu:24.04",
         "command": ["sleep", "3600"],
         "volumeMounts": [{
           "name": "data",
           "mountPath": "/data"
         }]
       }],
       "volumes": [{
         "name": "data",
         "persistentVolumeClaim": {
           "claimName": "vaultwarden-data"
         }
       }]
     }
   }'
   
   # Wait for pod to be ready
   kubectl -n vaultwarden wait --for=condition=ready pod/restore-helper
   
   # Copy data to pod
   kubectl -n vaultwarden exec restore-helper -- rm -rf /data/*
   cd /tmp/restore
   kubectl -n vaultwarden cp . restore-helper:/data/
   
   # Verify
   kubectl -n vaultwarden exec restore-helper -- ls -la /data/
   
   # Clean up
   kubectl -n vaultwarden delete pod restore-helper
   ```

   **Option 2: Via hostPath (if PVC is local)**
   ```bash
   # SSH to the node where data is stored
   ssh root@proxmox
   
   # Find the PVC path (example)
   cd /srv/vaultwarden/data
   
   # Backup existing data
   mv /srv/vaultwarden/data /srv/vaultwarden/data.backup.$(date +%Y%m%d-%H%M%S)
   
   # Create new directory and extract
   mkdir -p /srv/vaultwarden/data
   cd /srv/vaultwarden/data
   scp user@devcontainer:/tmp/restore/backup.tar.gz .
   tar -xzf backup.tar.gz
   rm backup.tar.gz
   
   # Fix permissions
   chown -R 1000:1000 /srv/vaultwarden/data
   ```

4. **Scale application back up**:
   ```bash
   kubectl -n vaultwarden scale deployment vaultwarden --replicas=1
   ```

5. **Verify restoration**:
   - Check application logs
   - Test functionality
   - Verify data integrity

## Testing Restore Process

### Automated Restore Test

Create a restore test job that validates the backup can be restored:

```bash
# Test restore to temporary location
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: vaultwarden-restore-test
  namespace: vaultwarden
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      imagePullSecrets:
      - name: ghcr-creds
      containers:
      - name: restore-test
        image: ghcr.io/readefries/backup-runner-filen:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          set -e
          
          # Get latest backup
          echo "Finding latest backup..."
          latest_backup=\$(filen list /backups/vaultwarden/ --json | \
            python3 -c "import sys,json; files=json.load(sys.stdin); \
            backups=[f for f in files if 'backup-' in f.get('name','')]; \
            print(sorted(backups, key=lambda x: x['name'], reverse=True)[0]['name'] if backups else '')")
          
          if [ -z "\$latest_backup" ]; then
            echo "ERROR: No backups found!"
            exit 1
          fi
          
          echo "Latest backup: \$latest_backup"
          
          # Download
          echo "Downloading backup..."
          filen download "/backups/vaultwarden/\$latest_backup" /tmp/test-restore.tar.gz
          
          # Verify it's a valid tar.gz
          echo "Verifying archive integrity..."
          if tar -tzf /tmp/test-restore.tar.gz >/dev/null 2>&1; then
            echo "✓ Archive is valid"
          else
            echo "✗ Archive is corrupted!"
            exit 1
          fi
          
          # Extract to temp location
          echo "Testing extraction..."
          mkdir -p /tmp/test-extract
          cd /tmp/test-extract
          tar -xzf /tmp/test-restore.tar.gz
          
          # Verify expected files exist (customize per service)
          echo "Verifying restored data..."
          if [ -f "config.json" ]; then
            echo "✓ config.json found"
          else
            echo "⚠ config.json not found (may be expected)"
          fi
          
          echo "Listing restored files:"
          ls -lah /tmp/test-extract/
          
          echo ""
          echo "✓✓✓ RESTORE TEST PASSED ✓✓✓"
          echo "Backup can be successfully downloaded and extracted"
        env:
        - name: FILEN_AUTH_CONFIG
          valueFrom:
            secretKeyRef:
              name: filen-auth
              key: .filen-cli-auth-config
EOF

# Monitor test
kubectl -n vaultwarden logs -f job/vaultwarden-restore-test

# Check result
kubectl -n vaultwarden get job vaultwarden-restore-test

# Clean up
kubectl -n vaultwarden delete job vaultwarden-restore-test
```

### Manual Restore Test Checklist

1. **Test backup download**:
   ```bash
   filen list /backups/vaultwarden/
   filen download /backups/vaultwarden/backup-LATEST.tar.gz /tmp/test.tar.gz
   ```

2. **Verify archive integrity**:
   ```bash
   tar -tzf /tmp/test.tar.gz | head -20
   ```

3. **Test extraction**:
   ```bash
   mkdir /tmp/test-extract
   cd /tmp/test-extract
   tar -xzf /tmp/test.tar.gz
   ls -la
   ```

4. **Verify critical files exist**:
   ```bash
   # For vaultwarden
   ls -la /tmp/test-extract/*.{db,json}
   
   # Check database integrity if applicable
   sqlite3 /tmp/test-extract/db.sqlite3 "PRAGMA integrity_check;"
   ```

5. **Clean up**:
   ```bash
   rm -rf /tmp/test-extract /tmp/test.tar.gz
   ```

## Scheduled Restore Testing

Add a monthly restore test to your CronJob:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: vaultwarden-restore-test
  namespace: vaultwarden
spec:
  schedule: "0 4 1 * *"  # 1st of month at 04:00
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          imagePullSecrets:
          - name: ghcr-creds
          containers:
          - name: restore-test
            image: ghcr.io/readefries/backup-runner-filen:latest
            command: ["/bin/bash", "-c"]
            args:
            - |
              # Same test script as above
              set -e
              # ... test commands ...
            env:
            - name: FILEN_AUTH_CONFIG
              valueFrom:
                secretKeyRef:
                  name: filen-auth
                  key: .filen-cli-auth-config
            - name: ALERT_WEBHOOK
              valueFrom:
                secretKeyRef:
                  name: backup-alert
                  key: webhook
                  optional: true
            - name: ALERT_TOKEN
              valueFrom:
                secretKeyRef:
                  name: backup-alert
                  key: token
                  optional: true
```

## Disaster Recovery Scenarios

### Scenario 1: Complete Data Loss

1. Identify last known good backup
2. Use Method A (Kubernetes Job) to restore
3. Verify application starts correctly
4. Test critical functionality

### Scenario 2: Partial Corruption

1. Scale down application
2. Download backup locally
3. Extract and compare with current data
4. Selectively restore corrupted files
5. Scale application back up

### Scenario 3: Point-in-Time Recovery

1. List backups around the desired time
2. Download specific backup by timestamp
3. Restore following Method A or B
4. Verify data is from correct time period

## Troubleshooting

### Issue: "filen download" fails

```bash
# Check Filen authentication
filen whoami

# Verify file exists
filen stat /backups/vaultwarden/backup-TIMESTAMP.tar.gz

# Try with absolute path
filen download "/backups/vaultwarden/backup-TIMESTAMP.tar.gz" "./local-backup.tar.gz"
```

### Issue: "Permission denied" during restore

```bash
# Fix PVC permissions after restore
kubectl -n vaultwarden exec POD_NAME -- chown -R 1000:1000 /data
```

### Issue: Application won't start after restore

1. Check logs: `kubectl -n vaultwarden logs POD_NAME`
2. Verify file permissions
3. Check database integrity
4. Consider restoring from previous backup

## Best Practices

1. **Test restores regularly** (at least monthly)
2. **Document service-specific validation steps**
3. **Keep multiple backup generations** (adjust `RETENTION_DAYS`)
4. **Alert on restore test failures**
5. **Practice full disaster recovery** annually
6. **Verify backup integrity** before deleting old backups
7. **Document RTO/RPO requirements** per service

## Service-Specific Notes

### Vaultwarden

- Database: `db.sqlite3*` files
- Config: `config.json`
- Attachments: `attachments/` directory
- Test: Login and verify vault items accessible

### Add other services as you implement backups...
