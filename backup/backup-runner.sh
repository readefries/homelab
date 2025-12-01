#!/usr/bin/env bash
set -euo pipefail

# Optional alerting configuration (webhook URL and bearer token)
# - ALERT_WEBHOOK: URL to POST a JSON payload on failure
# - ALERT_TOKEN: optional bearer token for the webhook
ALERT_WEBHOOK=${ALERT_WEBHOOK:-}
ALERT_TOKEN=${ALERT_TOKEN:-}

# helper to send alerts (best-effort)
alert_fail() {
  local msg="$1"
  if [ -n "${ALERT_WEBHOOK}" ]; then
    # Format for Gotify API: {"title":"...", "message":"...", "priority":N}
    payload=$(jq -n --arg title "Backup Failed: ${FILEN_DEST}" --arg msg "$msg" '{title:$title,message:$msg,priority:8}')
    if [ -n "${ALERT_TOKEN}" ]; then
      # Gotify uses token as query param
      curl -sS -X POST -H "Content-Type: application/json" "${ALERT_WEBHOOK}?token=${ALERT_TOKEN}" -d "${payload}" || true
    else
      curl -sS -X POST -H "Content-Type: application/json" -d "${payload}" "${ALERT_WEBHOOK}" || true
    fi
  fi
}

# trap failures and alert
on_err() {
  rc=$?
  msg="Backup-runner failed with exit code ${rc} on target ${FILEN_DEST}"
  echo "${msg}"
  alert_fail "${msg}"
  exit ${rc}
}
trap 'on_err' ERR

# Backup runner expects these env vars:
# - TARGET_DIR (path inside container to tar, e.g. /data)
# - FILEN_DEST (remote path in Filen, e.g. /backups/vaultwarden/)
# - RETENTION_DAYS (optional, defaults to 30)

: ${TARGET_DIR:?TARGET_DIR must be set}
FILEN_DEST=${FILEN_DEST:-/backups}
RETENTION_DAYS=${RETENTION_DAYS:-30}
# Optional debug: set DEBUG=1 to print filen raw output and parsing details
DEBUG=${DEBUG:-0}
PRUNE_DRY_RUN=${PRUNE_DRY_RUN:-0}

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE=/tmp/backup-${TIMESTAMP}.tar.gz

echo "Creating backup of ${TARGET_DIR} -> ${BACKUP_FILE}"
tar -C "${TARGET_DIR}" -czf "${BACKUP_FILE}" .

# Ensure filen auth is in place.
# Prefer FILEN_AUTH_CONFIG env var (secret injected as env) to avoid mounting files into the image.
if [ -n "${FILEN_AUTH_CONFIG-}" ]; then
  mkdir -p /root/.config/filen-cli
  printf '%s' "$FILEN_AUTH_CONFIG" > /root/.config/filen-cli/.filen-cli-auth-config
  chmod 600 /root/.config/filen-cli/.filen-cli-auth-config
  echo "Wrote filen auth from env to /root/.config/filen-cli/.filen-cli-auth-config"
fi

if [ ! -f /root/.config/filen-cli/.filen-cli-auth-config ]; then
  echo "filen auth config not found at /root/.config/filen-cli/.filen-cli-auth-config; set FILEN_AUTH_CONFIG or mount secret"
  exit 1
fi

echo "Uploading to Filen: ${FILEN_DEST}"
if command -v filen >/dev/null 2>&1; then
  if [ -f "${BACKUP_FILE}" ]; then
    echo "Ensuring remote directory exists: ${FILEN_DEST}"
    if filen mkdir "${FILEN_DEST}" 2>/dev/null; then
      echo "Created remote dir with 'filen mkdir'"
    else
      echo "Could not create remote dir with known filen commands; continuing and will attempt upload (it may fail if target missing)"
    fi

    (cd /tmp && echo "Running: filen upload '${BACKUP_FILE}' '${FILEN_DEST}$(basename "${BACKUP_FILE}")'" && filen upload "${BACKUP_FILE}" "${FILEN_DEST}$(basename "${BACKUP_FILE}")") 2>&1 || {
      echo "filen upload failed; printing filen --help for debugging"
      filen --help 2>&1 || true
      echo "Upload failed"
      exit 2
    }
    echo "Uploaded with 'filen upload'"
  else
    echo "Backup file missing: ${BACKUP_FILE}"
    exit 3
  fi
else
  echo "filen CLI not found in PATH"
  exit 2
fi

echo "Upload complete, cleaning local backup"
rm -f "${BACKUP_FILE}"

if [ "${RETENTION_DAYS}" -gt 0 ]; then
  echo "Pruning backups older than ${RETENTION_DAYS} days at ${FILEN_DEST}"
  # capture both stdout and stderr because some filen versions write JSON to stderr
  json_output=$(filen list "${FILEN_DEST}" --json 2>&1 || true)

    if [ "${DEBUG}" -eq 1 ]; then
      echo "--- FILEN RAW OUTPUT START ---"
      printf '%s\n' "${json_output}"
      echo "--- FILEN RAW OUTPUT END ---"
    fi

  if [ -z "${json_output}" ]; then
    echo "No files returned by filen list; skipping pruning"
  else
    # Use a small Python helper to parse filenames and determine which
    # backups are older than RETENTION_DAYS. The helper prints one
    # remote path per line to delete (e.g. /backups/vaultwarden/backup-...)
    # Use the shipped Python helper for clarity and maintainability
    files_to_delete=$(printf '%s\n' "${json_output}" | python3 "$(dirname "$0")/checkdates.py" "${RETENTION_DAYS}" "${FILEN_DEST}" 2>/dev/null || true)

    if [ -z "${files_to_delete}" ]; then
      echo "No files to prune"
    else
      echo "${files_to_delete}" | while read -r cloudpath; do
        [ -z "${cloudpath}" ] && continue
        echo "Pruning remote file older than ${RETENTION_DAYS} days: ${cloudpath}"
          if [ "${PRUNE_DRY_RUN}" -eq 1 ]; then
            echo "DRY-RUN: would delete ${cloudpath}"
          else
            if filen rm "${cloudpath}"; then
              echo "Deleted: ${cloudpath}"
            else
              echo "Failed to delete: ${cloudpath}"
            fi
          fi
      done
    fi
  fi
fi

echo "Backup-runner done"
