# Compares row counts: primary (minelab) vs restore target (minelab_restored).
$q = "select 'truck',count(*) from fleet.truck union all select 'route',count(*) from fleet.route union all select 'operator',count(*) from fleet.operator union all select 'haul_trip',count(*) from fleet.haul_trip union all select 'audit_event',count(*) from admin.audit_event order by 1"
$a = docker exec dbalab-primary psql -U postgres -d minelab -Atc $q
$b = docker exec dbalab-restore psql -U postgres -d minelab_restored -Atc $q
"PRIMARY:`n$($a -join "`n")`nRESTORED:`n$($b -join "`n")"
if (($a -join ',') -eq ($b -join ',')) { Write-Host "VALIDATION PASSED" -ForegroundColor Green } else { Write-Host "VALIDATION FAILED" -ForegroundColor Red; exit 1 }
