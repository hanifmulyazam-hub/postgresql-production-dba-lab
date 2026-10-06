-- Each query is run twice (1st warms cache, 2nd is the number we report).
\set ON_ERROR_STOP on
\echo '=== Q1: trips of one truck in a 30-day window ==='
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM fleet.haul_trip WHERE truck_id=17 AND start_ts >= '2026-03-01' AND start_ts < '2026-03-31' ORDER BY start_ts;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM fleet.haul_trip WHERE truck_id=17 AND start_ts >= '2026-03-01' AND start_ts < '2026-03-31' ORDER BY start_ts;
\echo '=== Q2: per-route stats for one operator ==='
EXPLAIN (ANALYZE, BUFFERS) SELECT route_id, count(*), avg(cycle_time_min), sum(payload_ton) FROM fleet.haul_trip WHERE operator_id=42 GROUP BY route_id;
EXPLAIN (ANALYZE, BUFFERS) SELECT route_id, count(*), avg(cycle_time_min), sum(payload_ton) FROM fleet.haul_trip WHERE operator_id=42 GROUP BY route_id;
\echo '=== Q3: trips on one day (function on column = index unusable) ==='
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM fleet.haul_trip WHERE start_ts >= '2026-03-15' AND start_ts < '2026-03-16';
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM fleet.haul_trip WHERE start_ts >= '2026-03-15' AND start_ts < '2026-03-16';
