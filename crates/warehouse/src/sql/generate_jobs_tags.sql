INSERT INTO jobs_tags(
  job_id,
  tags,
  created_at,
  updated_at
)
SELECT
  job_id,
  json_group_array(t.name) AS tags,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP AS updated_at
FROM remotehiro.jobs_tags jt
INNER JOIN remotehiro.tags t
  ON jt.tag_id = t.tag_id
WHERE
  (?1 IS NULL OR EXISTS (
    SELECT 1
    FROM json_each(?1) job_id
    WHERE job_id.value = jt.job_id
  ))
GROUP BY jt.job_id
ON CONFLICT (job_id)
DO UPDATE SET
  tags = EXCLUDED.tags,
  updated_at = EXCLUDED.updated_at;
