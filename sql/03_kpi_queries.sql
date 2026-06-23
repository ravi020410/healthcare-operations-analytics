-- Monthly KPI trend
SELECT
    DATE_TRUNC('month', admission_date) AS month,
    COUNT(*) AS records,
    SUM(length_of_stay) AS total_value
FROM analytics.admissions
GROUP BY 1
ORDER BY 1;

-- Quality profile
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT record_id) AS distinct_records
FROM analytics.admissions;
