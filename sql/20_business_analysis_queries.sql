-- ============================================================================
-- ADVANCED ANALYTICAL QUERIES: HEALTHCARE OPERATIONS & FINANCIAL SYSTEMS
-- Author: Ravikant Yadav
-- Designed for: Technical Interview & Advanced Portfolio Review
-- Target DB: PostgreSQL (relational analytics schema)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Executive KPI Scorecard
-- Purpose: Calculate high-level clinical metrics (admissions, length of stay,
-- wait times, readmission rate) grouped by admission month.
-- ----------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', admission_date)::DATE AS admission_month,
    COUNT(admission_id) AS total_admissions,
    ROUND(AVG(length_of_stay), 2) AS avg_length_of_stay_days,
    ROUND(AVG(wait_minutes), 1) AS avg_wait_time_minutes,
    ROUND(100.0 * SUM(CASE WHEN readmission_30d THEN 1 ELSE 0 END) / COUNT(admission_id), 2) AS readmission_rate_30d_pct
FROM analytics.admissions
GROUP BY 1
ORDER BY 1 DESC;


-- ----------------------------------------------------------------------------
-- QUERY 2: Monthly Admissions Trends & Moving Averages
-- Purpose: Track week-over-week changes and smooth seasonal patterns using a
-- 3-month moving average of patient admissions.
-- ----------------------------------------------------------------------------
WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', admission_date)::DATE AS admission_month,
        COUNT(admission_id) AS admissions_count
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    admission_month,
    admissions_count,
    admissions_count - LAG(admissions_count) OVER (ORDER BY admission_month) AS mom_admission_change,
    ROUND(AVG(admissions_count) OVER (
        ORDER BY admission_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) AS moving_avg_3m_admissions
FROM monthly_counts
ORDER BY admission_month;


-- ----------------------------------------------------------------------------
-- QUERY 3: Quarterly Growth & Billing Expansion Metrics
-- Purpose: Analyze total quarterly charges, total cost, net margins, and
-- quarter-over-quarter gross profit growth rates.
-- ----------------------------------------------------------------------------
WITH quarterly_financials AS (
    SELECT
        DATE_TRUNC('quarter', a.admission_date)::DATE AS fiscal_quarter,
        SUM(b.charge_amount) AS total_charges,
        SUM(b.cost_amount) AS total_costs,
        SUM(b.charge_amount - b.cost_amount) AS gross_profit
    FROM analytics.billing b
    JOIN analytics.admissions a ON b.admission_id = a.admission_id
    GROUP BY 1
)
SELECT
    fiscal_quarter,
    ROUND(total_charges, 2) AS total_charges,
    ROUND(total_costs, 2) AS total_costs,
    ROUND(gross_profit, 2) AS gross_profit,
    ROUND(100.0 * (gross_profit - LAG(gross_profit) OVER (ORDER BY fiscal_quarter)) /
        NULLIF(LAG(gross_profit) OVER (ORDER BY fiscal_quarter), 0), 2) AS qoq_profit_growth_pct
FROM quarterly_financials
ORDER BY fiscal_quarter;


-- ----------------------------------------------------------------------------
-- QUERY 4: Top Payer Profiles (Insurance Contribution)
-- Purpose: Determine market share, revenue generation, and payment compliance
-- across different insurance models.
-- ----------------------------------------------------------------------------
SELECT
    p.insurance_type,
    COUNT(a.admission_id) AS total_patient_admissions,
    ROUND(SUM(b.charge_amount), 2) AS gross_billing_revenue,
    ROUND(100.0 * SUM(b.charge_amount) / SUM(SUM(b.charge_amount)) OVER (), 2) AS gross_revenue_share_pct,
    ROUND(AVG(b.insurance_paid / NULLIF(b.charge_amount, 0)) * 100, 2) AS avg_insurance_recovery_rate_pct,
    ROUND(AVG(b.patient_paid / NULLIF(b.charge_amount, 0)) * 100, 2) AS avg_patient_out_of_pocket_pct
FROM analytics.patients p
JOIN analytics.admissions a ON p.patient_id = a.patient_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
GROUP BY 1
ORDER BY gross_billing_revenue DESC;


-- ----------------------------------------------------------------------------
-- QUERY 5: Insurance Claim Loss / Cost-to-Charge Ratio Analysis
-- Purpose: Identify which insurance models yield low operating margins by
-- evaluating cost-to-charge ratios and unrecovered billing write-offs.
-- ----------------------------------------------------------------------------
SELECT
    p.insurance_type,
    dept.department,
    ROUND(SUM(b.charge_amount), 2) AS total_billing_charges,
    ROUND(SUM(b.cost_amount), 2) AS total_operating_costs,
    ROUND(SUM(b.cost_amount) / NULLIF(SUM(b.charge_amount), 0), 3) AS cost_to_charge_ratio,
    ROUND(SUM(b.charge_amount - b.insurance_paid - b.patient_paid), 2) AS write_offs_unrecovered_amount
FROM analytics.patients p
JOIN analytics.admissions a ON p.patient_id = a.patient_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
JOIN analytics.departments dept ON a.department_id = dept.department_id
GROUP BY 1, 2
HAVING SUM(b.charge_amount) > 50000
ORDER BY cost_to_charge_ratio DESC;


-- ----------------------------------------------------------------------------
-- QUERY 6: Clinical Segment Performance (Emergency vs Elective vs Urgent)
-- Purpose: Benchmark length of stay, triage patient wait times, operational
-- efficiency, and satisfaction across clinical admission categories.
-- ----------------------------------------------------------------------------
SELECT
    a.admission_type,
    COUNT(a.admission_id) AS admissions_volume,
    ROUND(AVG(a.length_of_stay), 2) AS mean_los_days,
    ROUND(AVG(a.wait_minutes), 1) AS mean_wait_time_mins,
    ROUND(AVG(s.satisfaction_score), 1) AS mean_satisfaction_score,
    ROUND(AVG(a.discharge_efficiency_score), 1) AS mean_discharge_efficiency_pct
FROM analytics.admissions a
LEFT JOIN analytics.satisfaction_surveys s ON a.admission_id = s.admission_id
GROUP BY 1
ORDER BY admissions_volume DESC;


-- ----------------------------------------------------------------------------
-- QUERY 7: Geographic Patient Density & Demographics
-- Purpose: Analyze regional market penetration, average total billing, and
-- patient clinical severity scores by city.
-- ----------------------------------------------------------------------------
SELECT
    p.city,
    COUNT(p.patient_id) AS unique_patients_served,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(a.admission_date, p.birth_date))), 1) AS avg_patient_age,
    ROUND(AVG(a.severity_score), 2) AS avg_clinical_severity,
    ROUND(SUM(b.charge_amount) / COUNT(p.patient_id), 2) AS billing_spend_per_patient
