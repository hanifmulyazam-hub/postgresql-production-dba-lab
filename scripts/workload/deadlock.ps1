# LAB ONLY. Reproduces a deadlock: A locks row 1 then 2; B locks row 2 then 1.
$psql = @('exec','dbalab-primary','psql','-h','localhost','-U','postgres','-d','minelab')
$a = Start-Job { param($p) docker @p -c "BEGIN; UPDATE fleet.truck SET status=status WHERE truck_id=1; SELECT pg_sleep(3); UPDATE fleet.truck SET status=status WHERE truck_id=2; COMMIT;" 2>&1 } -ArgumentList (,$psql)
$b = Start-Job { param($p) docker @p -c "BEGIN; UPDATE fleet.truck SET status=status WHERE truck_id=2; SELECT pg_sleep(3); UPDATE fleet.truck SET status=status WHERE truck_id=1; COMMIT;" 2>&1 } -ArgumentList (,$psql)
Wait-Job $a,$b | Out-Null
"--- Session outputs ---"; Receive-Job $a,$b
Write-Host "--- DIAGNOSIS: server log ---"
docker logs dbalab-primary --since 2m 2>&1 | Select-String 'deadlock detected' -Context 0,6
docker @psql -c "select datname, deadlocks from admin.v_db_health"
Remove-Job $a,$b
