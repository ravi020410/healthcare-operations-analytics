-- PostgreSQL COPY script to load cleaned CSV files into normalized schema tables.
-- Author: Ravikant Yadav
-- Note: Replace '/absolute/path/to/' with your local repository path before running in psql.

-- 1. Load Reference: Departments
\copy analytics.departments (department_id, department, service_line) FROM 'data/cleaned/departments.csv' WITH CSV HEADER;

-- 2. Load Reference: Beds
\copy analytics.beds (department_id, licensed_beds, staffed_beds) FROM 'data/cleaned/beds.csv' WITH CSV HEADER;

-- 3. Load Dimension: Patients
\copy analytics.patients (patient_id, patient_name, gender, birth_date, insurance_type, city) FROM 'data/cleaned/patients.csv' WITH CSV HEADER;

-- 4. Load Dimension: Doctors
\copy analytics.doctors (doctor_id, doctor_name, department_id, employment_type) FROM 'data/cleaned/doctors.csv' WITH CSV HEADER;

-- 5. Load Fact: Admissions
\copy analytics.admissions (admission_id, patient_id, doctor_id, department_id, admission_date, discharge_date, length_of_stay, admission_type, wait_minutes, severity_score, readmission_30d, discharge_efficiency_score, quality_issue) FROM 'data/cleaned/admissions.csv' WITH CSV HEADER;

-- 6. Load Fact/Financial: Billing
\copy analytics.billing (admission_id, department_id, patient_id, charge_amount, cost_amount, insurance_paid, patient_paid) FROM 'data/cleaned/billing.csv' WITH CSV HEADER;

-- 7. Load Fact: Satisfaction Surveys
\copy analytics.satisfaction_surveys (admission_id, patient_id, department_id, satisfaction_score, response_date) FROM 'data/cleaned/satisfaction_surveys.csv' WITH CSV HEADER;
