#!/bin/bash
# LAB ONLY. On first start: clone the primary with pg_basebackup (-R writes standby config), then run as standby.
set -e
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  mkdir -p "$PGDATA"; chown postgres:postgres "$PGDATA"; chmod 700 "$PGDATA"
  PGPASSWORD="$REPL_PASSWORD" gosu postgres pg_basebackup -h primary -U replicator -D "$PGDATA" -R -X stream -S replica1_slot -P
fi
exec docker-entrypoint.sh postgres
