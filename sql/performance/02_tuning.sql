\set ON_ERROR_STOP on
CREATE INDEX idx_trip_truck_start ON fleet.haul_trip (truck_id, start_ts);                       -- Q1
CREATE INDEX idx_trip_operator_cov ON fleet.haul_trip (operator_id) INCLUDE (route_id, cycle_time_min, payload_ton); -- Q2 (index-only scan)
CREATE INDEX idx_trip_start ON fleet.haul_trip (start_ts);                                       -- Q3 (after rewrite)
VACUUM ANALYZE fleet.haul_trip;
