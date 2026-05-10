SELECT DISTINCT
  et.employment_type_id AS id,
  et.name
FROM employment_types AS et
LEFT JOIN jobs AS j
  ON et.employment_type_id = j.employment_type_id
WHERE j.job_id IS NOT NULL
ORDER BY et.employment_type_id DESC
