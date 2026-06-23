# Metric Definitions

- **Average Length of Stay:** 4.0
- **Readmission Rate:** 10.7%
- **Bed Occupancy Rate:** 14.2%
- **Patient Wait Time:** 39.7
- **Doctor Utilization:** 38.3%
- **Revenue per Department:** $17.8M
- **Cost per Patient:** 6,720.2
- **Patient Satisfaction Score:** 81.9
- **Emergency Admission Rate:** 38.1%
- **Discharge Efficiency:** 87.9

## Methodology

- Source tables are generated under `data/raw` with duplicates, missing values, outliers, and realistic business relationships.
- Cleaned analytical tables are stored under `data/cleaned`.
- KPIs are computed from cleaned fact tables and documented SQL patterns in `sql/`.
