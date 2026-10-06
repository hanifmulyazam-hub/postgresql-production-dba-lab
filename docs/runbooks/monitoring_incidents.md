# Runbook: Monitoring, Blocking, Deadlock, Logging (LAB ONLY)

## Setup
`Get-Content sql/monitoring/01_health_views.sql | docker exec -i dbalab-primary psql -h localhost -U postgres -d minelab -f -`
Creates `admin.v_active_sessions`, `v_long_running` (>5s), `v_blocking`, `v_db_health`; readable by `dba_user`.

## Health check (what I'd watch)
`select * from admin.v_db_health;` - size, connections vs max_connections, cache hit % (healthy OLTP is typically >99%; 98.3% here after a 2M-row seed + seq scans), rollbacks, deadlocks, temp_files (spills to disk = work_mem too small or heavy sorts).

## Incident 1: Blocking lock
Reproduce: `scripts/workload/lock_blocking.ps1` (evidence: `evidence/lock_blocking.txt`).
1. Symptom: query hangs, no error. 2. Diagnose: `select * from admin.v_blocking;` shows blocked pid, the blocker, and the blocker's state (an `idle in transaction` blocker = app forgot to commit). 3. Fix: ask owner to COMMIT/ROLLBACK; last resort `select pg_terminate_backend(<blocking_pid>)`. 4. Verify `v_blocking` is empty.
Prevention: short transactions, `lock_timeout`, `idle_in_transaction_session_timeout`.

## Incident 2: Deadlock
Reproduce: `scripts/workload/deadlock.ps1` (evidence: `evidence/deadlock.txt`).
Two sessions lock rows 1,2 in opposite order. After `deadlock_timeout` (1s) PostgreSQL aborts one with `ERROR: deadlock detected`; the other commits. Full detail (both queries, both pids) is in the server log: `docker logs dbalab-primary | grep -A8 "deadlock detected"`. Counter: `v_db_health.deadlocks`.
Root cause = inconsistent lock order. Fix: always lock rows in the same order (e.g. `ORDER BY id FOR UPDATE`), keep transactions short, and make the app retry on SQLSTATE 40P01.

## Logging (FR-09)
Set in `docker/docker-compose.yml`: `log_min_duration_statement=500` (slow queries, seen in log: the 9.9s blocked UPDATE), `log_connections=on`, `log_lock_waits=on`, `deadlock_timeout=1s`. View: `docker logs dbalab-primary`.
