# Power BI Report Engineering & Implementation Guide
### Hospital Network Operations & Clinical Quality Analytics (`healthcare_operations_analytics.pbix`)

This technical implementation guide documents the data modeling, relational star-schema architecture, DAX business logic, and visual layout specifications for the interactive 3-page Power BI executive report suite (`dashboards/healthcare_operations_analytics.pbix`).

---

## 1. Data Ingestion & Source Configuration

### Source Data Files
Load the following cleaned and curated CSV datasets via **Get Data → Text/CSV** (or connect directly to PostgreSQL 14+ via `Get Data → PostgreSQL Database` pointing to server `localhost`, database `hospitaldb`, schema `analytics`):

1. `data/cleaned/admissions_features.csv` (Central Fact Table — 46,500 patient encounter records)
2. `data/raw/billing.csv` (Encounter Financial Ledger — 46,500 billing lines)
3. `data/raw/departments.csv` (Clinical Department Dimension — 10 hospital units & bed capacities)
4. `data/raw/doctors.csv` (Physician Master Dimension — 120 attending physicians)
5. `data/raw/patients.csv` (Patient Demographics Dimension — 10,000 unique patients)
6. `data/raw/satisfaction_surveys.csv` (Post-Discharge Experience Fact Table — 26,970 survey responses)

### Power Query Data Type Transformation & Validation
Upon initial ingestion, verify and apply the following explicit data type mappings:

* **Dates & Timestamps:**
  * `admissions_features[admission_date]` → `Date` (Ensure date-only casting to support single-active relationship with Date dimension)
  * `admissions_features[discharge_date]` → `Date`
  * `patients[date_of_birth]` → `Date`
* **Clinical & Operational Numerics:**
  * `admissions_features[length_of_stay_days]` → `Decimal Number`
  * `admissions_features[wait_minutes]` → `Whole Number`
  * `admissions_features[discharge_efficiency]` → `Decimal Number`
  * `admissions_features[severity_score]` → `Decimal Number`
  * `satisfaction_surveys[satisfaction_score]` → `Decimal Number`
  * `departments[staffed_beds]` → `Whole Number`
* **Currencies & Financial Numerics:**
  * `billing[gross_charge]`, `billing[insurance_payment]`, `billing[patient_out_of_pocket]`, `billing[direct_operating_cost]` → `Decimal Number` (Format as Currency `$`)
* **Booleans & Encodings:**
  * `admissions_features[readmitted_30d]` → `Whole Number` (1 = Readmitted, 0 = Not Readmitted)

---

## 2. Dedicated Calendar Dimension Table (DAX)

To support standardized time intelligence and continuous multi-year date filtering without relying on auto-date/time hierarchies, construct a dedicated DAX Date dimension:

```dax
Calendar = 
ADDCOLUMNS (
    CALENDAR ( DATE ( 2023, 1, 1 ), DATE ( 2025, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "mmm yyyy" ),
    "Month Sort", FORMAT ( [Date], "yyyy-mm" ),
    "Quarter", "Q" & FORMAT ( [Date], "q yyyy" ),
    "Quarter Number", QUARTER ( [Date] ),
    "Day of Week", FORMAT ( [Date], "dddd" ),
    "Day Number", WEEKDAY ( [Date], 2 ),
    "Is Weekend", IF ( WEEKDAY ( [Date], 2 ) >= 6, TRUE (), FALSE () )
)
```

* **Configuration:** Select `Calendar`, navigate to **Table tools → Mark as date table**, and specify `[Date]` as the unique date column.
* **Sort Hierarchy:** Select the `Month` column and set **Column tools → Sort by column → Month Sort**.

---

## 3. Data Model Relationships (Star Schema)

In **Model view**, establish the relational star-schema topology. All relationships follow strict 1-to-many cardinality with single-direction cross-filtering (dimensions filtering facts):

| From Table (Many Side / Fact) | To Table (One Side / Dimension) | Foreign Key | Primary Key | Cardinality | Cross Filter | Active |
|---|---|---|---|---|---|---|
| `admissions_features` | `departments` | `department_id` (or `department`) | `department_id` (or `department`) | Many-to-One (`*:1`) | Single (`departments` filters `admissions`) | Yes |
| `admissions_features` | `doctors` | `doctor_id` | `doctor_id` | Many-to-One (`*:1`) | Single (`doctors` filters `admissions`) | Yes |
| `admissions_features` | `patients` | `patient_id` | `patient_id` | Many-to-One (`*:1`) | Single (`patients` filters `admissions`) | Yes |
| `admissions_features` | `Calendar` | `admission_date` | `Date` | Many-to-One (`*:1`) | Single (`Calendar` filters `admissions`) | Yes |
| `billing` | `admissions_features` | `admission_id` | `admission_id` | One-to-One (`1:1`) | Both | Yes |
| `satisfaction_surveys` | `admissions_features` | `admission_id` | `admission_id` | Many-to-One (`*:1`) | Single (`admissions` filters `surveys`) | Yes |

* **Best Practice:** Hide all foreign key columns in `admissions_features` (e.g., `patient_id`, `doctor_id`, `department_id`) from Report view to ensure clean report design.

---

## 4. DAX Business Measure Catalog

Create a dedicated measure table named `_Measures` via **Home → Enter Data** and implement the following production business calculations:

