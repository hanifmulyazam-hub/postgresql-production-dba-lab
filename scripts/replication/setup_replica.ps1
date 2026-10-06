# LAB ONLY. Turns the lab primary into a replication source and starts a streaming standby on port 5434.
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Get-Content "$root\sql\replication\01_primary_setup.sql" | docker exec -i dbalab-primary psql -h localhost -U postgres -d minelab -f -
# allow replication connections (idempotent), then reload
docker exec dbalab-primary bash -c "grep -q 'replicator' `$PGDATA/pg_hba.conf || echo 'host replication replicator all scram-sha-256' >> `$PGDATA/pg_hba.conf"
docker exec dbalab-primary psql -h localhost -U postgres -c "select pg_reload_conf()"
docker compose -f "$root\docker\docker-compose.yml" up -d replica 2>&1 | Out-Null
do { Start-Sleep 3; docker exec dbalab-replica psql -h localhost -U postgres -c "select 1" 2>&1 | Out-Null } until ($LASTEXITCODE -eq 0)
Write-Host "Replica up. Check with scripts\replication\check_replication.ps1"
