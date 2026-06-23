-- Duplicate check
SELECT record_id, COUNT(*)
FROM analytics.admissions
GROUP BY 1
HAVING COUNT(*) > 1;

-- Date completeness check
SELECT COUNT(*) AS missing_dates
FROM analytics.admissions
WHERE admission_date IS NULL;
