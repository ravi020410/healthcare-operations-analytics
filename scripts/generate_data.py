"""
Relational Synthetic Data Generator for Healthcare Operations Analytics
Author: Ravikant Yadav
Description: Generates robust, relational, realistic hospital clinical and financial CSV logs
             with realistic correlations, trends, and data anomalies.
"""

import sys
import os
from pathlib import Path
import pandas as pd
import numpy as np
from faker import Faker

# Base directory setup
ROOT = Path(__file__).resolve().parents[1]
raw_dir = ROOT / 'data' / 'raw'
cleaned_dir = ROOT / 'data' / 'cleaned'
processed_dir = ROOT / 'data' / 'processed'

for d in [raw_dir, cleaned_dir, processed_dir]:
    d.mkdir(parents=True, exist_ok=True)

fake = Faker()
Faker.seed(42)
np.random.seed(42)

print("Starting Relational Data Generation Pipeline...")

# 1. Generate Departments (Reference Table)
departments_data = [
    {"department_id": 1, "department": "Emergency", "service_line": "Acute"},
    {"department_id": 2, "department": "Cardiology", "service_line": "Specialty"},
    {"department_id": 3, "department": "Oncology", "service_line": "Specialty"},
    {"department_id": 4, "department": "Orthopedics", "service_line": "Surgical"},
    {"department_id": 5, "department": "Neurology", "service_line": "Specialty"},
    {"department_id": 6, "department": "Pediatrics", "service_line": "Primary"},
    {"department_id": 7, "department": "ICU", "service_line": "Acute"},
    {"department_id": 8, "department": "Surgery", "service_line": "Surgical"},
    {"department_id": 9, "department": "Radiology", "service_line": "Diagnostic"},
    {"department_id": 10, "department": "Gastroenterology", "service_line": "Specialty"},
    {"department_id": 11, "department": "Urology", "service_line": "Specialty"},
    {"department_id": 12, "department": "General Medicine", "service_line": "Primary"}
]
df_departments = pd.DataFrame(departments_data)
df_departments.to_csv(raw_dir / 'departments.csv', index=False)
print(f"Generated {len(df_departments)} departments.")

# 2. Generate Beds per Department (Reference Table)
beds_data = []
for d in departments_data:
    beds_data.append({
        "department_id": d["department_id"],
        "licensed_beds": np.random.randint(40, 150),
        "staffed_beds": np.random.randint(25, 120)
    })
df_beds = pd.DataFrame(beds_data)
df_beds.to_csv(raw_dir / 'beds.csv', index=False)
print(f"Generated beds capacity.")

# 3. Generate Doctors (Dimension Table)
num_doctors = 350
doctors_list = []
employment_types = ['Full Time', 'Part Time', 'Contract', 'On-Call']
for doc_id in range(1, num_doctors + 1):
    dept = np.random.choice(departments_data)
    doctors_list.append({
        "doctor_id": doc_id,
        "doctor_name": f"Dr. {fake.name()}",
        "department_id": dept["department_id"],
        "employment_type": np.random.choice(employment_types, p=[0.7, 0.15, 0.1, 0.05])
    })
df_doctors = pd.DataFrame(doctors_list)
df_doctors.to_csv(raw_dir / 'doctors.csv', index=False)
print(f"Generated {len(df_doctors)} doctors.")

# 4. Generate Patients (Dimension Table)
num_patients = 20000
patients_list = []
insurance_types = ['Medicare', 'Medicaid', 'Commercial', 'Self-Pay']
cities = ['Jacksonville', 'Miami', 'Orlando', 'Tampa', 'Tallahassee', 'St. Petersburg']
for pat_id in range(1, num_patients + 1):
    patients_list.append({
        "patient_id": pat_id,
        "patient_name": fake.name(),
        "gender": np.random.choice(['Male', 'Female', 'Other'], p=[0.48, 0.48, 0.04]),
        "birth_date": fake.date_of_birth(minimum_age=0, maximum_age=95).strftime('%Y-%m-%d'),
        "insurance_type": np.random.choice(insurance_types, p=[0.35, 0.25, 0.3, 0.10]),
        "city": np.random.choice(cities)
    })
df_patients = pd.DataFrame(patients_list)
df_patients.to_csv(raw_dir / 'patients.csv', index=False)
print(f"Generated {len(df_patients)} patients.")

# 5. Generate Admissions (Fact Table) with quality anomalies
num_admissions = 45000
admissions_list = []
admission_types = ['Emergency', 'Elective', 'Urgent']

start_date = pd.to_datetime('2023-01-01')
end_date = pd.to_datetime('2025-12-31')

