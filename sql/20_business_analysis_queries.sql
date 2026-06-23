-- =========================================================================================
-- Healthcare Operations Analytics - 22 Advanced PostgreSQL Business Queries
-- Author: Ravikant Yadav
-- Database Platform: PostgreSQL (v12+)
-- Description: This script contains 22 highly optimized, production-grade SQL queries designed
--              to run directly on the PostgreSQL hospital operations database. It tracks critical
--              SLA and operational metrics: Readmission Rate, Bed Occupancy, Doctor Utilization,
--              Financial Performance (Revenue/Costs), and Discharge Efficiency.
-- =========================================================================================

-- -----------------------------------------------------------------------------------------
-- QUERY 1: Executive KPI Operational Scorecard
-- Purpose: Computes hospital-wide operational metrics: Total admissions, overall readmission
--          rate, mean length of stay (LOS), average ER wait time, and emergency admission rate.
-- -----------------------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_admissions,
    ROUND((SUM(CASE WHEN readmission_30d = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::NUMERIC, 1) AS overall_readmission_rate_pct,
    ROUND(AVG(length_of_stay)::NUMERIC, 1) AS average_length_of_stay_days,
    ROUND(AVG(wait_minutes)::NUMERIC, 1) AS average_er_wait_minutes,
    ROUND((SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::NUMERIC, 1) AS emergency_admission_rate_pct,
    ROUND(AVG(discharge_efficiency_score)::NUMERIC, 1) AS average_discharge_efficiency_score
FROM analytics.admissions;


-- -----------------------------------------------------------------------------------------
-- QUERY 2: Hospital Bed Occupancy Rates by Department
-- Purpose: Evaluates capacity constraints. Calculates the average daily bed occupancy
--          using occupied patient days against staffed bed counts.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    b.staffed_beds,
    COUNT(a.admission_id) AS total_admissions,
    ROUND(SUM(a.length_of_stay)::NUMERIC, 1) AS total_occupied_patient_days,
    ROUND(
        (SUM(a.length_of_stay) * 100.0 / NULLIF(b.staffed_beds * 365.0, 0))::NUMERIC,
        1
    ) AS calculated_bed_occupancy_pct
FROM analytics.departments d
JOIN analytics.beds b ON d.department_id = b.department_id
LEFT JOIN analytics.admissions a ON d.department_id = a.department_id
GROUP BY d.department, b.staffed_beds
ORDER BY calculated_bed_occupancy_pct DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 3: Doctor Clinical Utilization and Workloads
-- Purpose: Identifies doctor work capacity by calculating patients treated, total billings,
--          and average patient length of stay (LOS).
-- -----------------------------------------------------------------------------------------
SELECT
    dr.doctor_name,
    d.department,
    COUNT(a.admission_id) AS patients_treated,
    ROUND(SUM(b.charge_amount)::NUMERIC, 2) AS total_departmental_revenue,
    ROUND(AVG(a.length_of_stay)::NUMERIC, 1) AS average_los_days,
    ROUND(
        (COUNT(a.admission_id) * 100.0 /
         (SELECT COUNT(*) FROM analytics.admissions))::NUMERIC,
        2
    ) AS total_hospital_patient_load_pct
FROM analytics.doctors dr
JOIN analytics.departments d ON dr.department_id = d.department_id
LEFT JOIN analytics.admissions a ON dr.doctor_id = a.doctor_id
LEFT JOIN analytics.billing b ON a.admission_id = b.admission_id
GROUP BY dr.doctor_name, d.department
ORDER BY patients_treated DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 4: Financial Performance: Revenue, Cost, and Profit Margins by Department
-- Purpose: Generates financial P&L insights. Analyzes charges, direct operating costs,
--          and profitability margins across corporate medical service lines.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    d.service_line,
    COUNT(b.admission_id) AS billed_cases,
    ROUND(SUM(b.charge_amount)::NUMERIC, 2) AS total_charges_revenue,
    ROUND(SUM(b.cost_amount)::NUMERIC, 2) AS total_direct_costs,
    ROUND((SUM(b.charge_amount) - SUM(b.cost_amount))::NUMERIC, 2) AS net_operating_profit,
    ROUND(
        ((SUM(b.charge_amount) - SUM(b.cost_amount)) * 100.0 / NULLIF(SUM(b.charge_amount), 0))::NUMERIC,
        1
    ) AS operational_profit_margin_pct
FROM analytics.departments d
LEFT JOIN analytics.billing b ON d.department_id = b.department_id
GROUP BY d.department, d.service_line
ORDER BY total_charges_revenue DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 5: 30-Day Readmission Analysis by Patient Demographics
-- Purpose: Locates clinical risk hotspots by looking at readmission rates across age groups.
-- -----------------------------------------------------------------------------------------
WITH patient_ages AS (
    SELECT
        p.patient_id,
        EXTRACT(YEAR FROM age('2026-01-01'::DATE, p.birth_date::DATE)) AS age
    FROM analytics.patients p
),
age_groups AS (
    SELECT
        patient_id,
        CASE
            WHEN age < 18 THEN '0-17 (Pediatric)'
            WHEN age BETWEEN 18 AND 40 THEN '18-40 (Young Adult)'
            WHEN age BETWEEN 41 AND 65 THEN '41-65 (Adult)'
            ELSE '66+ (Geriatric)'
        END AS age_cohort
    FROM patient_ages
)
SELECT
    ag.age_cohort,
    COUNT(a.admission_id) AS total_admissions,
    SUM(CASE WHEN a.readmission_30d = 1 THEN 1 ELSE 0 END) AS readmitted_cases,
    ROUND(
        (SUM(CASE WHEN a.readmission_30d = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(a.admission_id))::NUMERIC,
        1
    ) AS readmission_rate_pct
FROM age_groups ag
JOIN analytics.admissions a ON ag.patient_id = a.patient_id
GROUP BY ag.age_cohort
ORDER BY readmission_rate_pct DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 6: Discharge Efficiency score vs. Readmission rates
-- Purpose: Investigates the operational trade-off between rushing discharges and patient health.
-- -----------------------------------------------------------------------------------------
WITH discharge_cohorts AS (
    SELECT
        admission_id,
        readmission_30d,
        discharge_efficiency_score,
        CASE
            WHEN discharge_efficiency_score >= 90 THEN 'Excellent (>90)'
            WHEN discharge_efficiency_score BETWEEN 75 AND 89 THEN 'Optimal (75-89)'
            WHEN discharge_efficiency_score BETWEEN 50 AND 74 THEN 'Moderate (50-74)'
            ELSE 'Inefficient (<50)'
        END AS efficiency_cohort
    FROM analytics.admissions
)
SELECT
    efficiency_cohort,
    COUNT(*) AS total_cases,
    SUM(CASE WHEN readmission_30d = 1 THEN 1 ELSE 0 END) AS readmissions_30d,
    ROUND(
        (SUM(CASE WHEN readmission_30d = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::NUMERIC,
        1
    ) AS readmission_rate_pct
FROM discharge_cohorts
GROUP BY efficiency_cohort
ORDER BY MIN(discharge_efficiency_score) DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 7: Emergency Room Wait Times by Admission Severity & Type
-- Purpose: Analyzes ER efficiency. Identifies delays in patient care relative to severity.
-- -----------------------------------------------------------------------------------------
SELECT
    admission_type,
    severity_score,
    COUNT(*) AS total_admissions,
    ROUND(AVG(wait_minutes)::NUMERIC, 1) AS avg_wait_minutes,
    MAX(wait_minutes) AS maximum_wait_minutes,
    ROUND(AVG(length_of_stay)::NUMERIC, 1) AS avg_length_of_stay_days
FROM analytics.admissions
GROUP BY admission_type, severity_score
ORDER BY admission_type, severity_score ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 8: Financial Underperformance: Payer Mix & Write-Off Risks
-- Purpose: Analyzes bill payments across insurance companies. Identifies payment shortfalls.
-- -----------------------------------------------------------------------------------------
SELECT
    p.insurance_type,
    COUNT(b.admission_id) AS total_bills,
    ROUND(SUM(b.charge_amount)::NUMERIC, 2) AS total_charges,
    ROUND(SUM(b.insurance_paid)::NUMERIC, 2) AS insurance_payments,
    ROUND(SUM(b.patient_paid)::NUMERIC, 2) AS patient_payments,
    ROUND(
        (SUM(b.charge_amount) - SUM(b.insurance_paid) - SUM(b.patient_paid))::NUMERIC,
        2
    ) AS outstanding_write_off_balance,
    ROUND(
        ((SUM(b.insurance_paid) + SUM(b.patient_paid)) * 100.0 /
         NULLIF(SUM(b.charge_amount), 0))::NUMERIC,
        1
    ) AS financial_recovery_rate_pct
FROM analytics.patients p
JOIN analytics.billing b ON p.patient_id = b.patient_id
GROUP BY p.insurance_type
ORDER BY outstanding_write_off_balance DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 9: Patient Satisfaction Surveys by Clinical Department
-- Purpose: Evaluates patient experience across divisions to isolate quality deficits.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    COUNT(s.admission_id) AS feedback_responses,
    ROUND(AVG(s.satisfaction_score)::NUMERIC, 1) AS average_satisfaction_score,
    SUM(CASE WHEN s.satisfaction_score >= 8 THEN 1 ELSE 0 END) AS promoter_responses,
    ROUND(
        (SUM(CASE WHEN s.satisfaction_score >= 8 THEN 1 ELSE 0 END) * 100.0 /
         NULLIF(COUNT(s.admission_id), 0))::NUMERIC,
        1
    ) AS net_satisfaction_promoter_rate_pct
FROM analytics.departments d
JOIN analytics.satisfaction_surveys s ON d.department_id = s.department_id
GROUP BY d.department
ORDER BY average_satisfaction_score DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 10: MoM Admissions & Revenue Growth Trend
-- Purpose: Evaluates seasonal operational scale and monthly financial growth.
-- -----------------------------------------------------------------------------------------
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', a.admission_date::TIMESTAMP) AS active_month,
        COUNT(a.admission_id) AS admissions,
        SUM(b.charge_amount) AS total_charges
    FROM analytics.admissions a
    LEFT JOIN analytics.billing b ON a.admission_id = b.admission_id
    GROUP BY DATE_TRUNC('month', a.admission_date::TIMESTAMP)
)
SELECT
    active_month,
    admissions,
    ROUND((admissions - LAG(admissions) OVER (ORDER BY active_month))::NUMERIC, 1) AS admissions_mom_change,
    ROUND(total_charges::NUMERIC, 2) AS total_monthly_charges,
    ROUND(
        ((total_charges - LAG(total_charges) OVER (ORDER BY active_month)) * 100.0 /
         NULLIF(LAG(total_charges) OVER (ORDER BY active_month), 0))::NUMERIC,
        1
    ) AS revenue_growth_rate_pct
FROM monthly_metrics
ORDER BY active_month;


-- -----------------------------------------------------------------------------------------
-- QUERY 11: Clinical Procedure Intensity & Cost Drivers
-- Purpose: Tracks procedure codes and associated clinical costs across hospital lines.
-- -----------------------------------------------------------------------------------------
SELECT
    t.procedure_code,
    COUNT(t.treatment_id) AS procedure_volume,
    ROUND(SUM(t.treatment_cost)::NUMERIC, 2) AS total_treatment_cost,
    ROUND(AVG(t.treatment_cost)::NUMERIC, 2) AS average_cost_per_procedure
FROM analytics.treatments t
GROUP BY t.procedure_code
ORDER BY total_treatment_cost DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 12: High-Length of Stay (LOS) Outlier Analysis
-- Purpose: Identifies high outlier stays exceeding 3 standard deviations from average LOS.
-- -----------------------------------------------------------------------------------------
WITH los_stats AS (
    SELECT
        AVG(length_of_stay) AS mean_los,
        STDDEV(length_of_stay) AS stddev_los
    FROM analytics.admissions
)
SELECT
    a.admission_id,
    p.patient_name,
    d.department,
    a.length_of_stay,
    ROUND(ls.mean_los::NUMERIC, 1) AS mean_los_benchmark,
    ROUND(
        ((a.length_of_stay - ls.mean_los) / NULLIF(ls.stddev_los, 0))::NUMERIC,
        2
    ) AS z_score_los
FROM analytics.admissions a
JOIN analytics.patients p ON a.patient_id = p.patient_id
JOIN analytics.departments d ON a.department_id = d.department_id
CROSS JOIN los_stats ls
WHERE (a.length_of_stay - ls.mean_los) / NULLIF(ls.stddev_los, 0) > 3.0
ORDER BY a.length_of_stay DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 13: Operational Integrity Auditing: Overlapping Admissions
-- Purpose: Audits data quality for anomalies (such as overlapping active admissions).
-- -----------------------------------------------------------------------------------------
SELECT
    curr.patient_id,
    curr.admission_id AS current_admission_id,
    curr.admission_date AS current_admission_date,
    curr.discharge_date AS current_discharge_date,
    prev.admission_id AS prior_admission_id,
    prev.admission_date AS prior_admission_date,
    prev.discharge_date AS prior_discharge_date
FROM analytics.admissions curr
JOIN analytics.admissions prev ON curr.patient_id = prev.patient_id
    AND curr.admission_id != prev.admission_id
    AND curr.admission_date >= prev.admission_date
    AND curr.admission_date < prev.discharge_date
ORDER BY curr.patient_id, curr.admission_date;


-- -----------------------------------------------------------------------------------------
-- QUERY 14: Billing Invoice Consistency Checks
-- Purpose: Financial audit. Flags cases where total procedure costs exceed final billed amount.
-- -----------------------------------------------------------------------------------------
WITH billing_versus_procedures AS (
    SELECT
        b.admission_id,
        b.charge_amount,
        COALESCE(SUM(t.treatment_cost), 0) AS aggregated_treatment_costs
    FROM analytics.billing b
    LEFT JOIN analytics.treatments t ON b.admission_id = t.admission_id
    GROUP BY b.admission_id, b.charge_amount
)
SELECT
    admission_id,
    ROUND(charge_amount::NUMERIC, 2) AS charge_amount,
    ROUND(aggregated_treatment_costs::NUMERIC, 2) AS aggregated_procedure_costs,
    ROUND((aggregated_treatment_costs - charge_amount)::NUMERIC, 2) AS unbilled_clinical_costs
FROM billing_versus_procedures
WHERE aggregated_treatment_costs > charge_amount
ORDER BY unbilled_clinical_costs DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 15: Readmission Financial Penalty Forecasts
-- Purpose: Projections of hospital readmission financial losses under clinical penalty rules.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    COUNT(a.admission_id) AS total_discharged_cases,
    SUM(CASE WHEN a.readmission_30d = 1 THEN 1 ELSE 0 END) AS readmissions_30d,
    ROUND(SUM(CASE WHEN a.readmission_30d = 1 THEN b.charge_amount ELSE 0 END)::NUMERIC, 2) AS gross_readmission_cost,
    -- Assume standard penalty of 3% on total charges for departments with readmissions exceeding 12%
    ROUND(
        (CASE
            WHEN (SUM(CASE WHEN a.readmission_30d = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(a.admission_id)) > 12.0
            THEN SUM(b.charge_amount) * 0.03
            ELSE 0
         END)::NUMERIC,
        2
    ) AS estimated_3pct_readmission_penalty
FROM analytics.departments d
JOIN analytics.admissions a ON d.department_id = a.department_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
GROUP BY d.department
ORDER BY estimated_3pct_readmission_penalty DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 16: Readmissions by Admitting Doctor Severity and Wait Times
-- Purpose: Evaluates whether readmission risk is correlated with high clinical workloads
--          or excessive initial wait times.
-- -----------------------------------------------------------------------------------------
SELECT
    dr.doctor_name,
    COUNT(a.admission_id) AS patient_cases,
    ROUND(AVG(a.wait_minutes)::NUMERIC, 1) AS average_patient_wait_minutes,
    ROUND(AVG(a.severity_score)::NUMERIC, 1) AS average_severity_score,
    ROUND(
        (SUM(CASE WHEN a.readmission_30d = 1 THEN 1 ELSE 0 END) * 100.0 /
         NULLIF(COUNT(a.admission_id), 0))::NUMERIC,
        1
    ) AS readmission_rate_pct
FROM analytics.doctors dr
JOIN analytics.admissions a ON dr.doctor_id = a.doctor_id
GROUP BY dr.doctor_name
HAVING COUNT(a.admission_id) >= 5
ORDER BY readmission_rate_pct DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 17: Departmental Resource Productivity Index
-- Purpose: Highlights the operational load relative to patient satisfaction.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    COUNT(a.admission_id) AS total_admissions,
    ROUND(AVG(a.length_of_stay)::NUMERIC, 1) AS average_length_of_stay,
    ROUND(AVG(s.satisfaction_score)::NUMERIC, 1) AS average_satisfaction,
    -- Productivity score: Satisfaction divided by average length of stay
    ROUND(
        (AVG(s.satisfaction_score) / NULLIF(AVG(a.length_of_stay), 0))::NUMERIC,
        2
    ) AS operational_efficiency_index
FROM analytics.departments d
LEFT JOIN analytics.admissions a ON d.department_id = a.department_id
LEFT JOIN analytics.satisfaction_surveys s ON a.admission_id = s.admission_id
GROUP BY d.department
ORDER BY operational_efficiency_index DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 18: Patient Retention & City Distribution
-- Purpose: Identifies demographic geographical locations where patients reside.
-- -----------------------------------------------------------------------------------------
SELECT
    p.city,
    COUNT(a.admission_id) AS total_patient_admissions,
    ROUND(SUM(b.charge_amount)::NUMERIC, 2) AS total_geographic_billings,
    ROUND(AVG(b.charge_amount)::NUMERIC, 2) AS average_bill_per_patient
FROM analytics.patients p
JOIN analytics.admissions a ON p.patient_id = a.patient_id
JOIN analytics.billing b ON a.admission_id = b.admission_id
GROUP BY p.city
ORDER BY total_patient_admissions DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 19: Staffed Bed Allocation vs. Admission Rates
-- Purpose: Investigates if hospitals over-allocate staffed beds to underperforming lines.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    b.staffed_beds,
    COUNT(a.admission_id) AS total_admissions,
    ROUND((COUNT(a.admission_id) * 1.0 / NULLIF(b.staffed_beds, 0))::NUMERIC, 1) AS admissions_per_staffed_bed
FROM analytics.departments d
JOIN analytics.beds b ON d.department_id = b.department_id
LEFT JOIN analytics.admissions a ON d.department_id = a.department_id
GROUP BY d.department, b.staffed_beds
ORDER BY admissions_per_staffed_bed DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 20: Cost-To-Charge Ratio (CCR) by Clinical Line
-- Purpose: Standard health industry metrics showing operating cost structures.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    ROUND(SUM(b.charge_amount)::NUMERIC, 2) AS total_hospital_charges,
    ROUND(SUM(b.cost_amount)::NUMERIC, 2) AS total_internal_costs,
    ROUND(
        (SUM(b.cost_amount) / NULLIF(SUM(b.charge_amount), 0))::NUMERIC,
        3
    ) AS cost_to_charge_ratio_ccr
FROM analytics.departments d
JOIN analytics.billing b ON d.department_id = b.department_id
GROUP BY d.department
ORDER BY cost_to_charge_ratio_ccr ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 21: High-Risk Readmission Profile Flags (Seniors with Severity Score > 4)
-- Purpose: Generates care list of geriatric patients at risk of chronic readmission.
-- -----------------------------------------------------------------------------------------
SELECT
    p.patient_name,
    EXTRACT(YEAR FROM age('2026-01-01'::DATE, p.birth_date::DATE)) AS patient_age,
    d.department,
    a.length_of_stay,
    a.severity_score,
    a.wait_minutes AS er_wait_minutes
FROM analytics.admissions a
JOIN analytics.patients p ON a.patient_id = p.patient_id
JOIN analytics.departments d ON a.department_id = d.department_id
WHERE EXTRACT(YEAR FROM age('2026-01-01'::DATE, p.birth_date::DATE)) >= 65
  AND a.severity_score >= 4
  AND a.status = 'Active' -- assuming 'Active' represents currently active patients or active stays
ORDER BY a.severity_score DESC, patient_age DESC
LIMIT 50;


-- -----------------------------------------------------------------------------------------
-- QUERY 22: Consolidated Healthcare Operational Performance Matrix
-- Purpose: Combines geographical patient volume, revenue numbers, readmissions,
--          and beds into a single senior operational summary report.
-- -----------------------------------------------------------------------------------------
SELECT
    d.department,
    COUNT(a.admission_id) AS total_cases,
    ROUND(SUM(b.charge_amount)::NUMERIC, 2) AS aggregated_charges,
    ROUND(AVG(a.length_of_stay)::NUMERIC, 1) AS avg_los,
    ROUND((SUM(CASE WHEN a.readmission_30d = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::NUMERIC, 1) AS readmission_rate_pct,
    ROUND(AVG(s.satisfaction_score)::NUMERIC, 1) AS patient_satisfaction
FROM analytics.departments d
LEFT JOIN analytics.admissions a ON d.department_id = a.department_id
LEFT JOIN analytics.billing b ON a.admission_id = b.admission_id
LEFT JOIN analytics.satisfaction_surveys s ON a.admission_id = s.admission_id
GROUP BY d.department
ORDER BY total_cases DESC;
