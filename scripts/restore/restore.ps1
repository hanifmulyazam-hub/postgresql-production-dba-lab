# LAB ONLY. Restores a dump into the ISOLATED dbalab-restore instance (never the primary).
param([string]$File)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
if (-not $File) { $File = (Get-ChildItem "$root\backups\*.dump" | Sort-Object LastWriteTime | Select-Object -Last 1).FullName }
Write-Host "Restoring $File into dbalab-restore / minelab_restored"
$ErrorActionPreference = 'Continue'   # docker writes progress to stderr
docker compose -f "$root\docker\docker-compose.yml" up -d restore 2>&1 | Out-Null
# wait for the real server (TCP), not the temporary init server
do { Start-Sleep 2; docker exec dbalab-restore psql -h localhost -U postgres -c "select 1" 2>&1 | Out-Null } until ($LASTEXITCODE -eq 0)
$ErrorActionPreference = 'Stop'
docker cp $File dbalab-restore:/tmp/r.dump | Out-Null
docker exec dbalab-restore psql -U postgres -c "DROP DATABASE IF EXISTS minelab_restored" -c "CREATE DATABASE minelab_restored" | Out-Null
docker exec dbalab-restore pg_restore -U postgres -d minelab_restored --no-owner /tmp/r.dump
Write-Host "Restore finished. Validate with scripts\restore\validate.ps1"
