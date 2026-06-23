# Healthcare Operations Analytics & Patient Flow Optimization

[![SQL](https://img.shields.io/badge/Database-PostgreSQL%20%7C%20Postgres-blue?logo=postgresql&logoColor=white)](https://github.com/ravi020410/healthcare-operations-analytics/tree/main/sql)
[![Python](https://img.shields.io/badge/Language-Python%203.11-darkgreen?logo=python&logoColor=white)](https://github.com/ravi020410/healthcare-operations-analytics/tree/main/notebooks)
[![Power BI](https://img.shields.io/badge/BI-Power%20BI-yellow?logo=powerbi&logoColor=white)](https://github.com/ravi020410/healthcare-operations-analytics/tree/main/dashboards)

An end-to-end hospital operations and financial analytics project. This project implements a fully normalized analytical PostgreSQL database, automated Python ETL notebooks, patient cohort modeling, and billing audits to bridge patient admission records, staff capacities, and treatment costs into actionable executive clinical strategies.

---

## 📂 Project Architecture & Repository Structure

The data flow starts from raw clinical transaction CSV logs, runs through Python quality validation, aggregates doctor and patient metrics in a PostgreSQL data warehouse, and concludes with dynamic visualization and statistical modeling.

```text
├── data/
│   ├── raw/             # Messiah, uncleaned clinical source-like CSV files
│   └── cleaned/         # Cleaned, structured, and validated CSV files
├── sql/
│   ├── 01_schema.sql                      # DDL defining analytics schema
│   ├── 02_load_csv.sql                    # CSV bulk copy stubs
│   ├── 03_kpi_queries.sql                 # Baseline checks
│   ├── 04_quality_checks.sql              # Duplicate and integrity auditing
│   ├── 05_analysis_queries.sql            # Simple operational growth queries
│   └── 20_business_analysis_queries.sql   # 22 Advanced PostgreSQL Business Queries (LOS, Occupancy, Readmissions)
├── notebooks/
│   ├── 01_eda.ipynb                       # Patient demographic & geographic distribution
│   ├── 02_data_cleaning.ipynb             # Null imputation, logic checks, date consistency
│   ├── 03_feature_engineering.ipynb      # Length of Stay (LOS), procedure costs, write-off risks
│   ├── 04_visualization.ipynb             # Seaborn & Matplotlib custom analytical plots
│   └── 05_business_insights.ipynb         # Bed occupancy and Random Forest Readmission Drivers
├── dashboards/            # Theme templates and specifications for Power BI dashboards
├── visuals/               # Exported PNGs, wait-time plots, and feature importances
└── scripts/               # Automated Python execution scripts for cleaning and loading
```

---

## 📈 Hospital Operational KPIs (Calculated Baseline)

These high-level metrics are computed from the historical patient admission, staffing, and billing database, ensuring an auditable and mathematically consistent baseline:

| Healthcare Metric | Calculated Value | Business Significance |
|:---|---:|:---|
| **30-Day Readmission Rate** | **10.7%** | Core quality indicator (Target under 11.5% to avoid penalties). |
| **Bed Occupancy Rate** | **14.2%** | Average capacity utilization (Highlights room for expansion). |
| **Doctor Clinical Utilization** | **38.3%** | Mean workload share across active medical personnel. |
| **Revenue per Department** | **$17.8M** | Highest average charges driven by Cardiology and Surgery lines. |
| **Discharge Efficiency Score** | **87.9%** | Efficiency index of patient release processes (Goal: >85%). |
| **Emergency Admission Rate** | **38.1%** | Total cases entering through ER triage relative to elective admissions. |

---

## 🛠️ Tech Stack & Key Libraries
- **Database:** PostgreSQL (v12+) — custom schema design, indexes, multi-stage CTEs, window functions.
- **Languages:** Python (v3.11), T-SQL/PostgreSQL, Power BI DAX.
- **Python Ecosystem:**
  - `pandas` & `numpy` — high-performance data wrangling, feature engineering, DDL mocks.
  - `matplotlib` & `seaborn` — publication-quality custom static plots and heatmaps.
  - `scikit-learn` — Random Forest Classifier used to isolate feature importances driving readmissions.
- **BI Platform:** Power BI Desktop — Star schema modeling, time-intelligence DAX measures.

---

## 📊 Core Analytical Highlights & Visuals

### 1. Patient Readmission Drivers (from [05_business_insights.ipynb](notebooks/05_business_insights.ipynb))
Using engineered variables (including length of stay, ER wait times, severity scores, and procedural charges), we trained a classification tree to mathematically rank why patients are readmitted:
1. **Length of Stay (LOS):** Longer stays are the highest predictor of subsequent 30-day readmissions.
2. **Discharge Efficiency:** Shorter, hasty patient releases significantly increase readmission rates.
3. **Severity Score:** Higher triage severity levels naturally exhibit greater recurring care needs.

### 2. PostgreSQL Business Engine (from [20_business_analysis_queries.sql](sql/20_business_analysis_queries.sql))
Contains **22 advanced PostgreSQL scripts** that answer critical business questions, such as:
- **Query 2 (Bed Occupancy Rate):** Joins beds staffed and licensed records with actual stay durations. Tracks bed congestion by medical department.
- **Query 5 (Geriatric Readmissions):** Computes readmission rates specifically across geriatric cohorts to isolate senior care gaps.
- **Query 14 (Billing Leak Diagnosis):** Financial audit checking cases where direct clinical procedure costs exceed final patient charges (identifying billing leakage).

---

## 🎯 Strategic Hospital Recommendations

Based on the quantitative findings from our SQL and Python pipelines, we propose three tactical focus areas for hospital leadership:

1. **ER Wait Time Optimizations:** Since Emergency stays represent **38.1%** of all cases and wait times strongly correlate with patient satisfaction, restructuring triage protocols during peak hours can significantly improve satisfaction scores.
2. **Discharge Efficiency Standardizations:** Our analysis surfaces an overall **Discharge Efficiency score of 87.9%**, but also shows that hasty, low-efficiency discharges significantly spike 30-day readmissions. Implementing a clinical discharge checklist can help maintain optimal standards.
3. **Targeted Bed Allocation:** Reallocate staffed beds to departments displaying over-utilization (as surfaced in our Bed Occupancy Analysis) to optimize overall hospital patient flow.

---

## 🚀 How to Run the Analysis

### 1. Prerequisites
Ensure you have Python 3.11 installed locally, along with a PostgreSQL server instance.

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Database Schema Setup
1. Create a database called `healthcare_analytics`.
2. Execute the DDL script in your database shell or query tool:
   ```bash
   psql -U postgres -d healthcare_analytics -f sql/01_schema.sql
   ```
3. Load the cleaned CSV tables located under `data/cleaned/` into your corresponding schema tables.

### 4. Run Notebooks
Open VS Code or Jupyter and step through the files in `notebooks/` chronologically from `01_eda.ipynb` to `05_business_insights.ipynb` to see the full data-cleaning, engineering, and predictive modeling pipeline.

---

## 👤 Author
**Ravikant Yadav**  
*Data Analyst & Business Intelligence Specialist*  
- **Email:** [yadavravikant597@gmail.com](mailto:yadavravikant597@gmail.com)  
- **LinkedIn:** [Ravikant Yadav](https://www.linkedin.com/in/ravikant-yadav)  
- **GitHub:** [ravi020410](https://github.com/ravi020410)
