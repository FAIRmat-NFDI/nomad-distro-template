#!/bin/sh
set -e

# Helper for DB setup
setup_db() {
    echo "Starting PostgreSQL schema setup..."
    nc -z -w 10 ${POSTGRES_SEEDS} ${DB_PORT:-5432}

    # Setup Main DB
    temporal-sql-tool --plugin postgres12 --ep ${POSTGRES_SEEDS} -u ${POSTGRES_USER} -p ${DB_PORT:-5432} --db temporal create || true
    temporal-sql-tool --plugin postgres12 --ep ${POSTGRES_SEEDS} -u ${POSTGRES_USER} -p ${DB_PORT:-5432} --db temporal setup-schema -v 0.0
    temporal-sql-tool --plugin postgres12 --ep ${POSTGRES_SEEDS} -u ${POSTGRES_USER} -p ${DB_PORT:-5432} --db temporal update-schema -d /etc/temporal/schema/postgresql/v12/temporal/versioned

    # Setup Visibility DB
    temporal-sql-tool --plugin postgres12 --ep ${POSTGRES_SEEDS} -u ${POSTGRES_USER} -p ${DB_PORT:-5432} --db temporal_visibility create || true
    temporal-sql-tool --plugin postgres12 --ep ${POSTGRES_SEEDS} -u ${POSTGRES_USER} -p ${DB_PORT:-5432} --db temporal_visibility setup-schema -v 0.0
    temporal-sql-tool --plugin postgres12 --ep ${POSTGRES_SEEDS} -u ${POSTGRES_USER} -p ${DB_PORT:-5432} --db temporal_visibility update-schema -d /etc/temporal/schema/postgresql/v12/visibility/versioned
    echo "DB setup complete."
}

# Helper for Namespace creation
create_namespace() {
    NAMESPACE=${DEFAULT_NAMESPACE:-default}
    echo "Waiting for Temporal server at $TEMPORAL_ADDRESS..."

    until temporal operator cluster health --address $TEMPORAL_ADDRESS; do
      echo "Server not ready yet, waiting..."
      sleep 2
    done

    temporal operator namespace describe -n $NAMESPACE --address $TEMPORAL_ADDRESS || \
    temporal operator namespace create -n $NAMESPACE --address $TEMPORAL_ADDRESS
    echo "Namespace '$NAMESPACE' ready."
}

# Select mode based on the first argument
case "$1" in
    "setup_db")
        setup_db
        ;;
    "create_namespace")
        create_namespace
        ;;
    *)
        echo "Usage: $0 {db|namespace}"
        exit 1
        ;;
esac
