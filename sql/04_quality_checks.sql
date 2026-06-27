-- Production-ready Data Quality Auditing Suite for Healthcare Relational Schema
-- Author: Ravikant Yadav
-- Designed to identify duplicates, dangling references, data range boundary anomalies, and null violations.

-- 1. PRIMARY KEY UNIQUENESS AUDIT
SELECT 'Patients Duplicate Check' AS audit_rule, COUNT(*) FROM (
    SELECT patient_id FROM analytics.patients GROUP BY 1 HAVING COUNT(*) > 1
) sq
UNION ALL
SELECT 'Doctors Duplicate Check', COUNT(*) FROM (
    SELECT doctor_id FROM analytics.doctors GROUP BY 1 HAVING COUNT(*) > 1
) sq
UNION ALL
SELECT 'Admissions Duplicate Check', COUNT(*) FROM (
    SELECT admission_id FROM analytics.admissions GROUP BY 1 HAVING COUNT(*) > 1
) sq;

-- 2. FOREIGN KEY REFERENTIAL INTEGRITY AUDIT (DANGLING REFERENCES)
SELECT 'Dangling Admissions -> Patients' AS audit_rule, COUNT(*) FROM analytics.admissions a
LEFT JOIN analytics.patients p ON a.patient_id = p.patient_id WHERE p.patient_id IS NULL
UNION ALL
SELECT 'Dangling Admissions -> Doctors', COUNT(*) FROM analytics.admissions a
LEFT JOIN analytics.doctors d ON a.doctor_id = d.doctor_id WHERE d.doctor_id IS NULL AND a.doctor_id IS NOT NULL
UNION ALL
SELECT 'Dangling Admissions -> Departments', COUNT(*) FROM analytics.admissions a
LEFT JOIN analytics.departments dept ON a.department_id = dept.department_id WHERE dept.department_id IS NULL
UNION ALL
SELECT 'Dangling Billing -> Admissions', COUNT(*) FROM analytics.billing b
LEFT JOIN analytics.admissions a ON b.admission_id = a.admission_id WHERE a.admission_id IS NULL
UNION ALL
SELECT 'Dangling Surveys -> Admissions', COUNT(*) FROM analytics.satisfaction_surveys s
LEFT JOIN analytics.admissions a ON s.admission_id = a.admission_id WHERE a.admission_id IS NULL;

-- 3. RANGE BOUNDARY & LOGIC AUDITS (CLINICAL & FINANCIAL DATA SANE CHECKS)
SELECT 'Discharge Before Admission Date Check' AS anomaly, COUNT(*) FROM analytics.admissions WHERE discharge_date < admission_date
UNION ALL
SELECT 'Negative Length of Stay Check', COUNT(*) FROM analytics.admissions WHERE length_of_stay < 0
UNION ALL
SELECT 'Negative Wait Time Check', COUNT(*) FROM analytics.admissions WHERE wait_minutes < 0
UNION ALL
SELECT 'Out of Range Severity Score (not 1-10)', COUNT(*) FROM analytics.admissions WHERE severity_score < 1.0 OR severity_score > 10.0
UNION ALL
SELECT 'Out of Range Survey Score (not 0-100)', COUNT(*) FROM analytics.satisfaction_surveys WHERE satisfaction_score < 0.0 OR satisfaction_score > 100.0
UNION ALL
SELECT 'Billing Undercharges Anomaly (Charges < Cost)', COUNT(*) FROM analytics.billing WHERE charge_amount < cost_amount;

-- 4. CRITICAL MISSINGNESS AUDIT (NULL CONTROLS)
SELECT 'Nulls in Patients Birth Dates' AS missingness, COUNT(*) FROM analytics.patients WHERE birth_date IS NULL
UNION ALL
SELECT 'Nulls in Admissions Date', COUNT(*) FROM analytics.admissions WHERE admission_date IS NULL
UNION ALL
SELECT 'Nulls in Billing Net Charges', COUNT(*) FROM analytics.billing WHERE charge_amount IS NULL OR cost_amount IS NULL;
