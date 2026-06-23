-- Portfolio-ready analytical query examples for Healthcare Analytics
-- Add table-specific joins after loading the dimension tables.
WITH monthly AS (
    SELECT DATE_TRUNC('month', admission_date) AS month, SUM(length_of_stay) AS value
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    month,
    value,
    value - LAG(value) OVER (ORDER BY month) AS absolute_change,
    value / NULLIF(LAG(value) OVER (ORDER BY month), 0) - 1 AS growth_rate
FROM monthly
ORDER BY month;
