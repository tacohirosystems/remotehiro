-- Revert remotehiro:20260111093206_add_states to sqlite

BEGIN IMMEDIATE;

DROP TABLE states;

COMMIT;
