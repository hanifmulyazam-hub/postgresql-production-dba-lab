DROP INDEX IF EXISTS fleet.idx_trip_truck_start, fleet.idx_trip_operator_cov, fleet.idx_trip_start;
VACUUM ANALYZE fleet.haul_trip;
