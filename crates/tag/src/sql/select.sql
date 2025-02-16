SELECT
  t.tag_id AS id,
  name,
  count(jt.job_id) AS count
FROM tags t
LEFT JOIN jobs_tags jt
  ON t.tag_id = jt.tag_id
GROUP BY
  t.tag_id,
  t.name
ORDER BY t.name ASC;
