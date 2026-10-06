# LAB ONLY. Simulates accidental DELETE on the lab primary, recovers rows from the restored backup.
# Prereq: backup.ps1 + restore.ps1 already run (minelab_restored holds the known-good copy).
$ErrorActionPreference = 'Continue'
function Q($c,$db,$sql){ docker exec $c psql -h localhost -U postgres -d $db -Atc $sql }
$where = "route_id = 7"
$before = Q dbalab-primary minelab "select count(*) from fleet.haul_trip where $where"
Write-Host "1. Rows before incident ($where): $before"
Q dbalab-primary minelab "delete from fleet.haul_trip where $where" | Out-Null
Q dbalab-primary minelab "insert into admin.audit_event(action,object_name,details) values ('DRILL_DELETE','fleet.haul_trip',jsonb_build_object('filter','$where'))" | Out-Null
Write-Host "2. Incident: accidental DELETE. Rows now: $(Q dbalab-primary minelab "select count(*) from fleet.haul_trip where $where")"
# Recover: export missing rows from restored copy, load into primary
docker exec dbalab-restore psql -h localhost -U postgres -d minelab_restored -c "\copy (select * from fleet.haul_trip where $where) to '/tmp/recover.csv' csv"  | Out-Null
docker cp dbalab-restore:/tmp/recover.csv "$env:TEMP\recover.csv" | Out-Null
docker cp "$env:TEMP\recover.csv" dbalab-primary:/tmp/recover.csv | Out-Null
docker exec dbalab-primary psql -h localhost -U postgres -d minelab -c "\copy fleet.haul_trip from '/tmp/recover.csv' csv" | Out-Null
$after = Q dbalab-primary minelab "select count(*) from fleet.haul_trip where $where"
Write-Host "3. Rows after recovery: $after"
Q dbalab-primary minelab "insert into admin.audit_event(action,object_name,details) values ('DRILL_RECOVER','fleet.haul_trip',jsonb_build_object('rows',$after))" | Out-Null
if ($before -eq $after) { Write-Host "DRILL PASSED" -ForegroundColor Green } else { Write-Host "DRILL FAILED" -ForegroundColor Red }
