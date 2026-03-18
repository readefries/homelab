# Photos (Ente)

This stack creates a dedicated `photos` workload:
- PostgreSQL for metadata
- MinIO for object storage
- Ente API/web workload
- Ingress with TLS on `photos.xs4some.nl`
- Filen backup CronJobs for postgres + minio data

## Files
- `k8s/namespace.yaml`
- `k8s/pvc.yaml`
- `k8s/postgresql.yaml`
- `k8s/minio.yaml`
- `k8s/minio-ingress.yaml`
- `k8s/ente.yaml`
- `k8s/ingress.yaml`
- `k8s/secrets.yaml` (local, gitignored)
- `k8s/secrets.example.yaml`
- `k8s/postgres-backup-cronjob.yaml`
- `k8s/minio-backup-cronjob.yaml`

## 1) Create secrets file

Create a local secrets file from the example:

```bash
cp k8s/secrets.example.yaml k8s/secrets.yaml
```

Edit `k8s/secrets.yaml` and replace all `CHANGE_ME...` values with strong random values.

The deploy script applies this file automatically.

## 2) Optional: filen-auth secret for backups

If you use Filen backups, create this once:

```bash
kubectl -n photos create secret generic filen-auth \
  --from-file=.filen-cli-auth-config=/path/to/.filen-cli-auth-config
```

## 3) Deploy

```bash
chmod +x ./deploy.sh
./deploy.sh
```

The deploy script now also ensures the PostgreSQL database from `photos-postgresql-secret`
exists before finalizing the Ente rollout.

Uploads are signed against `s3.photos.xs4some.nl` (see `k8s/minio-ingress.yaml` and
`k8s/ente.yaml`). This host must resolve publicly to your cluster ingress.

Current deployment sets `ENTE_S3_ARE_LOCAL_BUCKETS=true`, so signed URLs use HTTP semantics.
This avoids upload failures while cert-manager TLS for `s3.photos.xs4some.nl` is still pending.

The Ente deployment also has startup hardening:
- init containers wait for PostgreSQL and MinIO before Ente starts
- startup/readiness/liveness probes on port 8080

## 4) Important note

The Ente image/env contract can change. Before production rollout, verify `k8s/ente.yaml` against the current Ente self-host documentation and adjust image/env keys accordingly.

If uploads fail with `MissingRegion`, ensure the Ente deployment keeps explicit S3 region
settings (`ENTE_S3_REGION`, `AWS_REGION`, and `AWS_DEFAULT_REGION`).

If uploads fail with `PutObjectInput.Bucket` validation errors, this Ente image expects
Museum-style S3 env keys (`ENTE_S3_B2_EU_CEN_*`) to be set. The deployment maps these to
your existing secret values.

If uploads fail slowly (timeouts/retries), verify the client can resolve and reach
`https://s3.photos.xs4some.nl`.

## 5) Next step for dad

Copy this folder to `photos-dad/` and change:
- namespace
- host/domain
- secret names and values
- Filen destination paths
- storage sizes/schedules

This keeps both systems fully separated.

## 6) Disable free plan limit (Ente CLI)

Use the Ente CLI against your self-hosted API endpoint.

1. Add your admin account in CLI (uses your self-host endpoint):

```bash
ente account add --app photos --endpoint https://photos.xs4some.nl --email <admin-email>
```

2. Verify the account is present:

```bash
ente account list
```

3. Set unlimited storage + long validity for a user:

```bash
ente admin update-subscription -a <admin-email> -u <target-user-email> --no-limit
```

Notes:
- `<admin-email>` must be an Ente admin user.
- `<target-user-email>` must be a registered and verified user on this instance.
- If needed, a finite limit can be set with:

```bash
ente admin update-subscription -a <admin-email> -u <target-user-email> --no-limit False
```
