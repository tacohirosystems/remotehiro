INSERT INTO tags (name)
SELECT value AS name
FROM json_each($1)
WHERE TRUE
ON CONFLICT (name) DO UPDATE
SET name = excluded.name
RETURNING id
