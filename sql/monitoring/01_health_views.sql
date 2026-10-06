-- LAB ONLY. Run once: Get-Content sql/monitoring/01_health_views.sql | docker exec -i dbalab-primary psql -h localhost -U postgres -d minelab -f -
CREATE OR REPLACE VIEW admin.v_active_sessions AS
SELECT pid, usename, datname, application_name, state, wait_event_type, wait_event,
       now()-xact_start AS xact_age, now()-query_start AS query_age, left(query,80) AS query
FROM pg_stat_activity WHERE backend_type='client backend' AND pid <> pg_backend_pid();

CREATE OR REPLACE VIEW admin.v_long_running AS
SELECT pid, usename, state, now()-query_start AS runtime, left(query,80) AS query
FROM pg_stat_activity
WHERE backend_type='client backend' AND state <> 'idle' AND now()-query_start > interval '5 seconds' AND pid <> pg_backend_pid();

CREATE OR REPLACE VIEW admin.v_blocking AS
SELECT blocked.pid AS blocked_pid, blocked.usename AS blocked_user, left(blocked.query,60) AS blocked_query,
       now()-blocked.query_start AS blocked_for,
       blocker.pid AS blocking_pid, blocker.usename AS blocking_user, blocker.state AS blocking_state, left(blocker.query,60) AS blocking_last_query
FROM pg_stat_activity blocked
JOIN LATERAL unnest(pg_blocking_pids(blocked.pid)) b(pid) ON true
JOIN pg_stat_activity blocker ON blocker.pid=b.pid;

CREATE OR REPLACE VIEW admin.v_db_health AS
SELECT d.datname, pg_size_pretty(pg_database_size(d.datname)) AS size,
       (SELECT count(*) FROM pg_stat_activity a WHERE a.datname=d.datname) AS connections,
       (SELECT setting::int FROM pg_settings WHERE name='max_connections') AS max_connections,
       round(100.0*s.blks_hit/nullif(s.blks_hit+s.blks_read,0),2) AS cache_hit_pct,
       s.xact_commit, s.xact_rollback, s.deadlocks, s.temp_files
FROM pg_database d JOIN pg_stat_database s USING (datname) WHERE d.datname='minelab';

GRANT SELECT ON admin.v_active_sessions, admin.v_long_running, admin.v_blocking, admin.v_db_health TO dba_role;
