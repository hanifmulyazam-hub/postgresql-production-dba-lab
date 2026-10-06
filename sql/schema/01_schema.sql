-- LAB ONLY: synthetic mining-fleet data.
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE SCHEMA fleet;
CREATE SCHEMA admin;

CREATE TABLE fleet.truck (
  truck_id serial PRIMARY KEY, model text NOT NULL,
  status text NOT NULL DEFAULT 'active', created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE fleet.route (
  route_id serial PRIMARY KEY, route_name text NOT NULL,
  distance_km numeric(6,2) NOT NULL, grade_pct numeric(4,1) NOT NULL);
CREATE TABLE fleet.operator (
  operator_id serial PRIMARY KEY, operator_name text NOT NULL, status text NOT NULL DEFAULT 'active');
CREATE TABLE fleet.haul_trip (
  trip_id bigserial PRIMARY KEY,
  truck_id int NOT NULL REFERENCES fleet.truck, route_id int NOT NULL REFERENCES fleet.route,
  operator_id int NOT NULL REFERENCES fleet.operator,
  start_ts timestamptz NOT NULL, end_ts timestamptz NOT NULL,
  payload_ton numeric(6,1), fuel_l numeric(7,1), cycle_time_min numeric(6,1));
-- Deliberately NO indexes on haul_trip FKs/start_ts: Phase 3 tuning baseline.
CREATE TABLE admin.audit_event (
  event_id bigserial PRIMARY KEY, event_ts timestamptz NOT NULL DEFAULT now(),
  username text NOT NULL DEFAULT current_user, action text NOT NULL,
  object_name text, details jsonb);

INSERT INTO fleet.truck(model,status)
  SELECT (ARRAY['CAT 793F','Komatsu 830E','Hitachi EH3500'])[1+i%3],
         (ARRAY['active','active','active','maintenance'])[1+i%4]
  FROM generate_series(1,60) i;
INSERT INTO fleet.route(route_name,distance_km,grade_pct)
  SELECT 'Route-'||i, round((2+random()*12)::numeric,2), round((random()*10)::numeric,1)
  FROM generate_series(1,25) i;
INSERT INTO fleet.operator(operator_name)
  SELECT 'Operator-'||i FROM generate_series(1,150) i;
-- 2,000,000 trips so index effects are measurable
INSERT INTO fleet.haul_trip(truck_id,route_id,operator_id,start_ts,end_ts,payload_ton,fuel_l,cycle_time_min)
  SELECT 1+(random()*59)::int, 1+(random()*24)::int, 1+(random()*149)::int, s, s+make_interval(mins=>m),
         round((180+random()*40)::numeric,1), round((80+random()*120)::numeric,1), m
  FROM (SELECT now()-make_interval(mins=>(random()*525600)::int) s, (30+random()*60)::int m
        FROM generate_series(1,2000000)) t;
ANALYZE;
