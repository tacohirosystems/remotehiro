INSERT INTO companies (name)
VALUES ($1)
ON CONFLICT (name) DO UPDATE
SET name = excluded.name
RETURNING id;