# To represent real correlations: Emergency/ICU has higher severity, Cardiology is costlier
for adm_id in range(1, num_admissions + 1):
    pat = np.random.choice(patients_list)
    doc = np.random.choice(doctors_list)
    adm_type = np.random.choice(admission_types, p=[0.40, 0.40, 0.20])

    # Severity & Wait times correlate with Admission Type
    if adm_type == 'Emergency':
        severity = round(np.random.normal(7.0, 1.5), 1)
        wait_min = max(0.0, np.random.exponential(45.0))
    elif adm_type == 'Urgent':
        severity = round(np.random.normal(5.0, 1.2), 1)
        wait_min = max(0.0, np.random.exponential(25.0))
    else: # Elective
        severity = round(np.random.normal(3.0, 1.0), 1)
        wait_min = max(0.0, np.random.normal(10.0, 5.0))

    severity = max(1.0, min(10.0, severity))
    wait_min = round(wait_min, 1)

    adm_dt = fake.date_between_dates(date_start=start_date, date_end=end_date)
    los = max(1, int(np.random.geometric(p=0.25))) # median stay ~3-4 days
    dis_dt = adm_dt + pd.Timedelta(days=los)

    readmit = np.random.choice([True, False], p=[0.11, 0.89]) if severity > 6.0 else np.random.choice([True, False], p=[0.05, 0.95])
    discharge_eff = round(max(0.0, min(100.0, np.random.normal(85.0 - (los * 0.5), 8.0))), 1)

    # Anomaly injection: Introduce duplicate rows and some missing values in categorical fields to clean in notebooks
    quality_issue = ""
    if np.random.rand() < 0.02: # 2% duplicates
        quality_issue = "duplicate"
    elif np.random.rand() < 0.01: # missing admission_type
        adm_type = np.nan
        quality_issue = "missing_category"

    admissions_list.append({
        "admission_id": adm_id,
        "patient_id": pat["patient_id"],
        "doctor_id": doc["doctor_id"],
        "department_id": doc["department_id"],
        "admission_date": adm_dt.strftime('%Y-%m-%d'),
        "discharge_date": dis_dt.strftime('%Y-%m-%d'),
        "length_of_stay": los,
        "admission_type": adm_type,
        "wait_minutes": wait_min,
        "severity_score": severity,
        "readmission_30d": readmit,
        "discharge_efficiency_score": discharge_eff,
        "quality_issue": quality_issue
    })

df_admissions = pd.DataFrame(admissions_list)

# Handle duplicate rows injection
duplicates = df_admissions[df_admissions['quality_issue'] == "duplicate"].copy()
if not duplicates.empty:
    df_admissions = pd.concat([df_admissions, duplicates], ignore_index=True)

df_admissions.to_csv(raw_dir / 'admissions.csv', index=False)
print(f"Generated {len(df_admissions)} admissions (with anomalies injected).")

# 6. Generate Billing Details (Financial Table)
billing_list = []
for index, row in df_admissions.dropna(subset=['admission_id']).drop_duplicates(subset=['admission_id']).iterrows():
    # Cardiology (2), Oncology (3), Surgery (8), and ICU (7) have higher baseline treatment charges
    dept_id = row['department_id']
    base_charge = 1500.0
    if dept_id in [2, 8, 7]:
        base_charge = 4500.0
    elif dept_id == 3:
        base_charge = 3000.0

    los = row['length_of_stay']
    charge = round(max(500.0, np.random.normal(base_charge + (los * 800.0), 350.0)), 2)
    cost = round(charge * np.random.uniform(0.55, 0.82), 2)

    ins_paid = round(charge * np.random.choice([0.80, 0.70, 0.00], p=[0.60, 0.30, 0.10]), 2)
    pat_paid = round(max(0.0, charge - ins_paid) * np.random.uniform(0.70, 1.00), 2)

    billing_list.append({
        "admission_id": int(row['admission_id']),
        "department_id": int(row['department_id']),
        "patient_id": int(row['patient_id']),
        "charge_amount": charge,
        "cost_amount": cost,
        "insurance_paid": ins_paid,
        "patient_paid": pat_paid
    })
df_billing = pd.DataFrame(billing_list)
df_billing.to_csv(raw_dir / 'billing.csv', index=False)
print(f"Generated {len(df_billing)} billing entries.")

# 7. Generate Satisfaction Surveys (Fact/Feedback Table)
surveys_list = []
for index, row in df_admissions.dropna(subset=['admission_id']).drop_duplicates(subset=['admission_id']).iterrows():
    # Higher wait time -> lower satisfaction. High severity -> lower satisfaction.
    wait_factor = row['wait_minutes'] / 30.0
    base_sat = 88.0

    sat = round(max(0.0, min(100.0, np.random.normal(base_sat - wait_factor - (row['severity_score'] * 1.5), 10.0))), 1)

    adm_dt = pd.to_datetime(row['admission_date'])
    resp_dt = adm_dt + pd.Timedelta(days=row['length_of_stay'] + np.random.randint(1, 15))

    surveys_list.append({
        "admission_id": int(row['admission_id']),
        "patient_id": int(row['patient_id']),
        "department_id": int(row['department_id']),
        "satisfaction_score": sat,
        "response_date": resp_dt.strftime('%Y-%m-%d')
    })
df_surveys = pd.DataFrame(surveys_list)
df_surveys.to_csv(raw_dir / 'satisfaction_surveys.csv', index=False)
print(f"Generated {len(df_surveys)} satisfaction surveys.")

# 8. Generate Clinical Treatments (Fact Table)
treatments_list = []
treatment_counter = 1
for index, row in df_admissions.dropna(subset=['admission_id']).drop_duplicates(subset=['admission_id']).iterrows():
    # Each stay has 1 to 4 treatments/procedures
    num_procs = np.random.randint(1, 5)
    for _ in range(num_procs):
        proc_code = f"PROC-{np.random.choice([110, 220, 310, 410, 510])}"
        proc_cost = round(np.random.uniform(200.0, 1800.0), 2)
        treatments_list.append({
            "treatment_id": treatment_counter,
            "admission_id": int(row['admission_id']),
            "procedure_code": proc_code,
            "treatment_cost": proc_cost
        })
        treatment_counter += 1
df_treatments = pd.DataFrame(treatments_list)
df_treatments.to_csv(raw_dir / 'treatments.csv', index=False)
print(f"Generated {len(df_treatments)} treatments.")

print("\n--- Relational CSV Generation Completed Successfully! ---")
