# Healthcare Operations Analytics Portfolio Project

[![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue?style=flat&logo=postgresql)](https://github.com/ravi020410/healthcare-operations-analytics/tree/main/sql)
[![Python](https://img.shields.io/badge/Python-pandas%20%7C%20numpy%20%7C%20scikit--learn-blue?style=flat&logo=python)](https://github.com/ravi020410/healthcare-operations-analytics/tree/main/notebooks)
[![BI](https://img.shields.io/badge/BI-Power%20BI-yellow?style=flat)](https://github.com/ravi020410/healthcare-operations-analytics/tree/main/dashboards)

**Author:** Ravikant Yadav, Lead Data Analyst  
**Case Study:** Clinical Operations Optimization, Financial Modeling, and Readmission Risk Machine Learning  

---

## 1. Project Overview & Business Problem

In hospital network management, operational bottlenecks (long wait times, capacity shortages) directly reduce patient care quality while causing financial leaks (excessive readmissions, unrecovered billing balances). 

This project delivers a **production-style, end-to-end analytical solution** utilizing a normalized PostgreSQL relational database, advanced SQL CTEs/window queries, distinct Python exploratory, ETL/cleaning, and engineering pipelines, and an analytical **scikit-learn machine learning classifier** to predict patient readmission risks. 

---

## 2. Relational Database Data Model

We modeled our transactional operations into a highly efficient **relational star schema** in PostgreSQL (see [sql/01_schema.sql](sql/01_schema.sql)):

```
                       +-------------------+
                       |    patients       |
                       +-------------------+
                                 | 1
                                 |
                                 | *
+-------------------+  * +-------------------+ *  +-------------------+
|    doctors        |----+ Inpatient Stays   |----+    departments     |
+-------------------+ 1  | (admissions)      | 1  +-------------------+
                         +-------------------+              | 1
                                 | 1                        |
                                 |                          | *
                                 | *                        |
                       +-------------------+                |
                       |    billing        |----------------+
                       +-------------------+
                                 | 1
                                 |
                                 | *
                       +-------------------+
                       |    treatments     |
                       +-------------------+
```

### Table Definitions & Keys:
1. **`departments`** (Reference Table): Core clinical divisions and service lines.
2. **`beds`** (Reference Table): Staffed and licensed bed counts per department.
3. **`patients`** (Dimension Table): Demographic profiles, location, and insurance types.
4. **`doctors`** (Dimension Table): Care provider names, medical lines, and employment status.
5. **`admissions`** (Fact Table): Admission types, length of stay, wait times, severity scores, and readmission targets.
6. **`billing`** (Financial Fact Table): Patient charges, direct operating costs, insurance payments, and out-of-pocket metrics.
7. **`satisfaction_surveys`** (Fact Table): Post-discharge satisfaction scores and response timelines.
8. **`treatments`** (Fact Table): Specific procedure codes and treatment expenses.

---

## 3. Executive KPI Dashboard Scorecard

Every clinical and financial metric is fully auditable and reconciles to our normalized relational tables (see [reports/executive_report.md](reports/executive_report.md)):

| Hospital Performance KPI | Cleaned Empirical Value | Business Domain Interpretation |
|---|---|---|
| **Total Admissions** | **45,000** | Full patient volume tracked over 3-year cycle (2023 - 2025). |
| **Inpatient Length of Stay (LOS)** | **4.0 Days** | Smooth baseline inpatient capacity metric. |
| **30-Day Readmission Rate** | **7.0%** | Quality of clinical transition and care standards. |
| **Triage Patient Wait Time** | **27.1 Mins** | Operational throughput efficiency in emergency/urgent care. |
| **Patient Satisfaction Score** | **79.6%** | Patient experience rating (out of 100). |
| **Gross Billings Revenue** | **$251.7M** | Consolidated gross medical charges generated. |

---

## 4. Advanced PostgreSQL Query Examples

To showcase complex relational data engineering capability, we authored **22 production-grade PostgreSQL analytical queries** (see [sql/20_business_analysis_queries.sql](sql/20_business_analysis_queries.sql)). Highlights include:

### A. 3-Month Moving Average of Monthly Admissions (CTEs & LAG Windowing)
Calculates net month-over-month volume change and smoothes seasonality trends using multi-row partition framing.
```sql
WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', admission_date)::DATE AS admission_month,
        COUNT(admission_id) AS admissions_count
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    admission_month,
    admissions_count,
    admissions_count - LAG(admissions_count) OVER (ORDER BY admission_month) AS mom_admission_change,
    ROUND(AVG(admissions_count) OVER (
        ORDER BY admission_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) AS moving_avg_3m_admissions
FROM monthly_counts;
```

### B. Statistical Triage Wait-Time Outliers (3x Standard Deviations)
Identifies extreme patient wait times exceeding 3 standard deviations from the department's mean, isolating operational bottlenecks.
```sql
WITH wait_stats AS (
    SELECT
        department_id,
        AVG(wait_minutes) AS avg_wait,
        STDDEV(wait_minutes) AS std_wait
    FROM analytics.admissions
    GROUP BY 1
)
SELECT
    a.admission_id,
    p.patient_name,
    dept.department,
    a.wait_minutes,
    ROUND((a.wait_minutes - ws.avg_wait) / ws.std_wait, 2) AS z_score
FROM analytics.admissions a
JOIN analytics.patients p ON a.patient_id = p.patient_id
JOIN analytics.departments dept ON a.department_id = dept.department_id
JOIN wait_stats ws ON a.department_id = ws.department_id
WHERE a.wait_minutes > (ws.avg_wait + (3 * ws.std_wait));
```

---

## 5. Python Data Science & Machine Learning Pipeline

Our analytical pipeline is divided into **5 structured, highly documented Jupyter Notebooks** located under [notebooks/](notebooks/):

1. **`01_eda.ipynb`** (Exploratory Data Analysis): Profiles clinical variables, maps distributions, and generates correlation heatmaps.
2. **`02_data_cleaning.ipynb`** (Deduplication & Outlier Clipping): Performs logical type casting, checks date constraints, and applies a **3x IQR statistical clipping** to remove billing outliers.
3. **`03_feature_engineering.ipynb`** (Indicator Creation): Engineers weekend admission flags, patient age groupings, procedure aggregations, and financial profit margin fields.
4. **`04_visualization.ipynb`** (Interactive Dashboards): Plots boxplots of wait times, violin plots of satisfaction, and generates interactive Scatter plots.
5. **`05_business_insights.ipynb`** (Predictive Modeling): Trains a **Random Forest Classifier** to predict **30-day patient readmissions** (ROC-AUC: **0.78**), isolating **Discharge Efficiency** and **Patient Age** as the top mathematical risk predictors.

---

## 6. Strategic Business & Administrative Recommendations

1. **Weekend Shift Rebalancing:** Increase triage nurse capacity by **15% on weekend evenings** to address the 35% wait-time spike identified on Fridays/Saturdays.
2. **Clinical Transition-of-Care checklists:** Mandate standardized pre-discharge checkups for patients with low discharge efficiency ratings. Patients discharged under high clinical rush (low efficiency) exhibit a **3.4x readmission probability**.
3. **Targeted Bed Reallocation:** Move **15% of staffed beds** from under-utilized Primary Care wards (currently under 45% occupancy) to Cardiology and Acute Care wings (operating at over 85% capacity).

---

## 7. How To Re-Run End-to-End

### Prerequisites
Install all requirements:
```bash
python -m pip install -r requirements.txt
```

### Execution Flow
1. **Regenerate Raw Relational Data:**
   ```bash
   python scripts/generate_data.py
   ```
2. **Execute Clinical ETL Cleaning & Modeling:**
   ```bash
   python scripts/clean_data.py
   ```
3. **Perform Automated Constraint & Integrity Assertions:**
   ```bash
   python scripts/validate_data.py
   ```

---

## 8. Portfolio Resume Alignment

This project establishes the technical credentials listed in my resume:
* **Relational Database Design:** Normalization of dimension and fact tables, indices, and constraints in PostgreSQL.
* **Advanced Query Engineering:** Window aggregates, CTE joins, DDL schemas, and outlier detection models.
* **Programmatic Data Science:** Outlier treatment, feature construction, interactive Plotly visualization, and Random Forest classification using scikit-learn.
* **Strategic Business Alignment:** Translating technical statistical summaries into actionable operating plans for executive leadership.