### Core Operational Volume & Capacity Measures
```dax
Total Admissions = 
COUNTROWS ( admissions_features )

Avg Length of Stay Days = 
AVERAGE ( admissions_features[length_of_stay_days] )

Total Inpatient Bed Days = 
SUM ( admissions_features[length_of_stay_days] )

Avg Triage Wait Minutes = 
AVERAGE ( admissions_features[wait_minutes] )

Avg Discharge Efficiency = 
AVERAGE ( admissions_features[discharge_efficiency] )

Avg Patient Satisfaction = 
AVERAGE ( admissions_features[satisfaction_score] )

Bed Occupancy Rate % = 
VAR TotalBedDays = SUM ( admissions_features[length_of_stay_days] )
VAR TotalAvailableBedDays = SUM ( departments[staffed_beds] ) * 1096
RETURN
    DIVIDE ( TotalBedDays, TotalAvailableBedDays, 0 )
```

### Clinical Quality & Readmission Analytics
```dax
Readmitted 30D Count = 
CALCULATE (
    COUNTROWS ( admissions_features ),
    admissions_features[readmitted_30d] = 1
)

Readmission Rate % = 
DIVIDE (
    [Readmitted 30D Count],
    [Total Admissions],
    0
)

Rushed Discharge Readmission Rate % = 
CALCULATE (
    [Readmission Rate %],
    admissions_features[discharge_efficiency_bucket] = "Rushed (0-40)"
)

Excellent Discharge Readmission Rate % = 
CALCULATE (
    [Readmission Rate %],
    admissions_features[discharge_efficiency_bucket] = "Excellent (80-100)"
)

Readmission Relative Risk = 
DIVIDE (
    [Rushed Discharge Readmission Rate %],
    [Excellent Discharge Readmission Rate %],
    0
)
```

### Financial Operations & Margin Analytics
```dax
Gross Billings = 
SUM ( billing[gross_charge] )

Total Operating Cost = 
SUM ( billing[direct_operating_cost] )

Total Gross Margin = 
[Gross Billings] - [Total Operating Cost]

Gross Margin % = 
DIVIDE ( [Total Gross Margin], [Gross Billings], 0 )

Total Insurance Payments = 
SUM ( billing[insurance_payment] )

Total Patient Out of Pocket = 
SUM ( billing[patient_out_of_pocket] )

Net Collection Rate % = 
DIVIDE (
    [Total Insurance Payments] + [Total Patient Out of Pocket],
    [Gross Billings],
    0
)
```

### Time Intelligence & Trend Forecasting
```dax
Admissions MoM Change = 
VAR CurrentMonth = [Total Admissions]
VAR PriorMonth = 
    CALCULATE (
        [Total Admissions],
        DATEADD ( 'Calendar'[Date], -1, MONTH )
    )
RETURN
    CurrentMonth - PriorMonth

Admissions 3-Month Moving Avg = 
AVERAGEX (
    DATESINPERIOD ( 'Calendar'[Date], LASTDATE ( 'Calendar'[Date] ), -3, MONTH ),
    [Total Admissions]
)
```

---

## 5. Visual Suite Construction Specifications

### Page 1: Executive Operations Summary
* **Header Band:** Hospital Network Title, Date Slicer (2023–2025), Department Multiselect Slicer.
* **Top KPI Scorecard (Multi-Row / Single KPI Cards):**
  * `[Total Admissions]` formatted as `46,500`
  * `[Avg Length of Stay Days]` formatted as `5.25 Days`
  * `[Readmission Rate %]` formatted as `13.25%`
  * `[Avg Triage Wait Minutes]` formatted as `24.2 min`
  * `[Gross Billings]` formatted as `$499.3M`
* **Seasonal Admissions Trajectory (Line and Clustered Column Chart):**
  * X-Axis: `Calendar[Month]` (sorted by `Month Sort`)
  * Column Values: `[Total Admissions]`
  * Line Values: `[Admissions 3-Month Moving Avg]`
* **Clinical Department Benchmark Matrix (Table):**
  * Rows: `departments[department]`
  * Values: `[Total Admissions]`, `[Avg Length of Stay Days]`, `[Readmission Rate %]`, `[Bed Occupancy Rate %]`

### Page 2: Financial Operations & Profitability
* **Header Band:** Financial Slicers, Admission Type Filter (Emergency, Urgent, Elective, Trauma).
* **KPI Scorecard:**
  * `[Gross Billings]` ($499.3M)
  * `[Total Operating Cost]` ($274.6M)
  * `[Total Gross Margin]` ($224.7M)
  * `[Gross Margin %]` (45.0%)
* **Department Billings vs. Operating Margins (Clustered Bar Chart):**
  * Y-Axis: `departments[department]`
  * Values: `[Gross Billings]` and `[Total Gross Margin]`
* **Payer Mix Collection Breakdown (Donut Chart / 100% Stacked Bar):**
  * Legend: Payer Category (Insurance vs. Out of Pocket)
  * Values: `[Total Insurance Payments]` vs. `[Total Patient Out of Pocket]`

### Page 3: Clinical Quality & 30-Day Readmission Risk
* **Header Band:** Clinical Quality Focus, Acuity Slicer (`severity_score`).
* **KPI Scorecard:**
  * `[Readmission Relative Risk]` (3.58x Callout Card)
  * `[Rushed Discharge Readmission Rate %]` (27.7%)
  * `[Excellent Discharge Readmission Rate %]` (7.7%)
* **Discharge Efficiency vs. Readmission Rate (Clustered Column Chart):**
  * X-Axis: `discharge_efficiency_bucket` (0–20, 20–40, 40–60, 60–80, 80–100)
  * Values: `[Readmission Rate %]` (demonstrating the clear 35.7% to 7.7% downward slope)
* **Triage Wait-Time Distribution by Day Type (Clustered Bar Chart):**
  * Category: Weekday vs. Weekend
  * Values: `[Avg Triage Wait Minutes]` (24.1 min vs. 24.3 min negative hypothesis verification)
* **High-Risk Readmission Clinical Queue (Table Visual):**
  * Columns: Patient ID, Department, Admission Date, Severity Score, Discharge Efficiency, Predicted Risk.
