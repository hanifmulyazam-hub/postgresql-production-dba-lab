-- Run per user: psql -h localhost -U app_user -d minelab -f /verify/verify_access.sql
-- Expected: all -> admin FAILS; analyst/readonly -> INSERT FAILS; app/dba INSERT ok (rolled back).
BEGIN;
SELECT current_user;
SELECT count(*) FROM fleet.truck;
SELECT count(*) FROM admin.audit_event;
INSERT INTO fleet.truck(model) VALUES ('test');
ROLLBACK;
