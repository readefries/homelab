#!/usr/bin/env bash
# Deploy Photos (Ente + PostgreSQL + MinIO) to k3s cluster

set -euo pipefail

REMOTE_HOST=${REMOTE_HOST:-root@mnemonic.xs4some.nl}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/k8s/secrets.yaml"

if [[ ! -f "${SECRETS_FILE}" ]]; then
  echo "ERROR: Missing ${SECRETS_FILE}"
  echo "Create it from k8s/secrets.example.yaml and try again."
  exit 1
fi

echo "Deploying Photos to ${REMOTE_HOST}"

echo "Copying manifests..."
ssh "${REMOTE_HOST}" "mkdir -p /tmp/photos-deploy"
scp -r "${SCRIPT_DIR}/k8s/"* "${REMOTE_HOST}:/tmp/photos-deploy/"

echo "Applying base manifests..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/photos-deploy/namespace.yaml"

echo "Applying secrets..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/photos-deploy/secrets.yaml"

echo "Applying storage..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/photos-deploy/pvc.yaml"

echo "Applying workloads..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/photos-deploy/postgresql.yaml && \
  kubectl apply -f /tmp/photos-deploy/minio.yaml && \
  kubectl apply -f /tmp/photos-deploy/ente.yaml && \
  kubectl apply -f /tmp/photos-deploy/ingress.yaml && \
  kubectl apply -f /tmp/photos-deploy/minio-ingress.yaml"

echo "Applying backup jobs (optional filen-auth secret required)..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl apply -f /tmp/photos-deploy/postgres-backup-cronjob.yaml && \
  kubectl apply -f /tmp/photos-deploy/minio-backup-cronjob.yaml"

echo "Waiting for deployments..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl wait --for=condition=available --timeout=180s deployment/photos-postgresql -n photos && \
  kubectl wait --for=condition=available --timeout=180s deployment/photos-minio -n photos"

echo "Ensuring PostgreSQL database exists for Ente..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  PGPASS=\
\$(kubectl get secret -n photos photos-postgresql-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d) && \
  DBNAME=\
\$(kubectl get secret -n photos photos-postgresql-secret -o jsonpath='{.data.POSTGRES_DB}' | base64 -d) && \
  DBUSER=\
\$(kubectl get secret -n photos photos-postgresql-secret -o jsonpath='{.data.POSTGRES_USER}' | base64 -d) && \
  kubectl exec -n photos deployment/photos-postgresql -- sh -lc \"export PGPASSWORD=\\\"\$PGPASS\\\"; psql -h 127.0.0.1 -U \\\"\$DBUSER\\\" -d postgres -tc \\\"SELECT 1 FROM pg_database WHERE datname='\\\"\$DBNAME\\\"';\\\" | grep -q 1 || psql -h 127.0.0.1 -U \\\"\$DBUSER\\\" -d postgres -v ON_ERROR_STOP=1 -c \\\"CREATE DATABASE \\\\\\\"\$DBNAME\\\\\\\" OWNER \\\\\\\"\$DBUSER\\\\\\\";\\\"\""

echo "Restarting Ente after DB check..."
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
  kubectl rollout restart deployment/photos-ente -n photos && \
  kubectl rollout status deployment/photos-ente -n photos --timeout=180s"

echo "Status:"
ssh "${REMOTE_HOST}" "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get all,ingress,pvc,cronjob -n photos"

echo "Done. Verify Ente image/env compatibility in k8s/ente.yaml before production use."

ssh "${REMOTE_HOST}" "rm -rf /tmp/photos-deploy"
