# MongoDB Migration (v5.0.6 to v8.x)

Starting with NOMAD Oasis template **v1.4.2**, the MongoDB container image was migrated from version `5.0.6` to version `8.x` (`docker.io/mongo:8.0`).

MongoDB requires sequential upgrades through major versions (`5.0` → `6.0` → `7.0` → `8.0`) with `featureCompatibilityVersion` updated at each stage. You cannot directly mount a MongoDB 5.x data directory into a MongoDB 8.x container.

---

## Prerequisites

- Python >= 3.8 installed on the Docker host machine.
- Sufficient disk space for backups.
- Ensure your existing NOMAD Oasis MongoDB container is running and healthy before starting.

---

## Migration Steps

### 1. Back up your existing MongoDB data

Before running any migration, ensure you have a verified backup of your MongoDB database.

You can use the helper backup script included in this repository:

```bash
bash scripts/backup-mongo.sh
```

Confirm that the backup dump was created in `.volumes/mongo`:

```bash
ls -lh .volumes/mongo
cat .volumes/mongo/backup.log
```

> [!IMPORTANT]
> Always verify that your backup files exist and are non-empty before proceeding.

### 2. Download and Run the Sequential Upgrade Script

FAIRmat provides an automated helper script that sequentially upgrades MongoDB across intermediate major versions (5 → 6 → 7 → 8), setting the appropriate `featureCompatibilityVersion` at each step:

```bash
curl -O https://gitlab.mpcdf.mpg.de/nomad-lab/nomad-FAIR/-/snippets/188/raw/main/upgrade_mongo.py
python3 upgrade_mongo.py -c nomad_oasis_mongo -f docker-compose.yaml --from-version 5.0.6
```

### 3. Verify the Upgrade

1. Check that the MongoDB container is running the new version:
   ```bash
   docker compose exec mongo mongosh --eval 'db.version()'
   ```
2. Verify that the feature compatibility version is set to 8.0:
   ```bash
   docker compose exec mongo mongosh --eval 'db.adminCommand({getParameter: 1, featureCompatibilityVersion: 1})'
   ```
3. Check the NOMAD Oasis logs to ensure the services connect properly:
   ```bash
   docker compose logs -f app worker
   ```
