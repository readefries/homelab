#!/usr/bin/env bash
# Restore backup to a copy PVC for safe verification before production restore
# Usage: ./restore-to-copy.sh <namespace> <backup-file> [pvc-size]
# Example: ./restore-to-copy.sh vaultwarden /backups/vaultwarden/backup-20251201-030000.tar.gz 10Gi

set -euo pipefail

NAMESPACE=${1:-}
BACKUP_FILE=${2:-}
PVC_SIZE=${3:-10Gi}

if [ -z "$NAMESPACE" ] || [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <namespace> <backup-file> [pvc-size]"
  echo "Example: $0 vaultwarden /backups/vaultwarden/backup-20251201-030000.tar.gz 10Gi"
  exit 1
fi

SERVICE_NAME=$(echo "$NAMESPACE" | cut -d'-' -f1)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESTORE_PVC="${SERVICE_NAME}-data-restore-${TIMESTAMP}"
RESTORE_JOB="${SERVICE_NAME}-restore-job-${TIMESTAMP}"
VERIFY_DEPLOY="${SERVICE_NAME}-restore-verify-${TIMESTAMP}"

echo "=== Restore to Copy for ${NAMESPACE} ==="
echo "Backup file: ${BACKUP_FILE}"
echo "PVC size: ${PVC_SIZE}"
echo "Restore PVC: ${RESTORE_PVC}"
echo ""

# Check namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "ERROR: Cannot access namespace ${NAMESPACE}"
  exit 1
fi

# Create temporary PVC
echo "Step 1/4: Creating temporary PVC..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${RESTORE_PVC}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: restore-copy
    app.kubernetes.io/instance: ${TIMESTAMP}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PVC_SIZE}
EOF

echo "✓ PVC created: ${RESTORE_PVC}"
echo ""

# Create restore job
echo "Step 2/4: Creating restore job..."
kubectl apply -n "${NAMESPACE}" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${RESTORE_JOB}
  labels:
    app.kubernetes.io/name: restore-copy
    app.kubernetes.io/instance: ${TIMESTAMP}
spec:
  backoffLimit: 1
  ttlSecondsAfterFinished: 3600
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
          
          echo "=== Starting Restore to Copy ==="
          echo "Backup: ${BACKUP_FILE}"
          echo "Target: /restore"
          echo ""
          # Prepare Filen auth from env secret for CLI
          if [ -n "\${FILEN_AUTH_CONFIG-}" ]; then
            mkdir -p /root/.config/filen-cli
            printf '%s' "\$FILEN_AUTH_CONFIG" > /root/.config/filen-cli/.filen-cli-auth-config
            chmod 600 /root/.config/filen-cli/.filen-cli-auth-config
            echo "Wrote filen auth from env to /root/.config/filen-cli/.filen-cli-auth-config"
          else
            echo "ERROR: FILEN_AUTH_CONFIG not set; ensure secret is mounted"
            exit 1
          fi
          
          echo "Downloading backup from Filen..."
          if filen download "${BACKUP_FILE}" /tmp/backup.tar.gz; then
            size=\$(stat -f%z /tmp/backup.tar.gz 2>/dev/null || stat -c%s /tmp/backup.tar.gz)
            echo "✓ Downloaded: \$(numfmt --to=iec \$size 2>/dev/null || echo \$size bytes)"
          else
            echo "✗ Download failed"
            exit 1
          fi
          
          echo ""
          echo "Verifying archive integrity..."
          if tar -tzf /tmp/backup.tar.gz >/dev/null 2>&1; then
            file_count=\$(tar -tzf /tmp/backup.tar.gz | wc -l)
            echo "✓ Archive is valid (\$file_count files)"
          else
            echo "✗ Archive is corrupted!"
            exit 1
          fi
          
          echo ""
          echo "Extracting backup to /restore..."
          cd /restore
          if tar -xzf /tmp/backup.tar.gz; then
            echo "✓ Extraction complete"
          else
            echo "✗ Extraction failed"
            exit 1
          fi
          
          echo ""
          echo "Restored data summary:"
          du -sh /restore
          ls -lah /restore | head -20
          
          echo ""
          echo "╔═══════════════════════════════════════╗"
          echo "║  ✓ RESTORE TO COPY COMPLETE         ║"
          echo "╚═══════════════════════════════════════╝"
          echo ""
          echo "Data has been restored to: ${RESTORE_PVC}"
          echo "Next: Deploy verification pod to inspect the data"
        env:
        - name: FILEN_AUTH_CONFIG
          valueFrom:
            secretKeyRef:
              name: filen-auth
              key: ".filen-cli-auth-config"
        volumeMounts:
        - name: restore-data
          mountPath: /restore
      volumes:
      - name: restore-data
        persistentVolumeClaim:
          claimName: ${RESTORE_PVC}
