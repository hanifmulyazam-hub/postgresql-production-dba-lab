-- LAB ONLY. Replication role + physical slot (slot keeps WAL until the replica has consumed it).
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='replicator') THEN
    CREATE ROLE replicator REPLICATION LOGIN PASSWORD 'repl_lab_pw';
  END IF;
END $$;
SELECT pg_create_physical_replication_slot('replica1_slot')
WHERE NOT EXISTS (SELECT FROM pg_replication_slots WHERE slot_name='replica1_slot');
