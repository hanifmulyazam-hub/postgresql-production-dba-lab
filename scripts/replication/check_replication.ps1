# Verifies replication health and demonstrates read-only standby + data propagation.
function P($c,$sql){ docker exec $c psql -h localhost -U postgres -d minelab -c $sql }
Write-Host "--- Primary: pg_stat_replication ---"
P dbalab-primary "select application_name, state, sync_state, sent_lsn, replay_lsn, replay_lag from pg_stat_replication"
Write-Host "--- Primary: slot ---"
P dbalab-primary "select slot_name, active, restart_lsn from pg_replication_slots"
Write-Host "--- Replica: in recovery? (t = standby) and replay lag ---"
P dbalab-replica "select pg_is_in_recovery() as standby, now()-pg_last_xact_replay_timestamp() as replay_delay"
Write-Host "--- Propagation: write on primary, read on replica ---"
P dbalab-primary "insert into admin.audit_event(action,object_name) values ('REPL_TEST','heartbeat')"
Start-Sleep 1
P dbalab-replica "select action, object_name from admin.audit_event where action='REPL_TEST'"
Write-Host "--- Write on replica must FAIL ---"
P dbalab-replica "insert into admin.audit_event(action) values ('should_fail')"
