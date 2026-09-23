# Elasticsearch Migration (v7.17 to v9.5)

Starting with **NOMAD 2.0**, NOMAD Oasis has migrated its search backend from **Elasticsearch 7** to **Elasticsearch 9** (default container version `9.5.0`).

Because Elasticsearch 9 cannot read indices created with Elasticsearch 7 due to major Lucene version changes, existing data cannot be read directly from the old Elasticsearch 7 volume.

There are two migration options available:
1. **Option 1: Reindex data from ES7 to ES9 (Running two containers)** — Runs an ES9 container alongside ES7 and migrates index data directly via Elasticsearch's `_reindex` API without reprocessing archive files.
2. **Option 2: Start from a fresh ES9 container and reindex uploads** — In NOMAD, MongoDB and the archive files (`.volumes/fs`) are the single source of truth. This option starts with a clean ES9 container and rebuilds the search index by reindexing uploads.

> [!NOTE]
> Previously, NOMAD maintained a separate materials index (`nomad_materials_v1` / `nomad_oasis_materials_v1`). This index is deprecated and dropped in NOMAD 2.0. **Only the entries index (`nomad_oasis_entries_v1` or `nomad_entries_v1`) needs to be migrated.**

---

## Option 1: Reindex data from ES7 to ES9 (Running two containers)

This approach runs a temporary Elasticsearch 9 container alongside your existing Elasticsearch 7 container, copies over the index mappings, and streams documents over the Docker network using Elasticsearch's remote `_reindex` API.

### 1. Add the Temporary `nomad_oasis_elastic_9` Service

Add the `nomad_oasis_elastic_9` service and volume to your `docker-compose.yaml` (while keeping your existing `elastic` 7.x service running):

```yaml
services:
  # ... existing services ...

  nomad_oasis_elastic_9:
    restart: "no"
    image: docker.elastic.co/elasticsearch/elasticsearch:9.5.0
    container_name: nomad_oasis_elastic_9
    environment:
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
      - cluster.routing.allocation.disk.threshold_enabled=true
      - cluster.routing.allocation.disk.watermark.flood_stage=1gb
      - cluster.routing.allocation.disk.watermark.low=4gb
      - cluster.routing.allocation.disk.watermark.high=2gb
      - discovery.type=single-node
      - xpack.security.enabled=false
      - reindex.remote.whitelist=elastic:9200
    ports:
      - "9201:9200"
    volumes:
      - nomad_oasis_elastic_9:/usr/share/elasticsearch/data

volumes:
  # ... existing volumes ...
  nomad_oasis_elastic_9:
    name: "nomad_oasis_elastic_9"
```

Start the temporary ES9 container:

```bash
docker compose up -d nomad_oasis_elastic_9
```

Wait until ES9 is healthy and responding on port 9201:

```bash
curl -fsS http://localhost:9201
```

### 2. Copy Mapping and Create Index in ES9

Export the settings and mappings from ES7 (port 9200) and create the new index in ES9 (port 9201).

> [!NOTE]
> Check `configs/nomad.yaml` for your configured `entries_index`. In standard Oasis deployments it is `nomad_oasis_entries_v1`; if unset or default NOMAD is used, it is `nomad_entries_v1`.

```bash
# Set your entries index name:
INDEX="nomad_oasis_entries_v1"

# 1. Fetch settings and mapping from ES7
curl -fsS "http://localhost:9200/${INDEX}/_settings?flat_settings=false" > "/tmp/${INDEX}-settings.json"
curl -fsS "http://localhost:9200/${INDEX}/_mapping" > "/tmp/${INDEX}-mapping.json"

# 2. Create the index on ES9 with replica count set to 0 and matching analysis settings
jq -n \
  --arg index "$INDEX" \
  --slurpfile settings "/tmp/${INDEX}-settings.json" \
  --slurpfile mapping "/tmp/${INDEX}-mapping.json" \
  '{
    settings: {
      number_of_replicas: 0,
      analysis: ($settings[0][$index].settings.index.analysis // {})
    },
    mappings: $mapping[0][$index].mappings
  }' | \
  curl -fsS -X PUT "http://localhost:9201/${INDEX}" \
    -H 'Content-Type: application/json' \
    --data-binary @-

echo "Created ${INDEX} on ES9"
```

### 3. Reindex from ES7 to ES9

Trigger the remote reindex from the ES7 container (`http://elastic:9200`) into ES9:

```bash
jq -n \
  --arg index "$INDEX" \
  '{
    source: {
      remote: {host: "http://elastic:9200"},
      index: $index,
      size: 100
    },
    dest: {index: $index}
  }' | \
  curl -fsS -X POST \
    "http://localhost:9201/_reindex?wait_for_completion=true&refresh=true" \
    -H 'Content-Type: application/json' \
    --data-binary @- | jq .
```

### 4. Verify Document Counts

Verify that the document count in ES9 matches ES7:

```bash
echo "ES7 count:"
curl -fsS "http://localhost:9200/${INDEX}/_count" | jq .

echo "ES9 count:"
curl -fsS "http://localhost:9201/${INDEX}/_count" | jq .

echo "ES9 mapping property count:"
curl -fsS "http://localhost:9201/${INDEX}/_mapping" | \
  jq 'to_entries[0].value.mappings.properties | length'
```

### 5. Finalize the Migration

Once verified:

1. Stop the running containers:
   ```bash
   docker compose down
   ```

2. Update `docker-compose.yaml`:
   - Set the main `elastic` service image to `docker.elastic.co/elasticsearch/elasticsearch:9.5.0`.
   - Change the volume mount for `elastic` to use the migrated volume `nomad_oasis_elastic_9` (or replace the old volume).
   - Ensure `NOMAD_ELASTIC_VERSION: 9` is present in your Nomad services (`app`, `worker`, etc.).
   - Remove the temporary `nomad_oasis_elastic_9` service definition from `docker-compose.yaml`.

3. Start your upgraded NOMAD Oasis:
   ```bash
   docker compose up -d
   ```

4. Remove the old ES7 volume if no longer needed:
   ```bash
   docker volume rm nomad_oasis_elastic
   ```

---

## Option 2: Start from a fresh ES9 container and reindex uploads

In NOMAD, **MongoDB and the archive files (`.volumes/fs`) are the single source of truth**. This option wipes the Elasticsearch volume, starts a fresh Elasticsearch 9 container, and reindexes all uploads from MongoDB and archive storage.

### 1. Back Up MongoDB and File Storage

Before proceeding, run a MongoDB backup:

```bash
bash scripts/backup-mongo.sh
```

Ensure `.volumes/fs` is intact.

### 2. Update Compose File

In `docker-compose.yaml`:
- Set `image: docker.elastic.co/elasticsearch/elasticsearch:9.5.0` under the `elastic` service.
- Ensure `NOMAD_ELASTIC_VERSION: 9` is set under the Nomad container environment (`app`, `worker`, etc.).

### 3. Clear Old Elasticsearch Volume and Start Services

```bash
# 1. Stop all containers
docker compose down

# 2. Remove the old Elasticsearch 7 volume
docker volume rm nomad_oasis_elastic

# 3. Start the upgraded stack
docker compose up -d
```

### 4. Run the Indexing CLI Command

Wait until `app` and `elastic` are healthy, then trigger re-indexing across all uploads:

```bash
docker compose exec app python -m nomad.cli admin uploads index --parallel 4
```

> [!TIP]
> You can increase `--parallel` based on available CPU cores. For large deployments, add `--print-progress 10` to monitor ongoing progress.
