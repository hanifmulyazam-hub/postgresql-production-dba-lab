# LAB ONLY. Reproduces a blocking lock: A holds a row lock, B waits, DBA diagnoses, A commits.
$psql = @('exec','dbalab-primary','psql','-h','localhost','-U','postgres','-d','minelab')
$a = Start-Job { param($p) docker @p -c "BEGIN; UPDATE fleet.truck SET status=status WHERE truck_id=1; SELECT pg_sleep(12); COMMIT;" } -ArgumentList (,$psql)
Start-Sleep 2
$b = Start-Job { param($p) docker @p -c "SET application_name='session_B'; UPDATE fleet.truck SET status=status WHERE truck_id=1;" } -ArgumentList (,$psql)
Start-Sleep 4
Write-Host "--- DIAGNOSIS: admin.v_blocking (session B waits on A) ---"
docker @psql -c "select * from admin.v_blocking"
Write-Host "--- Lock waits ---"
docker @psql -c "select pid, locktype, mode, granted from pg_locks where not granted"
Write-Host "--- RESOLUTION: wait for A to COMMIT (or pg_terminate_backend(blocking_pid) as last resort) ---"
Wait-Job $a,$b | Out-Null
docker @psql -c "select count(*) as still_blocked from admin.v_blocking"
Remove-Job $a,$b
