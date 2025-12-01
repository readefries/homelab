#!/usr/bin/env bash
# Restore test script - validates that backups can be downloaded and extracted
# Usage: ./test-restore.sh <namespace> <backup-path>
# Example: ./test-restore.sh vaultwarden /backups/vaultwarden/

set -euo pipefail

NAMESPACE=${1:-}
BACKUP_PATH=${2:-}

if [ -z "$NAMESPACE" ] || [ -z "$BACKUP_PATH" ]; then
  echo "Usage: $0 <namespace> <backup-path>"
  echo "Example: $0 vaultwarden /backups/vaultwarden/"
  exit 1
fi

JOB_NAME="${NAMESPACE}-restore-test"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=== Backup Restore Test for ${NAMESPACE} ==="
echo "Backup path: ${BACKUP_PATH}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Check if kubectl and context work
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "ERROR: Cannot access namespace ${NAMESPACE}"
  exit 1
fi

echo "Creating restore test job..."

kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: ${NAMESPACE}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 3600
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
          
          echo "=== Starting Restore Test ==="
          echo "Finding latest backup in ${BACKUP_PATH}..."
          
          # List backups
          filen list "${BACKUP_PATH}" --json > /tmp/backups.json || {
            echo "ERROR: Failed to list backups at ${BACKUP_PATH}"
            exit 1
          }
          
          # Find latest backup file
          latest_backup=\$(python3 -c "
          import sys, json
          try:
              with open('/tmp/backups.json') as f:
                  files = json.load(f)
              backups = [f for f in files if f.get('type') == 'file' and 'backup-' in f.get('name', '')]
              if not backups:
                  print('', file=sys.stderr)
                  sys.exit(1)
              latest = sorted(backups, key=lambda x: x.get('name', ''), reverse=True)[0]
              print(latest['name'])
          except Exception as e:
              print(f'Error: {e}', file=sys.stderr)
              sys.exit(1)
          " 2>&1)
          
          if [ -z "\$latest_backup" ]; then
            echo "ERROR: No backup files found in ${BACKUP_PATH}"
            echo "Available files:"
            cat /tmp/backups.json | python3 -m json.tool || cat /tmp/backups.json
            exit 1
          fi
          
          backup_file="${BACKUP_PATH}\$latest_backup"
          echo "✓ Found latest backup: \$latest_backup"
          
          # Download backup
          echo ""
          echo "Downloading backup..."
          if filen download "\$backup_file" /tmp/test-restore.tar.gz; then
            echo "✓ Download successful"
          else
            echo "✗ Download failed"
            exit 1
          fi
          
          # Check file size
          size=\$(stat -f%z /tmp/test-restore.tar.gz 2>/dev/null || stat -c%s /tmp/test-restore.tar.gz)
          echo "  Backup size: \$(numfmt --to=iec \$size 2>/dev/null || echo \$size bytes)"
          
          # Verify archive integrity
          echo ""
          echo "Verifying archive integrity..."
          if tar -tzf /tmp/test-restore.tar.gz >/dev/null 2>&1; then
            echo "✓ Archive is valid"
          else
            echo "✗ Archive is corrupted or invalid!"
            exit 1
          fi
          
          # Count files in archive
          file_count=\$(tar -tzf /tmp/test-restore.tar.gz | wc -l)
          echo "  Files in archive: \$file_count"
          
          # Extract to temp location
          echo ""
          echo "Testing extraction..."
          mkdir -p /tmp/test-extract
          cd /tmp/test-extract
          if tar -xzf /tmp/test-restore.tar.gz; then
            echo "✓ Extraction successful"
          else
            echo "✗ Extraction failed"
            exit 1
          fi
          
          # List top-level contents
          echo ""
          echo "Top-level contents of backup:"
          ls -lh /tmp/test-extract/ | head -20
          
          # Calculate total size
          total_size=\$(du -sh /tmp/test-extract 2>/dev/null | cut -f1)
          echo ""
          echo "  Total extracted size: \$total_size"
          
          # Service-specific validation
          echo ""
          echo "Performing service-specific checks..."
          
          # Vaultwarden checks
          if [ -f /tmp/test-extract/db.sqlite3 ]; then
            echo "✓ Found vaultwarden database: db.sqlite3"
            if command -v sqlite3 >/dev/null 2>&1; then
              if sqlite3 /tmp/test-extract/db.sqlite3 "PRAGMA integrity_check;" | grep -q "ok"; then
                echo "  ✓ Database integrity check passed"
              else
                echo "  ⚠ Database integrity check failed"
              fi
            fi
          fi
          
          if [ -f /tmp/test-extract/config.json ]; then
            echo "✓ Found config.json"
          fi
          
          if [ -d /tmp/test-extract/attachments ]; then
            attachment_count=\$(find /tmp/test-extract/attachments -type f 2>/dev/null | wc -l || echo 0)
            echo "✓ Found attachments directory (\$attachment_count files)"
          fi
          
          # Generic file checks
          if [ -f /tmp/test-extract/*.db ] || [ -f /tmp/test-extract/db.* ]; then
            echo "✓ Found database file(s)"
          fi
          
          # Cleanup
          echo ""
          echo "Cleaning up test files..."
          rm -rf /tmp/test-extract /tmp/test-restore.tar.gz /tmp/backups.json
          
          echo ""
          echo "╔═══════════════════════════════════════╗"
          echo "║  ✓✓✓ RESTORE TEST PASSED ✓✓✓        ║"
          echo "╚═══════════════════════════════════════╝"
          echo ""
          echo "Summary:"
          echo "  - Backup: \$latest_backup"
          echo "  - Files: \$file_count"
          echo "  - Size: \$total_size"
          echo ""
          echo "The backup can be successfully:"
          echo "  1. Downloaded from Filen"
          echo "  2. Verified as valid tar.gz"
          echo "  3. Extracted completely"
          echo ""
          echo "✓ Ready for production restore if needed"
        env:
        - name: FILEN_AUTH_CONFIG
          valueFrom:
            secretKeyRef:
              name: filen-auth
              key: .filen-cli-auth-config
EOF

echo ""
echo "Job created. Waiting for completion..."
echo ""

# Wait for job to complete
kubectl wait --for=condition=complete --timeout=300s "job/${JOB_NAME}" -n "${NAMESPACE}" 2>/dev/null || {
  echo "Job did not complete successfully. Checking status..."
  kubectl get job "${JOB_NAME}" -n "${NAMESPACE}"
}

echo ""
echo "=== Job Logs ==="
kubectl logs "job/${JOB_NAME}" -n "${NAMESPACE}"

# Check if successful
if kubectl get job "${JOB_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.succeeded}' | grep -q "1"; then
  echo ""
  echo "✓ Restore test completed successfully!"
  EXIT_CODE=0
else
  echo ""
  echo "✗ Restore test failed!"
  EXIT_CODE=1
fi

# Cleanup
echo ""
read -p "Delete test job? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
  kubectl delete job "${JOB_NAME}" -n "${NAMESPACE}"
  echo "Test job deleted."
fi

exit $EXIT_CODE
