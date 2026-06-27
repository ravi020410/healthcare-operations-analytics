# Healthcare Operations Analytics - Executive Report
**Author:** Ravikant Yadav, Lead Data Analyst  
**Date:** June 27, 2026  

---

## 1. Executive Summary

- **Relational Integrity End-to-End:** This project successfully models real hospital operations, transitioning from raw clinical transactions to advanced PostgreSQL relational models, pandas feature-engineering scripts, and predictive scikit-learn models.
- **Auditable Data Pipeline:** Every clinical and financial metric reported here is backed by reproducible, normalized relational tables under `data/processed/`, verified by an automated validation suite.
- **Unit Economics Focus:** The project quantifies clinical quality metrics (length of stay, readmission risk) alongside financial performance (margins, insurance-reimbursement write-offs), highlighting operational cost drivers.

---

## 2. Key Findings & Empirical Evidence

- **Total Patient Volume:** **45,000** unique admissions tracked over a 3-year cycle (2023 - 2025).
- **Average Length of Stay (LOS):** **4.0 Days** average inpatient-stay duration.
- **30-Day Readmission Frequency:** **7.0%** readmission rate overall, indicating solid care transition standards but significant spikes in high-severity segments.
- **Average Patient Wait Time:** **27.1 Minutes** triage duration from arrival to doctor consult.
- **Patient Care Experience:** **79.6%** average patient satisfaction score across all departments.
- **Aggregate Hospital Billing Revenue:** **$251.7 Million** gross charges generated, with Specialty segments (Cardiology, Oncology, ICU) driving over **55%** of gross margins.

---

## 3. Operational Insights & Bottlenecks

### A. Triage Flow Bottlenecks
Triage patient wait times average 27.1 minutes overall, but boxplot analysis reveals that **Emergency and Urgent admissions** encounter severe outliers exceeding **90 minutes** during peak days. Our temporal analysis indicates wait times spike by **35% on weekends**, highlighting clinical staffing shortages during weekend shifts.

### B. Readmission Risk Drivers (Predictive AI)
By training a **Random Forest Classifier** to predict 30-day readmissions, we identified that the **Discharge Efficiency Score** and **Patient Age** are the two strongest mathematical predictors of readmission. Patients discharged under high clinical rush (low efficiency scores) have a **3.4x higher readmission probability**.

### C. Capacity Constraints (Bed Utilization)
Bed occupancy analysis reveals that **Cardiology and ICU** operate at near-capacity thresholds (exceeding **85% bed occupancy**), while Primary Care segments operate under **45% occupancy**, indicating a clear resource misalignment.

---

## 4. Business & Administrative Recommendations

1. **Weekend Staffing Rebalancing:** Restructure clinical shift scheduling to increase triage nurse capacity by **15% on Friday and Saturday evenings** to directly reduce emergency wait times.
2. **Clinical Transition-of-Care checklists:** Mandate a standardized clinical discharge audit for geriatric patients and high-risk admissions. If discharge efficiency scores fall below **80%**, trigger an automatic outpatient telehealth follow-up within **48 hours** to lower 30-day readmissions.
3. **Bed Space Reallocation:** Reallocate **15% of underutilized beds** from Primary Care/Pediatrics lines to Cardiology and Acute Care wards to resolve occupancy bottlenecks and lower wait-times.
