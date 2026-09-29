# Data Architecture & Relational Star Schema


## Entity-Relationship Diagram (PostgreSQL Star Schema)

```mermaid
erDiagram
    DEPARTMENTS ||--o{ DOCTORS : "employs (1:N)"
    DEPARTMENTS ||--o{ ADMISSIONS : "hosts (1:N)"
    DOCTORS ||--o{ ADMISSIONS : "treats (1:N)"
    PATIENTS ||--o{ ADMISSIONS : "undergoes (1:N)"
    ADMISSIONS ||--o| BILLING : "generates (1:1)"
    ADMISSIONS ||--o{ TREATMENTS : "administers (1:N)"
    ADMISSIONS ||--o| SATISFACTION_SURVEYS : "receives (1:0..1)"

    DEPARTMENTS {
        smallint department_id PK
        varchar department
        smallint staffed_beds
    }
    DOCTORS {
        int doctor_id PK
        varchar doctor_name
        smallint department_id FK
        varchar employment_status
        smallint years_experience
    }
    PATIENTS {
        int patient_id PK
        varchar patient_name
        date date_of_birth
        varchar gender
        varchar state "Intake audit flag"
        varchar insurance_type "Intake audit flag"
    }
    ADMISSIONS {
        int admission_id PK
        int patient_id FK
        int doctor_id FK
        smallint department_id FK
        timestamp admission_date
        timestamp discharge_date
        varchar admission_type
        numeric severity_score
        numeric length_of_stay_days
        int wait_minutes
        numeric discharge_efficiency
        smallint readmitted_30d
        varchar department_raw_text_original
    }
    BILLING {
        int billing_id PK
        int admission_id FK
        numeric gross_charge
        numeric insurance_payment
        numeric patient_out_of_pocket
        numeric direct_operating_cost
    }
    TREATMENTS {
        int treatment_id PK
        int admission_id FK
        varchar procedure
        numeric treatment_cost
    }
    SATISFACTION_SURVEYS {
        int survey_id PK
        int admission_id FK
        numeric satisfaction_score
        smallint response_days_after_discharge
    }
```

---

## Relational Data Model Specifications

| Entity Name | Database Object | Primary Key | Foreign Keys | Relationship Type | Record Volume | Description |
|---|---|---|---|---|---|---|
| **Admissions** | `analytics.admissions` | `admission_id` | `patient_id`, `doctor_id`, `department_id` | Central Fact Table | 46,500 rows | Clinical encounter facts capturing admission/discharge timestamps, admission acuity, length of stay (LOS), triage wait, discharge efficiency index, and 30-day readmission status. |
| **Patients** | `analytics.patients` | `patient_id` | None | Dimension (1:N with Admissions) | 18,000 rows | Longitudinal patient master tracking demographics, age cohort, geographic state, and primary health insurance coverage (16,606 with active encounter history). |
| **Doctors** | `analytics.doctors` | `doctor_id` | `department_id` | Dimension (1:N with Admissions) | 140 rows | Attending medical provider master holding physician name, department assignment, employment contract status, and clinical tenure. |
| **Departments** | `analytics.departments` | `department_id` | None | Dimension (1:N with Admissions/Doctors) | 10 rows | Operating clinical units (ICU, Oncology, Cardiology, Emergency, etc.) along with licensed staffed bed counts. |
| **Billing** | `analytics.billing` | `billing_id` | `admission_id` | Secondary Fact (1:1 with Admissions) | 46,500 rows | Encounter financial ledger recording gross charge billings, insurance reimbursements, patient out-of-pocket payments, and operating costs. |
| **Treatments** | `analytics.treatments` | `treatment_id` | `admission_id` | Secondary Fact (1:N with Admissions) | 79,050 rows | Clinical interventions and procedure logging detailing diagnostic tests, surgical interventions, and direct procedural supply costs. |
| **Satisfaction Surveys** | `analytics.satisfaction_surveys` | `survey_id` | `admission_id` | Secondary Fact (1:0..1 with Admissions) | 26,970 rows | Post-discharge patient experience surveys measuring patient satisfaction ratings (0–100 scale) and survey turnaround duration. |

---


