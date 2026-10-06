# Performance Tuning Report (LAB ONLY)
Table `fleet.haul_trip`: 2,000,000 rows, 192 MB. Docker Desktop on Windows 11 laptop, PostgreSQL 16.15. Times = 2nd (warm) run of `EXPLAIN (ANALYZE, BUFFERS)`.
Raw evidence: `evidence/perf_before.txt`, `evidence/perf_after.txt`. Reproduce: `sql/performance/00_reset.sql` -> `01_slow_queries.sql` -> `02_tuning.sql` -> `03_after_queries.sql`.

| Query | Before | After | Change | Fix |
|---|---|---|---|---|
| Q1 trips of one truck, 30 days | 46.2 ms, Parallel Seq Scan | 3.0 ms, Bitmap Index Scan | ~15x | composite index `(truck_id, start_ts)` |
| Q2 per-route stats for one operator | 39.9 ms, Parallel Seq Scan | 2.7 ms, Index Only Scan | ~15x | covering index `(operator_id) INCLUDE (route_id, cycle_time_min, payload_ton)` |
| Q3 trips on one day | 66.6 ms, Parallel Seq Scan | 0.8 ms, Index Only Scan | ~85x | rewrite `start_ts::date = d` to `start_ts >= d AND < d+1` + index `(start_ts)` |

## Lessons
- **Q3 is a query fix, not just an index**: a function on the column makes the predicate non-sargable, so an index alone would not be used.
- **Column order matters** in Q1: equality column (`truck_id`) first, range column (`start_ts`) second; it also satisfies `ORDER BY start_ts`.
- **Indexes cost something**: the 3 new indexes add ~161 MB on a 192 MB table, and slow every INSERT/UPDATE. The covering index (77 MB) is only worth it if Q2 is a hot query.
- Gains here are modest in absolute ms because the table fits in cache on this machine; on larger data or cold cache the gap grows.
