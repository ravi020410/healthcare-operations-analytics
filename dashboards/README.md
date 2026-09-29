# Power BI Executive Dashboard Suite
### Hospital Operations, Financial Performance & Clinical Quality Analytics

This directory contains the production-grade **3-page Power BI executive report** (`healthcare_operations_analytics.pbix`) modeled on **46,500 patient encounters across 2023–2025**, 10 clinical hospital departments, and 120 attending physicians.

---


## 📊 Executive Visual Walkthrough

### Page 1: Executive Operations Summary
*High-level hospital throughput, seasonal encounter volumes, bed capacity utilization, and department-level benchmarking.*

![Page 1: Executive Operations Summary](../visuals/powerbi/01_executive_summary.jpg)

#### Strategic Operational Insights:
* **Encounter Volume & Capacity:** 46,500 total inpatient admissions across 36 months, with a system-wide average length of stay (LOS) of **5.25 days**.
* **Seasonal Admissions Trajectory:** Tracks monthly admissions with a **3-Month Moving Average** overlay to smooth winter intake surges (December–January peaks) against summer troughs.
* **Severe Bed Bottlenecks:** Identifies critical capacity constraints in **Oncology (101.0% occupancy)** and the **ICU (99.1% occupancy)**, contrasting with underutilized beds in Cardiology (60.5%) and Obstetrics (59.6%).
* **Triage Wait Efficiency:** Average intake triage wait sits at **24.2 minutes**, with no statistically meaningful variance between weekdays (24.1 min) and weekends (24.3 min).

---

### Page 2: Financial Operations & Profitability
*Department-level gross billing, direct operational costs, net operating margins, and payer reimbursement collection ratios.*

![Page 2: Financial Operations](../visuals/powerbi/02_financial_operations.jpg)

#### Financial Performance Drivers:
* **Top-Line Financial Health:** Generates **$499.3M in cumulative gross charges** against **$274.6M in direct operating costs**, yielding an enterprise gross operating margin of **$224.7M (45.0% margin)**.
* **Department Margin Contributions:** **Emergency** drives the largest volume and top-line billings ($86.8M billings / $39.0M margin), followed by **Cardiology** ($61.2M billings / $27.6M margin) and **Pediatrics** ($55.4M billings / $25.0M margin).
* **Payer Mix Dynamics:** Analyzes insurance reimbursements versus patient out-of-pocket collections across commercial HMO/PPO, Medicare, Medicaid, and Self-Pay cohorts.

---

### Page 3: Clinical Quality & 30-Day Readmission Risk
*Clinical discharge efficiency, acuity-adjusted length of stay, and 30-day inpatient readmission drivers.*

![Page 3: Clinical Quality](../visuals/powerbi/03_clinical_quality.jpg)

#### Clinical Quality & Risk Insights:
* **3.58x Relative Readmission Risk:** Discharges scoring in the lowest efficiency band (0-40, indicating premature or rushed transitions) experience a **35.71% readmission rate**, compared to just **7.73%** for optimal discharges (80–100).
* **Clinical Acuity vs. Readmissions:** Patient severity score and discharge transition quality are the two leading predictive drivers of post acute clinical deterioration.
* **Hig Risk Patient Queue:** Identifies clinical cohorts requiring prioritized post-discharge follow up calls, home health coordination, and medication reconciliation within 48 hours.

---



