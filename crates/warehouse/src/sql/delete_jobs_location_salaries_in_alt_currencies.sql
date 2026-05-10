DELETE
FROM jobs_location_salaries_in_alt_currencies
WHERE job_id IN (
  SELECT job_id
  FROM
    jobs_location_salaries_in_alt_currencies,
    json_each(coalesce(?1, '[null]')) AS job_ids
  WHERE
    CASE
      WHEN ?1 IS NOT NULL THEN job_id = job_ids.value
      ELSE TRUE
    END
);