FROM analytics.patients p
JOIN analytics.admissions a ON p.patient_id = a.patient_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
GROUP BY 1
ORDER BY unique_patients_served DESC, billing_spend_per_patient DESC;


-- ----------------------------------------------------------------------------
-- QUERY 8: Departmental Capacity & Bed Utilization Rates
-- Purpose: Join reference bed table to calculate staffed and licensed bed
-- utilization rates against active hospital discharge cycles.
-- ----------------------------------------------------------------------------
WITH active_monthly_utilization AS (
    SELECT
        department_id,
        DATE_TRUNC('month', admission_date)::DATE AS calendar_month,
        SUM(length_of_stay) AS total_inpatient_days
    FROM analytics.admissions
    GROUP BY 1, 2
)
SELECT
    dept.department,
    u.calendar_month,
    b.licensed_beds,
    b.staffed_beds,
    u.total_inpatient_days,
    ROUND(100.0 * u.total_inpatient_days / (b.staffed_beds * 30), 2) AS approx_staffed_bed_occupancy_pct,
    ROUND(100.0 * u.total_inpatient_days / (b.licensed_beds * 30), 2) AS approx_licensed_bed_occupancy_pct
FROM active_monthly_utilization u
JOIN analytics.departments dept ON u.department_id = dept.department_id
JOIN analytics.beds b ON u.department_id = b.department_id
ORDER BY dept.department, u.calendar_month;


-- ----------------------------------------------------------------------------
-- QUERY 9: Patient Attrition & 30-Day Readmission Risk Index
-- Purpose: Calculate patient 30-day readmission metrics by clinical department,
-- sorting by departments with highest readmission frequencies.
-- ----------------------------------------------------------------------------
SELECT
    dept.department,
    COUNT(a.admission_id) AS total_discharges,
    SUM(CASE WHEN a.readmission_30d THEN 1 ELSE 0 END) AS readmission_30d_count,
    ROUND(100.0 * SUM(CASE WHEN a.readmission_30d THEN 1 ELSE 0 END) / COUNT(a.admission_id), 2) AS readmission_pct,
    ROUND(AVG(a.severity_score), 2) AS avg_severity_of_readmissions