EOF

echo "✓ Restore job created: ${RESTORE_JOB}"
echo ""

# Wait for job to complete
echo "Step 3/4: Waiting for restore to complete..."
if kubectl wait --for=condition=complete --timeout=600s "job/${RESTORE_JOB}" -n "${NAMESPACE}" 2>/dev/null; then
  echo "✓ Restore completed successfully"
else
  echo "✗ Restore job failed or timed out"
  echo ""
  echo "Check logs with:"
  echo "  kubectl -n ${NAMESPACE} logs job/${RESTORE_JOB}"
  exit 1
fi

echo ""
kubectl logs "job/${RESTORE_JOB}" -n "${NAMESPACE}" | tail -30
echo ""

# Create verification deployment
echo "Step 4/4: Creating verification pod..."

# Determine the appropriate image based on service
case "$SERVICE_NAME" in
  vaultwarden)
    VERIFY_IMAGE="vaultwarden/server:latest"
    VERIFY_CMD='["sleep", "infinity"]'
    ;;
  *)
    VERIFY_IMAGE="ubuntu:24.04"
    VERIFY_CMD='["sleep", "infinity"]'
    ;;
esac

kubectl apply -n "${NAMESPACE}" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${VERIFY_DEPLOY}
  labels:
    app.kubernetes.io/name: restore-verify
    app.kubernetes.io/instance: ${TIMESTAMP}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${VERIFY_DEPLOY}
  template:
    metadata:
      labels:
        app: ${VERIFY_DEPLOY}
    spec:
      containers:
      - name: verify
        image: ${VERIFY_IMAGE}
        command: ${VERIFY_CMD}
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
          claimName: ${RESTORE_PVC}
EOF

echo "✓ Verification deployment created: ${VERIFY_DEPLOY}"
echo ""

# Wait for pod to be ready
echo "Waiting for verification pod to be ready..."
kubectl -n "${NAMESPACE}" wait --for=condition=ready --timeout=60s pod -l app="${VERIFY_DEPLOY}" 2>/dev/null || {
  echo "Warning: Pod is taking longer than expected to start"
}

POD_NAME=$(kubectl -n "${NAMESPACE}" get pod -l app="${VERIFY_DEPLOY}" -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✓✓✓ RESTORE TO COPY COMPLETED SUCCESSFULLY ✓✓✓          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Resources created:"
echo "  • PVC: ${RESTORE_PVC}"
echo "  • Job: ${RESTORE_JOB}"
echo "  • Verification Pod: ${POD_NAME}"
echo ""
echo "Next steps:"
echo ""
echo "1. Inspect the restored data:"
echo "   kubectl -n ${NAMESPACE} exec -it ${POD_NAME} -- /bin/bash"
echo ""
echo "   Inside the pod:"
echo "     cd /data"
echo "     ls -lah"

if [ "$SERVICE_NAME" = "vaultwarden" ]; then
  echo "     sqlite3 db.sqlite3 'SELECT COUNT(*) FROM users;'"
  echo "     sqlite3 db.sqlite3 'PRAGMA integrity_check;'"
fi

echo ""
echo "2. If data looks good, copy to production:"
echo "   # Scale down production"
echo "   kubectl -n ${NAMESPACE} scale deployment ${SERVICE_NAME} --replicas=0"
echo ""
echo "   # Get production PVC name"
echo "   PROD_PVC=\$(kubectl -n ${NAMESPACE} get deployment ${SERVICE_NAME} -o jsonpath='{.spec.template.spec.volumes[?(@.persistentVolumeClaim)].persistentVolumeClaim.claimName}')"
echo ""
echo "   # Copy data (create helper script or use rsync pod)"
echo "   # See RESTORE.md for detailed instructions"
echo ""
echo "3. Clean up test resources:"
echo "   kubectl -n ${NAMESPACE} delete deployment ${VERIFY_DEPLOY}"
echo "   kubectl -n ${NAMESPACE} delete job ${RESTORE_JOB}"
echo "   kubectl -n ${NAMESPACE} delete pvc ${RESTORE_PVC}"
echo ""
echo "Or run:"
echo "  ./cleanup-restore-copy.sh ${NAMESPACE} ${TIMESTAMP}"
echo ""
