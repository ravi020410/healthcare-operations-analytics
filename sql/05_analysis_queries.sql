-- Portfolio-Ready Analytical Growth Queries (Time-Series & Trend Analysis)
-- Author: Ravikant Yadav
-- Platform: PostgreSQL

-- 1. MONTH-OVER-MONTH ADMISSIONS & CLINICAL GROWTH RATES (CTEs & LAG Windows)
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', admission_date)::DATE AS calendar_month,
        COUNT(*) AS total_admissions,
        SUM(length_of_stay) AS total_inpatient_days,
        AVG(wait_minutes) AS avg_patient_wait_time
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    calendar_month,
    total_admissions,
    total_admissions - LAG(total_admissions) OVER (ORDER BY calendar_month) AS admissions_mom_net_change,
    ROUND(100.0 * (total_admissions - LAG(total_admissions) OVER (ORDER BY calendar_month)) /
        NULLIF(LAG(total_admissions) OVER (ORDER BY calendar_month), 0), 2) AS admissions_mom_growth_rate_pct,
    ROUND(avg_patient_wait_time, 1) AS avg_patient_wait_time_mins,
    ROUND(avg_patient_wait_time - LAG(avg_patient_wait_time) OVER (ORDER BY calendar_month), 1) AS wait_time_mom_shift_mins
FROM monthly_metrics
ORDER BY calendar_month;

-- 2. CUMULATIVE DEPARTMENTAL RUNNING TOTAL BILLINGS (Partitioned Aggregate Windows)
SELECT
    DATE_TRUNC('month', a.admission_date)::DATE AS calendar_month,
    dept.department,
    ROUND(SUM(b.charge_amount), 2) AS monthly_gross_charges,
    ROUND(SUM(SUM(b.charge_amount)) OVER (
        PARTITION BY dept.department_id
        ORDER BY DATE_TRUNC('month', a.admission_date)::DATE
    ), 2) AS running_cumulative_revenue
FROM analytics.billing b
JOIN analytics.admissions a ON b.admission_id = a.admission_id
JOIN analytics.departments dept ON a.department_id = dept.department_id
GROUP BY 1, dept.department, dept.department_id
ORDER BY dept.department, calendar_month;
