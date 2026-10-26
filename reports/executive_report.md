# Hospital Operations & Clinical Analytics

---

## Why I Built This Project

I wanted to look at hospital operations the way an operational director or clinical operations manager does: balancing bed capacity, patient flow, financial margins, and readmissions. 

A lot of healthcare dashboards only show high-level summaries without digging into what's actually driving bottlenecks or clinical risks. Using 3 years of inpatient data, I wanted to answer four practical questions:
1. What operational factors are most strongly tied to 30-day patient readmissions?
2. Which hospital units are running at dangerously high bed capacity, and where do we have idle capacity?
3. Does triage wait time actually spike on weekends due to reduced staffing, or is that just an assumption?
4. How do departmental margins break down across emergency vs. elective stays?


---

## 1. Core Summary Numbers

| Metric | Result | Context / Meaning |
|---|---:|---|
| **Total Inpatient Admissions** | 46,500 | Cleaned encounters (removed 558 duplicate records and fixed 279 clock-sync errors) |
| **Average Length of Stay (ALOS)** | 5.25 days | Across 244,125 total inpatient bed-days |
| **30-Day Readmission Rate** | 13.25% | Baseline readmission rate (6,160 total readmissions) |
| **Average Triage Wait Time** | 24.2 min | Across all departments; 613 admissions had extreme delays (Z > 3) |
| **Average Discharge Score** | 68.6 / 100 | Composite operational efficiency score calculated at discharge |
| **Average Patient Satisfaction** | 74.1 / 100 | Post-discharge survey responses (26,970 returned surveys) |
| **Total Gross Billings** | $499.3M | Generated across all 10 departments over 3 years |
| **Total Operating Margin** | $224.7M | ~45.0% blended gross operating margin |

---

## 2. Main Finding: The Link Between Discharge Efficiency & Readmissions

When I grouped admissions into discharge efficiency score bands, the correlation with 30-day readmissions was stark:

| Discharge Efficiency Cohort | Score Range | Patient Admissions | Readmission Rate |
|---|---|---:|---:|
| **Rushed** | 0 – 40 | 1,596 | **27.69%** |
| **Below Average** | 40 – 60 | 11,805 | **18.25%** |
| **Good** | 60 – 80 | 22,045 | **12.30%** |
| **Excellent** | 80 – 100 | 11,054 | **7.73%** |

### What this means:
- Patients in the **rushed cohort (score 0–40)** returned to the hospital within 30 days at **3.58 times the rate** of patients in the **excellent cohort (score 80–100)**.
- In my Random Forest model (`notebooks/05_business_insights.ipynb`), discharge efficiency was by far the strongest operational predictor, accounting for **44.9% of feature importance** (followed by admission severity at 23.4%).
- **Practical Action:** Hospitals often try to clear beds quickly before noon to make room for incoming admissions. But rushing patients out the door without thorough medication reviews, caregiver training, or confirmed follow-up appointments simply bounces them right back into the emergency department within a month. Implementing an EHR checklist gate for low-scoring discharges would directly address this.

---

## 3. Bed Capacity Issues: Overcrowding in Oncology & ICU

I calculated bed occupancy by taking the total patient bed-days for each department and dividing by the total licensed bed-days available over the 3-year period (beds × 1,096 days):

| Department | Staffed Beds | Total Bed-Days | 3-Year Occupancy Rate | Status |
|---|---:|---:|---:|---|
| **Oncology** | 28 | 30,953.5 | **101.0%** | Critical Bottleneck (overflow beds in use) |
| **ICU** | 20 | 21,687.5 | **99.1%** | Near Peak (zero emergency buffer) |
| **General Surgery** | 35 | 32,842.0 | **85.6%** | Healthy / Target Utilization |
| **Emergency** | 50 | 40,828.0 | **74.6%** | Adequate Buffer |
| **Cardiology** | 42 | 27,858.0 | **60.5%** | Under-Utilized Buffer |
| **Obstetrics** | 26 | 16,990.0 | **59.6%** | Low Utilization |

### What this means:
- **Oncology running at 101%** is a genuine operational problem. It means oncology is regularly relying on hallway beds, temporary overflow cots, or borrowing beds from other wards.
- **ICU running at 99.1%** leaves almost no headroom for unexpected trauma cases or emergency surgical complications.
- At the same time, **Cardiology (60.5%)** and **Obstetrics (59.6%)** have consistent excess bed capacity.
- **My Recommendation:** Hospital management should explore reallocating 4 to 6 beds from Cardiology over to Oncology and an ICU step-down unit. That would relieve Oncology's constant overflow without compromising Cardiology's ability to handle patient surges.

