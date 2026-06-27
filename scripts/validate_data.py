"""
Automated Relational & Domain Data Integrity Validation Suite
Author: Ravikant Yadav
Description: Executes strict data-quality and logical assertions over cleaned files,
             verifying constraints, primary keys, null boundaries, and referential integrity.
"""

from pathlib import Path
import pandas as pd
import sys

# Base directories
ROOT = Path(__file__).resolve().parents[1]
data_dir = ROOT / 'data' / 'processed'

print("Starting Automated Data Validation Checks...")

def run_validation():
    failures = []

    # 1. Check all required files exist
    required_files = [
        'departments.csv', 'beds.csv', 'doctors.csv', 'patients.csv',
        'admissions.csv', 'billing.csv', 'satisfaction_surveys.csv', 'treatments.csv'
    ]

    for f in required_files:
        p = data_dir / f
        if not p.exists():
            failures.append(f"Missing File: {f} does not exist in data/processed.")
            continue

        df = pd.read_csv(p)
        if df.empty:
            failures.append(f"Empty File: {f} is completely empty.")
            continue
        print(f"File Verified: {f} ({len(df)} records)")

    if failures:
        print("\nCritical structural failures detected:")
        print("\n".join(failures))
        sys.exit(1)

    # 2. Ingest clean dataframes for relational checks
    depts = pd.read_csv(data_dir / 'departments.csv')
    beds = pd.read_csv(data_dir / 'beds.csv')
    docs = pd.read_csv(data_dir / 'doctors.csv')
    patients = pd.read_csv(data_dir / 'patients.csv')
    admissions = pd.read_csv(data_dir / 'admissions.csv')
    billing = pd.read_csv(data_dir / 'billing.csv')
    surveys = pd.read_csv(data_dir / 'satisfaction_surveys.csv')
    treatments = pd.read_csv(data_dir / 'treatments.csv')

    # 3. Uniqueness Checks (Primary Keys)
    uniqueness_assertions = {
        'departments.csv (department_id)': depts['department_id'].duplicated().sum(),
        'beds.csv (department_id)': beds['department_id'].duplicated().sum(),
        'doctors.csv (doctor_id)': docs['doctor_id'].duplicated().sum(),
        'patients.csv (patient_id)': patients['patient_id'].duplicated().sum(),
        'admissions.csv (admission_id)': admissions['admission_id'].duplicated().sum(),
        'billing.csv (admission_id)': billing['admission_id'].duplicated().sum(),
    }

    for key, duplicates in uniqueness_assertions.items():
        if duplicates > 0:
            failures.append(f"Constraint Violation: {key} contains {duplicates} duplicate keys.")
        else:
            print(f"Primary Key Assertion Passed: {key}")

    # 4. Referential Integrity Checks (Foreign Keys)
    # Check admissions refer to valid patients
    dangling_patients = admissions[~admissions['patient_id'].isin(patients['patient_id'])]
    if not dangling_patients.empty:
        failures.append(f"Referential Violation: {len(dangling_patients)} admissions refer to invalid patient_id.")

    # Check admissions refer to valid doctors
    dangling_doctors = admissions[~admissions['doctor_id'].isin(docs['doctor_id']) & admissions['doctor_id'].notnull()]
    if not dangling_doctors.empty:
        failures.append(f"Referential Violation: {len(dangling_doctors)} admissions refer to invalid doctor_id.")

    # Check billing records map to valid admissions
    dangling_billing = billing[~billing['admission_id'].isin(admissions['admission_id'])]
    if not dangling_billing.empty:
        failures.append(f"Referential Violation: {len(dangling_billing)} billing records are orphaned (invalid admission_id).")

    # 5. Critical Missingness & Logical Range Checks
    null_admissions = admissions['admission_date'].isnull().sum()
    if null_admissions > 0:
        failures.append(f"Null Violation: admissions.csv contains {null_admissions} missing admission dates.")

    negative_charges = (billing['charge_amount'] < 0).sum()
    if negative_charges > 0:
        failures.append(f"Domain Violation: billing.csv contains {negative_charges} negative charge values.")

    invalid_satisfaction = surveys[(surveys['satisfaction_score'] < 0) | (surveys['satisfaction_score'] > 100)]
    if not invalid_satisfaction.empty:
        failures.append(f"Domain Violation: surveys.csv contains {len(invalid_satisfaction)} scores out of [0, 100] bounds.")

    # 6. Conclusion
    print("\n--- Validation Summary ---")
    if failures:
        print(f"FAILED: Verification Failed with {len(failures)} errors:")
        for err in failures:
            print(f"  - {err}")
        sys.exit(1)
    else:
        print("SUCCESS: All Relational and Domain Integrity Constraints Passed!")
        sys.exit(0)

if __name__ == "__main__":
    run_validation()
