# Runbook: Streaming Replication (LAB ONLY)

## Setup
`powershell -File scripts/replication/setup_replica.ps1`
1. Creates role `replicator` (REPLICATION) and physical slot `replica1_slot` on the primary.
2. Adds `host replication replicator all scram-sha-256` to `pg_hba.conf` (a plain `all` rule does NOT match replication connections) and reloads.
3. Starts `dbalab-replica` (port 5434): `pg_basebackup -R -X stream -S replica1_slot` clones the primary and writes `standby.signal` + `primary_conninfo`, then it starts as a hot standby.

## Verify
`powershell -File scripts/replication/check_replication.ps1` (evidence: `evidence/replication.txt`)
- Primary `pg_stat_replication`: `state=streaming`, `sent_lsn = replay_lsn`, `replay_lag` ~22 ms, `sync_state=async`.
- Replica `pg_is_in_recovery() = t`; a row written on the primary appears on the replica; a write on the replica fails with `cannot execute INSERT in a read-only transaction`.
- `replay_delay` (now() - last replayed xact) is empty/NULL or grows on an idle primary - it only means no recent transactions, not lag. Use `replay_lag`/LSN difference instead.

## Why a standby
Read scaling (reporting queries off the primary), a warm copy for failover, and a safe place to take backups. Replication is **not** a backup: a bad DELETE replicates instantly.

## Risks to know
- **Async** replication: on primary failure, the last few transactions may be lost. Synchronous replication trades latency for zero loss.
- A replication **slot retains WAL** while the replica is down; if the replica never returns, the primary's disk fills. Monitor `pg_replication_slots` and drop unused slots (`pg_drop_replication_slot`).
- Failover (promote with `pg_ctl promote` / `select pg_promote()`) is not automated or tested in this lab.
