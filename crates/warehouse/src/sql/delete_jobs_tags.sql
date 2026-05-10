DELETE
FROM jobs_tags
WHERE job_id IN (
  SELECT job_id
  FROM json_each(coalesce(?1, '[null]')) AS job_ids
  WHERE ?1 IS NULL OR job_id = job_ids.value
);
