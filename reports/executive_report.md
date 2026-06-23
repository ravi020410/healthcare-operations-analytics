# Healthcare Analytics Executive Report

## Executive Summary

- **Business performance is measurable end to end.** The project combines synthetic raw source tables, cleaning logic, SQL, Python notebooks, Excel analysis, and dashboard-ready visuals.
- **The KPI model is recruiter-ready.** Metrics are defined in business terms and supported by reproducible tables under `data/cleaned`.
- **Recommended next step:** Load the cleaned CSVs into PostgreSQL and Power BI Desktop, then connect the documented DAX measures and dashboard pages.

## Key Findings With Visual Evidence

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

The top-level movement is summarized in `visuals/01_monthly_trend.svg`. Supporting breakdowns are stored under `visuals/` and embedded in the README.

## Recommendations

1. Review the strongest and weakest segments each month, then prioritize two improvement experiments.
2. Use the SQL quality checks before refreshing dashboards.
3. Publish the dashboard screenshots and report PDFs after replacing personal portfolio links.

## Future Opportunities

- Add live database refresh through PostgreSQL.
- Add Power BI drill-through pages from the dashboard specification.
- Add model monitoring or forecasting experiments in the Python notebooks.

## Caveats and Assumptions

- Data is synthetic and designed for portfolio demonstration.
- Power BI `.pbix` creation requires Power BI Desktop and must be completed locally.
- GitHub URLs require authenticated repository creation and publishing.
