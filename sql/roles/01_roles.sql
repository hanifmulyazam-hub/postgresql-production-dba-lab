-- LAB ONLY. Passwords are throwaway; use \set from env in real setups.
CREATE ROLE dba_role NOLOGIN; CREATE ROLE app_role NOLOGIN;
CREATE ROLE analyst_role NOLOGIN; CREATE ROLE readonly_role NOLOGIN;

CREATE ROLE dba_user    LOGIN PASSWORD 'dba_lab_pw'      IN ROLE dba_role;
CREATE ROLE app_user    LOGIN PASSWORD 'app_lab_pw'      IN ROLE app_role;
CREATE ROLE analyst_user LOGIN PASSWORD 'analyst_lab_pw' IN ROLE analyst_role;
CREATE ROLE readonly_user LOGIN PASSWORD 'readonly_lab_pw' IN ROLE readonly_role;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CONNECT ON DATABASE minelab FROM PUBLIC;
GRANT CONNECT ON DATABASE minelab TO dba_role, app_role, analyst_role, readonly_role;

-- DBA: full control of lab schemas
GRANT ALL ON SCHEMA fleet, admin TO dba_role;
GRANT ALL ON ALL TABLES IN SCHEMA fleet, admin TO dba_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA fleet, admin TO dba_role;
GRANT pg_monitor TO dba_role;

-- App/ETL: read/write fleet only, no admin schema
GRANT USAGE ON SCHEMA fleet TO app_role;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA fleet TO app_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA fleet TO app_role;

-- Analyst: read approved tables, no writes
GRANT USAGE ON SCHEMA fleet TO analyst_role;
GRANT SELECT ON fleet.haul_trip, fleet.truck, fleet.route TO analyst_role;

-- Read-only: all fleet tables, select only
GRANT USAGE ON SCHEMA fleet TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA fleet TO readonly_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA fleet GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA fleet GRANT SELECT ON TABLES TO readonly_role;