FROM analytics.admissions a
JOIN analytics.departments dept ON a.department_id = dept.department_id
GROUP BY 1
ORDER BY readmission_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 10: High-Frequency Readmission Profiles (Inpatient Loyalty/Risk)
-- Purpose: CTE-based analysis mapping patients who experience readmissions
-- within 30 days, ranking their clinical profiles.
-- ----------------------------------------------------------------------------
WITH readmitted_patients AS (
    SELECT
        p.patient_id,
        p.patient_name,
        p.birth_date,
        COUNT(a.admission_id) AS total_admissions,
        SUM(CASE WHEN a.readmission_30d THEN 1 ELSE 0 END) AS readmissions_30d,
        AVG(a.length_of_stay) AS avg_los,
        AVG(a.severity_score) AS avg_severity
    FROM analytics.patients p
    JOIN analytics.admissions a ON p.patient_id = a.patient_id
    GROUP BY 1, 2, 3
    HAVING COUNT(a.admission_id) >= 2
)
SELECT
    patient_id,
    patient_name,
    ROUND(EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))) AS current_age,
    total_admissions,
    readmissions_30d,
    ROUND(avg_los, 1) AS avg_los_days,
    ROUND(avg_severity, 1) AS avg_clinical_severity,
    CASE
        WHEN readmissions_30d >= 2 THEN 'Extreme Risk Inpatient'
        WHEN readmissions_30d = 1 THEN 'High Risk Inpatient'
        ELSE 'Moderate Risk Inpatient'
    END AS clinical_risk_classification
FROM readmitted_patients
ORDER BY readmissions_30d DESC, total_admissions DESC;


-- ----------------------------------------------------------------------------
-- QUERY 11: Clinical Department Cohort Retention (Quarterly View)
-- Purpose: Grouping patients by their first clinical admission quarter and
-- tracking readmission rates over subsequent quarters.
-- ----------------------------------------------------------------------------
WITH patient_first_admission AS (
    SELECT
        patient_id,
        MIN(DATE_TRUNC('quarter', admission_date)::DATE) AS cohort_quarter
    FROM analytics.admissions
    GROUP BY 1
),
cohort_sizes AS (
    SELECT cohort_quarter, COUNT(patient_id) AS cohort_size
    FROM patient_first_admission
    GROUP BY 1
)
SELECT
    fa.cohort_quarter,
    cs.cohort_size,
    COUNT(a.admission_id) AS subsequent_admissions,
    ROUND(100.0 * SUM(CASE WHEN a.readmission_30d THEN 1 ELSE 0 END) / COUNT(a.admission_id), 2) AS readmission_rate_pct,
    ROUND(AVG(a.length_of_stay), 2) AS avg_stay_days
FROM patient_first_admission fa
JOIN cohort_sizes cs ON fa.cohort_quarter = cs.cohort_quarter
JOIN analytics.admissions a ON fa.patient_id = a.patient_id
GROUP BY 1, 2
ORDER BY fa.cohort_quarter;


-- ----------------------------------------------------------------------------
-- QUERY 12: Clinical Revenue Contribution Matrix
-- Purpose: Calculate total billings, costs, and percentage of the total hospital
-- budget generated by each clinical department.
-- ----------------------------------------------------------------------------
SELECT
    dept.department,
    COUNT(b.admission_id) AS bill_records_count,
    ROUND(SUM(b.charge_amount), 2) AS gross_charges,
    ROUND(SUM(b.cost_amount), 2) AS total_costs,
    ROUND(SUM(b.charge_amount - b.cost_amount), 2) AS net_profit_margin,
    ROUND(100.0 * SUM(b.charge_amount) / SUM(SUM(b.charge_amount)) OVER (), 2) AS pct_hospital_revenue_contribution
FROM analytics.billing b
JOIN analytics.departments dept ON b.department_id = dept.department_id
GROUP BY 1
ORDER BY gross_charges DESC;


-- ----------------------------------------------------------------------------
-- QUERY 13: Treatment Cost Profitability & Financial Optimization
-- Purpose: Evaluate procedural profit margins, identifying expensive
-- and loss-making departments.
-- ----------------------------------------------------------------------------
SELECT
    dept.department,
    a.admission_type,
    ROUND(SUM(b.charge_amount), 2) AS total_billing_charges,
    ROUND(SUM(b.cost_amount), 2) AS total_treatment_costs,
    ROUND(AVG(b.charge_amount - b.cost_amount), 2) AS avg_profit_per_patient,
    ROUND(100.0 * SUM(b.charge_amount - b.cost_amount) / SUM(b.charge_amount), 2) AS average_profit_margin_pct
