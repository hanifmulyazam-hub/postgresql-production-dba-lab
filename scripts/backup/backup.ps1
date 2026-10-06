# LAB ONLY. Timestamped logical backup of minelab + log line.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
New-Item -ItemType Directory -Force "$root\backups" | Out-Null
$ts   = Get-Date -Format 'yyyyMMdd_HHmmss'
$file = "minelab_$ts.dump"
$log  = "$root\backups\backup.log"
try {
  docker exec dbalab-primary pg_dump -U postgres -d minelab -Fc -f "/tmp/$file"
  if ($LASTEXITCODE -ne 0) { throw "pg_dump exit $LASTEXITCODE" }
  docker cp "dbalab-primary:/tmp/$file" "$root\backups\$file" | Out-Null
  docker exec dbalab-primary rm "/tmp/$file"
  $size = (Get-Item "$root\backups\$file").Length
  "$(Get-Date -Format o) SUCCESS $file bytes=$size" | Add-Content $log
  Get-ChildItem "$root\backups\minelab_*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 7 | Remove-Item   # retention: keep 7
  Write-Host "OK: backups\$file ($size bytes)"
} catch {
  "$(Get-Date -Format o) FAILURE $file $_" | Add-Content $log; throw
}
