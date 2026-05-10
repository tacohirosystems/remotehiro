SELECT DISTINCT
  c.category_id AS id,
  c.name
FROM
  categories AS c
LEFT JOIN jobs AS j
  ON c.category_id = j.category_id
WHERE
  j.job_id IS NOT NULL
ORDER BY c.name