FROM analytics.billing b
JOIN analytics.admissions a ON b.admission_id = a.admission_id
JOIN analytics.departments dept ON b.department_id = dept.department_id
GROUP BY 1, 2
ORDER BY average_profit_margin_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 14: Clinical Wait Time Outliers (3 Standard Deviations Analysis)
-- Purpose: Use statistical standard deviation windows to flag extreme patient
-- wait bottlenecks per clinical department.
-- ----------------------------------------------------------------------------
WITH wait_stats AS (
    SELECT
        department_id,
        AVG(wait_minutes) AS avg_wait,
        STDDEV(wait_minutes) AS std_wait
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    a.admission_id,
    p.patient_name,
    dept.department,
    a.admission_type,
    a.wait_minutes,
    ROUND(ws.avg_wait, 1) AS dept_avg_wait_minutes,
    ROUND(a.wait_minutes - ws.avg_wait, 1) AS deviation_from_avg,
    ROUND((a.wait_minutes - ws.avg_wait) / ws.std_wait, 2) AS z_score
FROM analytics.admissions a
JOIN analytics.patients p ON a.patient_id = p.patient_id
JOIN analytics.departments dept ON a.department_id = dept.department_id
JOIN wait_stats ws ON a.department_id = ws.department_id
WHERE a.wait_minutes > (ws.avg_wait + (3 * ws.std_wait))
ORDER BY z_score DESC;


-- ----------------------------------------------------------------------------
-- QUERY 15: Quality Control: Clinical Null Audit
-- Purpose: Perform strict audits checking key operational data fields for
-- missing fields, anomalies, or bad strings.
-- ----------------------------------------------------------------------------
SELECT
    'Admissions wait_minutes NULL count' AS data_check,
    COUNT(*) AS anomalous_rows_count
FROM analytics.admissions
WHERE wait_minutes IS NULL
UNION ALL
SELECT 'Admissions discharge_date NULL count', COUNT(*)
FROM analytics.admissions WHERE discharge_date IS NULL
UNION ALL
SELECT 'Billing cost_amount NULL count', COUNT(*)
FROM analytics.billing WHERE cost_amount IS NULL OR cost_amount = 0
UNION ALL
SELECT 'Surveys satisfaction_score NULL count', COUNT(*)
FROM analytics.satisfaction_surveys WHERE satisfaction_score IS NULL;


-- ----------------------------------------------------------------------------
-- QUERY 16: Duplicate Admission Records Diagnostic Check
-- Purpose: Scan for duplicate admissions within the database (same patient,
-- doctor, and date) to identify system or loader issues.
-- ----------------------------------------------------------------------------
SELECT
    patient_id,
    doctor_id,
    admission_date,
    COUNT(*) AS overlapping_admissions_count
FROM analytics.admissions
GROUP BY 1, 2, 3
HAVING COUNT(*) > 1;


-- ----------------------------------------------------------------------------
-- QUERY 17: Forecasting Base Table Generator
-- Purpose: Extract historical time-series indicators at a weekly grain to train
-- predictive models for emergency patient arrivals.
-- ----------------------------------------------------------------------------
SELECT
    DATE_TRUNC('week', admission_date)::DATE AS admission_week,
    dept.department,
    COUNT(CASE WHEN a.admission_type = 'Emergency' THEN 1 END) AS emergency_arrivals_count,
    ROUND(AVG(a.wait_minutes), 2) AS avg_wait_time_minutes,
    ROUND(AVG(a.severity_score), 2) AS avg_severity_score,
    ROUND(SUM(b.charge_amount), 2) AS billing_weekly_charges
FROM analytics.admissions a
JOIN analytics.departments dept ON a.department_id = dept.department_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- ----------------------------------------------------------------------------
-- QUERY 18: Doctor Care Quality vs Operational Outcomes
-- Purpose: Quantify care quality per doctor by linking patient satisfaction
-- surveys, patient clinical volumes, and 30d readmission rates.
-- ----------------------------------------------------------------------------
SELECT
    d.doctor_name,
    dept.department,
    COUNT(a.admission_id) AS total_patients_treated,
    ROUND(AVG(s.satisfaction_score), 1) AS mean_satisfaction_score,
    ROUND(100.0 * SUM(CASE WHEN a.readmission_30d THEN 1 ELSE 0 END) / COUNT(a.admission_id), 2) AS doctor_readmission_rate_pct,
    DENSE_RANK() OVER (
        PARTITION BY dept.department_id
        ORDER BY AVG(s.satisfaction_score) DESC
    ) AS satisfaction_rank_in_department
FROM analytics.doctors d
JOIN analytics.departments dept ON d.department_id = dept.department_id
JOIN analytics.admissions a ON d.doctor_id = a.doctor_id
LEFT JOIN analytics.satisfaction_surveys s ON a.admission_id = s.admission_id
GROUP BY 1, 2, dept.department_id
HAVING COUNT(a.admission_id) > 10
ORDER BY department, satisfaction_rank_in_department;


-- ----------------------------------------------------------------------------
-- QUERY 19: Emergency Department Temporal Bottlenecks
-- Purpose: Analyze daily billing, wait times, and LOS values specifically for
-- emergency rooms to locate staff scheduling inefficiencies.
-- ----------------------------------------------------------------------------
SELECT
    TO_CHAR(admission_date, 'Day') AS day_of_week,
    EXTRACT(DOW FROM admission_date) AS day_index,
    COUNT(admission_id) AS total_emergency_arrivals,
    ROUND(AVG(wait_minutes), 1) AS mean_wait_time_mins,
    ROUND(AVG(length_of_stay), 2) AS mean_length_of_stay_days,
    ROUND(SUM(b.charge_amount), 2) AS gross_charges_generated
FROM analytics.admissions a
JOIN analytics.billing b ON a.admission_id = b.admission_id
WHERE a.admission_type = 'Emergency'
GROUP BY 1, 2
ORDER BY day_index;


-- ----------------------------------------------------------------------------
-- QUERY 20: YoY Operational Clinical & Treatment Cost Comparisons
-- Purpose: Compare treatment costs year-over-year at a departmental level to
-- identify inflationary operational overheads.
-- ----------------------------------------------------------------------------
WITH annual_billing AS (
    SELECT
        EXTRACT(YEAR FROM a.admission_date) AS fiscal_year,
        dept.department,
        SUM(b.cost_amount) AS total_costs,
        AVG(b.cost_amount) AS avg_cost_per_patient
    FROM analytics.billing b
    JOIN analytics.admissions a ON b.admission_id = a.admission_id
    JOIN analytics.departments dept ON b.department_id = dept.department_id
    GROUP BY 1, 2
)
SELECT
    curr.department,
    ROUND(prev.total_costs, 2) AS costs_2023,
    ROUND(curr.total_costs, 2) AS costs_2024,
    ROUND(curr.total_costs - prev.total_costs, 2) AS yoy_cost_difference,
    ROUND(100.0 * (curr.total_costs - prev.total_costs) / prev.total_costs, 2) AS yoy_cost_inflation_pct
FROM annual_billing curr
JOIN annual_billing prev ON curr.department = prev.department
    AND curr.fiscal_year = 2024
    AND prev.fiscal_year = 2023
ORDER BY yoy_cost_inflation_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 21: Rolling 7-Day Wait Time Averages (Operational Flow)
-- Purpose: Extract rolling average patterns of patient wait times to identify
-- queue spikes and patient blockages.
-- ----------------------------------------------------------------------------
WITH daily_wait_times AS (
    SELECT
        admission_date,
        COUNT(admission_id) AS admissions_count,
        AVG(wait_minutes) AS avg_wait_mins
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    admission_date,
    admissions_count,
    ROUND(avg_wait_mins, 2) AS daily_avg_wait,
    ROUND(AVG(avg_wait_mins) OVER (
        ORDER BY admission_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7d_wait_avg
FROM daily_wait_times
ORDER BY admission_date;


-- ----------------------------------------------------------------------------
-- QUERY 22: Unified Executive Performance Scorecard
-- Purpose: Consolidate clinical, operational, financial, and feedback indicators
-- into a single, comprehensive hospital dashboard.
-- ----------------------------------------------------------------------------
SELECT
    dept.department,
    COUNT(a.admission_id) AS total_patients_discharged,
    ROUND(AVG(a.length_of_stay), 2) AS avg_los_days,
    ROUND(AVG(a.wait_minutes), 1) AS avg_wait_time_minutes,
    ROUND(AVG(s.satisfaction_score), 1) AS avg_patient_satisfaction_score,
    ROUND(SUM(b.charge_amount), 2) AS total_gross_billings,
    ROUND(100.0 * (SUM(b.charge_amount - b.cost_amount) / SUM(b.charge_amount)), 2) AS net_profit_margin_pct
FROM analytics.admissions a
JOIN analytics.departments dept ON a.department_id = dept.department_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
LEFT JOIN analytics.satisfaction_surveys s ON a.admission_id = s.admission_id
GROUP BY 1
ORDER BY total_patients_discharged DESC;
