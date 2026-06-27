-- PostgreSQL relational schema for Healthcare Operations Analytics
-- Author: Ravikant Yadav
-- Designed for portfolio review with complete referential integrity, constraints, and index definitions.

CREATE SCHEMA IF NOT EXISTS analytics;

-- 1. Reference Table: Departments
CREATE TABLE IF NOT EXISTS analytics.departments (
    department_id INT PRIMARY KEY,
    department VARCHAR(50) NOT NULL,
    service_line VARCHAR(50) NOT NULL
);

-- 2. Reference Table: Beds Capacity per Department
CREATE TABLE IF NOT EXISTS analytics.beds (
    department_id INT PRIMARY KEY REFERENCES analytics.departments(department_id) ON DELETE CASCADE,
    licensed_beds INT NOT NULL CHECK (licensed_beds >= 0),
    staffed_beds INT NOT NULL CHECK (staffed_beds >= 0)
);

-- 3. Dimension Table: Patients
CREATE TABLE IF NOT EXISTS analytics.patients (
    patient_id INT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    birth_date DATE NOT NULL,
    insurance_type VARCHAR(50) NOT NULL,
    city VARCHAR(100) NOT NULL
);

-- 4. Dimension Table: Doctors
CREATE TABLE IF NOT EXISTS analytics.doctors (
    doctor_id INT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL REFERENCES analytics.departments(department_id) ON DELETE CASCADE,
    employment_type VARCHAR(50) NOT NULL CHECK (employment_type IN ('Full Time', 'Part Time', 'Contract', 'On-Call'))
);

-- 5. Fact Table: Patient Admissions
CREATE TABLE IF NOT EXISTS analytics.admissions (
    admission_id INT PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES analytics.patients(patient_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES analytics.doctors(doctor_id) ON DELETE SET NULL,
    department_id INT NOT NULL REFERENCES analytics.departments(department_id) ON DELETE CASCADE,
    admission_date DATE NOT NULL,
    discharge_date DATE CHECK (discharge_date >= admission_date),
    length_of_stay INT NOT NULL CHECK (length_of_stay >= 0),
    admission_type VARCHAR(30) NOT NULL CHECK (admission_type IN ('Emergency', 'Elective', 'Urgent')),
    wait_minutes DECIMAL(10,2) CHECK (wait_minutes >= 0),
    severity_score DECIMAL(3,1) CHECK (severity_score BETWEEN 1.0 AND 10.0),
    readmission_30d BOOLEAN NOT NULL DEFAULT FALSE,
    discharge_efficiency_score DECIMAL(5,2) CHECK (discharge_efficiency_score BETWEEN 0.0 AND 100.0),
    quality_issue VARCHAR(100)
);

-- 6. Fact/Financial Table: Patient Billing Details
CREATE TABLE IF NOT EXISTS analytics.billing (
    admission_id INT PRIMARY KEY REFERENCES analytics.admissions(admission_id) ON DELETE CASCADE,
    department_id INT NOT NULL REFERENCES analytics.departments(department_id) ON DELETE CASCADE,
    patient_id INT NOT NULL REFERENCES analytics.patients(patient_id) ON DELETE CASCADE,
    charge_amount DECIMAL(12,2) NOT NULL CHECK (charge_amount >= 0),
    cost_amount DECIMAL(12,2) NOT NULL CHECK (cost_amount >= 0),
    insurance_paid DECIMAL(12,2) NOT NULL CHECK (insurance_paid >= 0),
    patient_paid DECIMAL(12,2) NOT NULL CHECK (patient_paid >= 0)
);

-- 7. Fact Table: Patient Satisfaction Surveys
CREATE TABLE IF NOT EXISTS analytics.satisfaction_surveys (
    survey_id SERIAL PRIMARY KEY,
    admission_id INT NOT NULL REFERENCES analytics.admissions(admission_id) ON DELETE CASCADE,
    patient_id INT NOT NULL REFERENCES analytics.patients(patient_id) ON DELETE CASCADE,
    department_id INT NOT NULL REFERENCES analytics.departments(department_id) ON DELETE CASCADE,
    satisfaction_score DECIMAL(4,1) NOT NULL CHECK (satisfaction_score BETWEEN 0.0 AND 100.0),
    response_date DATE NOT NULL
);

-- Index Definitions for Query Optimization
CREATE INDEX IF NOT EXISTS idx_admissions_patient ON analytics.admissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_admissions_doctor ON analytics.admissions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_admissions_dept ON analytics.admissions(department_id);
CREATE INDEX IF NOT EXISTS idx_admissions_date ON analytics.admissions(admission_date);
CREATE INDEX IF NOT EXISTS idx_billing_admission ON analytics.billing(admission_id);
CREATE INDEX IF NOT EXISTS idx_surveys_admission ON analytics.satisfaction_surveys(admission_id);