---

## 4. Weekend vs. Weekday Triage: Testing a Common Myth

Before running the numbers, my hypothesis was that patients admitted on weekends would experience noticeably longer triage wait times because clinical staffing is usually leaner on Saturdays and Sundays.

I wrote a query comparing the two:
- **Weekday Admissions (31,773 patients):** Average wait time was **24.1 minutes**
- **Weekend Admissions (14,727 patients):** Average wait time was **24.3 minutes**
- **Difference:** Just **0.2 minutes (12 seconds)**

### Why I kept this in the report:
It's tempting to only highlight "exciting" discoveries and hide hypotheses that didn't pan out. But in real-world data analysis, disproving an assumption is just as valuable as confirming one. If hospital leadership had hired expensive weekend agency nursing staff to "fix the weekend wait problem," they would have spent significant budget solving a bottleneck that doesn't actually exist. The real wait-time spikes happen during winter respiratory surges, regardless of the day of the week.

---

## 5. Department Financial Margins & An Honest Data Note

Looking at gross billings and costs across all 10 departments:

- **Top Volume Departments:**
  - Emergency generated the highest gross billings ($86.8M billings, $39.0M gross margin).
  - Cardiology was second ($61.2M billings, $27.6M gross margin).
  - Pediatrics was third ($55.4M billings, $25.0M gross margin).
- **Operating Margin:** Across the entire network, total billings came to $499.3M against $274.6M in operating costs, leaving a gross margin of $224.7M (45.0%).

### Important Transparency Note on the Data:
You'll notice that every department hovers right around a 45% margin. That is a limitation of how operating costs were assigned in the underlying synthetic dataset (using a uniform cost multiplier rather than true activity-based department accounting). In a real hospital, an ICU bed costs far more per day to staff than an obstetrics bed. I want to call this out honestly as a modeling caveat rather than pretend it's a real-world financial pattern.

---

## 6. How the Machine Learning Readmission Model Performed

In `notebooks/05_business_insights.ipynb`, I trained a Random Forest model to flag patients at risk of 30-day readmission:

- **Train/Test Split:** 80% train (37,200 encounters) / 20% test (9,300 encounters)
- **Model Result:** **ROC-AUC of 0.642**
- **Top 5 Features:**
  1. `discharge_efficiency` (44.9%)
  2. `severity_score` (23.4%)
  3. `length_of_stay_days` (6.5%)
  4. `patient_age` (5.5%)
  5. `wait_minutes` (4.5%)

### Why 0.642 AUC is realistic (and not a failure):
- I intentionally excluded downstream financial numbers (like total treatment costs or billings) from the model. Using financial data that is only calculated weeks after a patient leaves would be data leakage.
- In published medical literature, well-known readmission scoring frameworks like the **HOSPITAL score** and **LACE index** typically land between **0.65 and 0.75 AUC**. Readmissions are heavily influenced by things that don't show up in hospital encounter databases: whether a patient can afford their prescriptions at home, whether they have a family caregiver, and their diet. An AUC of 0.642 using strictly operational intake and discharge data is solid, honest, and realistic.

---

## 7. Action Plan for Hospital Leadership

If I were presenting these findings to the hospital's Chief Medical Officer and Chief Operating Officer, here are the 4 recommendations I would give them:

1. **Gate Low-Efficiency Discharges:** Don't let patients with a low discharge score (0-40) leave without a mandatory clinical checklist (medication reconciliation, caregiver education, scheduled primary care visit). Cutting rushed discharges could significantly lower the 27.7% readmission spike.
2. **Reallocate 4–6 Beds to Oncology & ICU:** Shift unused licensed beds out of Cardiology (60.5% occupancy) into Oncology (101% occupancy) to eliminate hallway overflow beds.
3. **Don't Waste Budget on Weekend Triage Shifts:** Triage waits are practically identical on weekends (24.3 min vs 24.1 min). Focus triage staffing instead on seasonal respiratory spikes in December through February.
4. **Upgrade Cost Accounting for Phase 2:** To make the financial model truly useful for budgeting, connect actual departmental nursing hours and supply costs to each unit rather than relying on uniform margin estimates.
