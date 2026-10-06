# Runbook: Backup, Restore, Recovery Drill (LAB ONLY)

## 1. Backup
`powershell -File scripts/backup/backup.ps1`
Runs `pg_dump -Fc` (custom format) on `minelab`, saves `backups/minelab_<timestamp>.dump`, appends SUCCESS/FAILURE to `backups/backup.log`.

## 2. Restore (isolated target)
`powershell -File scripts/restore/restore.ps1 [-File path]`
Starts `dbalab-restore` (port 5433), recreates `minelab_restored`, runs `pg_restore --no-owner`.
Expect ~13 "errors ignored": GRANTs to roles that don't exist on the restore instance. Data is unaffected.

## 3. Validate
`powershell -File scripts/restore/validate.ps1` - compares row counts of all tables, primary vs restored. Must print `VALIDATION PASSED`.

## 4. Recovery drill
`powershell -File scripts/restore/recovery_drill.ps1`
1. Count rows for `route_id = 7` (83,604). 2. `DELETE` them (the "accident"). 3. Export the rows from the restored copy and `\copy` them back. 4. Verify count matches; both steps logged in `admin.audit_event`.

Real-world note: this is a row-level recovery from a logical backup. It cannot recover changes made after the backup (that needs WAL archiving / PITR - out of scope for this lab).
