# DBA Lessons Learned: Interview Summary (1 page)
Framing: "My background is Data Engineering. I built a PostgreSQL DBA lab to learn the operational side: access, recovery, tuning, monitoring, concurrency."

| Question | My answer from the lab |
|---|---|
| Back up / restore? | `pg_dump -Fc` to timestamped file + log; restore into an isolated instance with `pg_restore`; validate by comparing row counts of every table. Limit: point-in-time only, PITR needs WAL archiving. |
| Slow query? | `EXPLAIN (ANALYZE, BUFFERS)` -> found Seq Scans on 2M rows -> composite, covering and range indexes + one predicate rewrite: 46->3 ms, 40->2.7 ms, 67->0.8 ms. |
| Index help vs hurt? | Helps selective reads; costs disk (161 MB on a 192 MB table) and write speed; unusable if the column is wrapped in a function; column order matters. |
| Blocking / deadlock? | `pg_blocking_pids()` view shows blocker and victim; `idle in transaction` blockers are app bugs. Deadlock = opposite lock order; read the server log, fix ordering, retry on 40P01. |
| Access design? | Role per duty (app/analyst/readonly/dba), login users inherit from NOLOGIN roles, revoke PUBLIC, grant least privilege; verified with a test script. |
| What to monitor? | Connections vs max, cache hit %, long-running queries, blocking sessions, deadlocks, temp files, DB size, backup success. |
| Replication? | Built async streaming replication (pg_basebackup + slot): standby is read-only, verified via `pg_stat_replication` (state, LSNs, replay_lag). Not a backup (bad DELETE replicates). Risks: async can lose last txns, slots retain WAL if replica is down. Failover not tested. |
