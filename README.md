# Apex Group Command Center

Consulting-style executive rollup for a multi-domain portfolio narrative — **Apex Bank**, **Apex Mart**, **Apex Care**, and **Apex Logistics** — with shared QoQ diagnosis, market-entry scoring, and ops bottleneck audit.

**Walkthrough:** [`artifacts/apex-group-demo.mp4`](./artifacts/apex-group-demo.mp4) · **Open in Power BI Desktop:** [`dashboard/ApexGroup.pbip`](./dashboard/ApexGroup.pbip)

## Data Scope & Assumptions

- **Sources (real public datasets):** Analysis is built on seven named public datasets (UCI / Kaggle / Mendeley), landed under `data/landing/` with citations in `DATA_SOURCES.csv`. Lineage: `data/landing/` → `data/cleaned/` → `data/marts/`.
- **Operating Model:** Apex Bank, Apex Mart, Apex Care, and Apex Logistics are structured as a unified multi-business reporting environment for cross-functional executive analytics (portfolio narrative across four domains).
- **Reporting grain:** Group ₹ Cr figures are FX-rolled for a unified portfolio view. Source calendars do not fully align; the last overlapping source quarter on the DataCo calendar is **2018Q1** (reported as portfolio “last Q”). The rollup is an analytical construct, not a statutory consolidated P&L.
- **Documented proxies:** Telco churn stands in for bank retention signals; formulary “Down” status for expiry risk; cancel / C-invoices for cart-funnel leakage; claims flags = high OLS residual vs age / bmi / smoker / children (95th-percentile residual tail — not investigated fraud); DataCo on-time proxy (`Late_delivery_risk = 0`) for OTIF.
- **Sampling:** ULB fraud, DataCo, and Online Retail II extracts are stratified or sampled for repository size. Fraud % on the extract ≠ full ULB base rate (~0.17%). **Dashboard RFM Champions (1,028) used a fuller Online Retail II extract than the GitHub landing sample**; published `data/marts/mart_retail_rfm.csv` holds that headcount; sample rebuild writes `mart_retail_rfm_from_sample.csv`.
- **Cart sessions:** Funnel counts in `mart_cart_funnel` are calibrated sessions (viewed→paid = 10,500 / 30,000 = **35.0%**), not raw web hits. Checkout→paid (10,500 / 11,776 ≈ **89.16%**) is a stage rate, not the primary conversion KPI.
- **KPI lineage:** Metrics are computed from `data/landing/` → cleaned tables → `data/marts/`, reconciled in SQL and the Excel dictionary / cleaning log / KPI recon workbook. Claims anomaly % is rebuilt via `scripts/build_marts.py` from residual flags.
- **Governance Note:** All insights, KPIs, and recommendations are traceable to documented source datasets, transformation logic, and analytical assumptions included in this repository.

---

## Executive Summary

Leadership teams rarely lack dashboards. They lack a **shared grain**. Banking risk packs, retail CX packs, hospital ops packs, and logistics OTIF packs usually live in different tools, calendars, and definitions — so an executive cannot answer “where is the book hurting this quarter?” without stitching four slide decks by hand.

This project builds a single Power BI command center that rolls four business-unit lenses into one executive view, then drills into loan default, card fraud, churn, RFM, cart abandon, delivery, readmission, formulary risk, claims anomalies, forecast MAPE, and OTIF / inventory turns — using **named public extracts** with documented proxies and samples.

---

## Business Objective

Enable executives and BI partners to:

- Compare BU contribution and QoQ movement on a common ₹ Cr rollup (portfolio narrative, FX-normalized)
- Prioritize cross-BU bottlenecks (default, churn, late delivery, readmit, OTIF miss) instead of debating which report is “right”
- Approve market-entry / corridor focus using a transparent composite scorecard
- Drill from group KPIs into BU risk and ops pages without leaving the report

---

## Key Features

- **Multi-business-unit monitoring** — Bank, Mart, Care, Logistics in one `.pbip`
- **Executive KPI tracking** — revenue, EBITDA, customers, NPS blend, QoQ growth
- **Cross-functional performance visibility** — shared ops-efficiency and market-entry pages
- **Drill-down capability** — group overview → BU risk / CX / care / logistics pages
- **Risk identification** — default, fraud bands, churn, readmission, claims residuals, expiry
- **Operational monitoring** — late delivery, OTIF, forecast MAPE, inventory turns

---

## Dataset Overview

| Business Unit | Dataset Source | Records (landing extract) | Purpose |
|---|---|---:|---|
| Apex Bank | [German Credit (Statlog)](https://archive.ics.uci.edu/dataset/144/statlog+german+credit+data) | 1,000 | Loan default risk |
| Apex Bank | [ULB Credit Card Fraud](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) (stratified) | 20,492 | Card fraud patterns (all frauds kept) |
| Apex Bank | [IBM Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) | 7,043 | Churn watch (banking/telco proxy) |
| Apex Mart | [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (sample) | 40,000 | RFM segments · cart funnel proxy |
| Apex Mart / Logistics | [DataCo Smart Supply Chain](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis) (sample) | 25,000 | Delivery, OTIF, forecast, inventory, market entry |
| Apex Care | [Diabetes 130-US Hospitals](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008) (enriched sample) | 20,000 | 30-day readmission · formulary/expiry proxy |
| Apex Care | [Medical Cost Personal](https://www.kaggle.com/datasets/mirichoi0218/insurance) | 1,338 | Claims anomaly / residual flags |

Full citations: [`data/landing/DATA_SOURCES.csv`](./data/landing/DATA_SOURCES.csv).

---


## Key Metrics

Reconciled across `data/marts/`, `sql/03_kpi_marts.sql`, Excel KPI recon, and `scripts/build_marts.py`.

| Area | KPI | Value | Note |
|---|---|---|---|
| Group | Last-Q revenue / EBITDA | **₹51.1 Cr** / **₹5.8 Cr** | Last overlapping source quarter **2018Q1** (DataCo calendar) |
| Bank | Default / fraud extract / churn | **30.0%** / **2.40%** / **26.54%** | Fraud extract % ≠ full ULB ~0.17% |
| Mart | RFM Champions / viewed→paid | **1,028** / **35.0%** | Champions from fuller Retail II extract; checkout→paid ≈ 89.16% (stage rate) |
| Care | Readmit / claims anomaly / ≤60d | **34.78%** / **5.01%** / **₹0.91 Cr** | Anomaly = 95th pctile residual vs OLS expected cost |
| Logistics | Late / OTIF / MAPE / turns | **55.15%** / **44.79%** / **14.69%** / **12.28x** | OTIF from DataCo `Late_delivery_risk=0` |

---

## Data Preparation Process

1. **Landing** — store named public extracts under `data/landing/` with source citations.
2. **Cleaning** — type fixes, cancel/C-invoice handling (retail), stratification notes (fraud / DataCo), enrichment rules (diabetes `<30` kept).
3. **Missing values** — drop or flag incomplete keys (e.g. RFM requires Customer ID); document exclusions in Excel cleaning log.
4. **Standardization** — shared BU labels, quarter labels for the group rollup, FX-rolled ₹ Cr for exec comparability (not statutory P&L).
5. **KPI creation** — SQL marts (`sql/03_kpi_marts.sql`, `sql/04_rfm.sql`, `sql/05_market_entry.sql`) plus `scripts/build_marts.py` for claims residual flags.
6. **Data modeling** — cleaned tables → marts → Power BI semantic model (`dashboard/ApexGroup.SemanticModel`).

Excel workbook sheets: **Dictionary / Cleaning log / KPI recon** — [`excel/apex_group_dictionary_recon.xlsx`](./excel/apex_group_dictionary_recon.xlsx).

---

## Power BI Data Model

- **Approach:** star-style semantic model in Power BI Desktop (`.pbip`)
- **Facts / marts:** group KPI snapshot, bank KPIs, retail RFM, cart funnel, logistics KPIs, care KPIs, claims residuals, market entry, ops bottlenecks
- **Dimensions / labels:** BU, period (quarter / month where available), segment bands (RFM, risk, expiry)
- **Relationships:** mart tables related through BU / period keys in the semantic model; CSV paths point at `data/marts/` and `data/cleaned/`
- **Measures:** DAX for rates, margins, QoQ, and page-level KPI cards

Open [`dashboard/ApexGroup.pbip`](./dashboard/ApexGroup.pbip) in Power BI Desktop to inspect relationships and measures.

---

## Dashboard Pages

Fluent Light theme (canvas `#F3F2F1`, accent `#118DFF`). Typical page pattern: **4 KPI cards → wide trend → dual bottom charts**.

### 1. Group Executive Overview
![Group Executive Overview](./screenshots/01-group-executive-overview.png)

| | |
|---|---|
| **Objective** | Give leadership one page for last-quarter ₹ Cr book, margin, and BU mix |
| **KPIs** | Last-Q (**2018Q1** DataCo calendar) group revenue **₹51.1 Cr** · EBITDA **₹5.8 Cr** · Active customers (extract headcount) · Avg NPS blend |
| **Visuals** | KPI cards · revenue trend by quarter · revenue by BU · QoQ growth % |
| **Questions answered** | Which BU carries the FX-rolled book? Where did QoQ growth / decline concentrate? |

### 2. Ops Efficiency Audit
![Ops Efficiency Audit](./screenshots/02-ops-efficiency-audit.png)

| | |
|---|---|
| **Objective** | Rank cross-BU bottlenecks by severity for a shared-services agenda |
| **KPIs** | High-severity count **6** · gap vs stated targets on default, churn, late delivery, readmit, OTIF |
| **Visuals** | Severity bars · process gap chart |
| **Questions answered** | Which gaps are P0 vs watch-list? Is late delivery / OTIF larger than credit risk on these extracts? |

### 3. Market Entry Scorecard
![Market Entry Scorecard](./screenshots/03-market-entry-scorecard.png)

| | |
|---|---|
| **Objective** | Score regions for enter / watch / avoid using a transparent composite |
| **KPIs** | Enter calls **5** · composite demand / competition / infra / talent / regulatory inputs (DataCo regions) |
| **Visuals** | Score table · ranked bars |
| **Questions answered** | Which corridors clear the enter bar? What drives a low composite? |

### 4. Loan Default Risk (Apex Bank)
![Loan Default Risk](./screenshots/04-loan-default-risk.png)

| | |
|---|---|
| **Objective** | Show credit-book risk on German Credit with score bands |
| **KPIs** | Default rate **30.0%** (300 / 1,000) · avg credit score heuristic · band mix |
| **Visuals** | KPI cards · default by score band · DTI-style split |
| **Questions answered** | Where do bad loans concentrate by score band? |

### 5. Card Fraud Patterns (Apex Bank)
![Card Fraud Patterns](./screenshots/05-card-fraud-patterns.png)

| | |
|---|---|
| **Objective** | Surface fraud lift by rule / score band on a stratified ULB extract |
| **KPIs** | Extract fraud rate **2.40%** (all 492 frauds kept; full-file base rate ~0.17%) |
| **Visuals** | Band bars · rule hits · amount concentration |
| **Questions answered** | Which Critical-band rules deserve review before “booked loss” talk? |

### 6. Banking Churn Watch (Apex Bank)
![Banking Churn Watch](./screenshots/06-banking-churn-watch.png)

| | |
|---|---|
| **Objective** | Monitor retention risk using Telco churn as a documented bank/telco proxy |
| **KPIs** | Churn **26.54%** of 7,043 customers · early-tenure concentration · logistic baseline AUC ~0.83 |
| **Visuals** | KPI cards · tenure bands · contract / charge views |
| **Questions answered** | Which tenure / plan cohorts drive churn on this extract? |

### 7. Retail RFM Segments (Apex Mart)
![Retail RFM Segments](./screenshots/07-retail-rfm-segments.png)

| | |
|---|---|
| **Objective** | Prioritize lifecycle spend by RFM segment |
| **KPIs** | Champions **1,028 (~20%)** (fuller Online Retail II extract than landing sample) · GMV concentration in top segments |
| **Visuals** | Segment bars · value mix |
| **Questions answered** | Who to win back (At Risk / Hibernating) vs protect (Champions)? |

### 8. Cart Abandonment Funnel (Apex Mart)
![Cart Abandonment Funnel](./screenshots/08-cart-abandonment-funnel.png)

| | |
|---|---|
| **Objective** | Locate funnel drop using cancel/C-invoice structure as abandon proxy |
| **KPIs** | Viewed→Paid **35.0%** (10,500/30,000 calibrated sessions); checkout→paid stage rate ≈ **89.16%** (not the primary conversion KPI) |
| **Visuals** | Funnel · reason mix |
| **Questions answered** | Where does conversion leak between view and paid? |

### 9. Retail Delivery Performance (Apex Mart)
![Retail Delivery Performance](./screenshots/09-retail-delivery-performance.png)

| | |
|---|---|
| **Objective** | Spot late-delivery hotspots by category / city |
| **KPIs** | Late delivery **55.15%** (DataCo `Late_delivery_risk`) |
| **Visuals** | Late % by category/city · monthly late trend · ship hours |
| **Questions answered** | Where should promise dates be reset first? |

### 10. Patient Readmission Risk (Apex Care)
![Patient Readmission Risk](./screenshots/10-patient-readmission-risk.png)

| | |
|---|---|
| **Objective** | Flag 30-day readmission risk for discharge triage |
| **KPIs** | 30-day readmission **34.78%** (enriched Diabetes sample) |
| **Visuals** | Specialty / LOS views · risk bands |
| **Questions answered** | Which specialties / LOS bands need follow-up capacity? |

### 11. Medicine Supply & Expiry (Apex Care)
![Medicine Supply & Expiry](./screenshots/11-medicine-supply-expiry.png)

| | |
|---|---|
| **Objective** | Quantify formulary write-off / expiry proxy risk |
| **KPIs** | Expiring ≤60d stock value **₹0.91 Cr** (formulary “Down” → expiry proxy) |
| **Visuals** | Risk bands · value at risk |
| **Questions answered** | What stock should transfer / promote before write-off? |

### 12. Claims Anomaly Watch (Apex Care)
![Claims Anomaly Watch](./screenshots/12-claims-anomaly-watch.png)

| | |
|---|---|
| **Objective** | Route high residual claims for manual review |
| **KPIs** | Anomaly rate **5.01%** (95th pctile residual vs OLS expected cost: charges ~ age + bmi + smoker + children) |
| **Visuals** | Residual distribution · review flags |
| **Questions answered** | Which claims clear a review threshold on this extract? |

### 13. Demand Forecast Accuracy (Apex Logistics)
![Demand Forecast Accuracy](./screenshots/13-demand-forecast-accuracy.png)

| | |
|---|---|
| **Objective** | Show where a seasonal-naive baseline is enough vs where error is high |
| **KPIs** | MAPE **14.69%** (lag-4 seasonal naive on DataCo weekly demand) |
| **Visuals** | Category MAPE · actual vs naive |
| **Questions answered** | Which categories justify a richer forecast model? |

### 14. Logistics + Inventory (Apex Logistics)
![Logistics + Inventory](./screenshots/14-logistics-inventory.png)

| | |
|---|---|
| **Objective** | Connect service (OTIF) with inventory turns |
| **KPIs** | OTIF **44.79%** · avg inventory turns **12.28x** |
| **Visuals** | Route OTIF · turns by category · monthly OTIF |
| **Questions answered** | Which corridors need service investment vs stock rebalancing? |

---

## Key Insights

Numbers below are **computed from the public extracts in this repo** (see Data Scope & Assumptions for proxies and samples).

1. **Group book is Care + Mart heavy on the FX-rolled last overlapping source quarter (2018Q1)** — revenue **₹51.1 Cr**, EBITDA **₹5.8 Cr** (margin ~11%). Implication: exec reviews should not treat Bank interest-proxy and Logistics sales as interchangeable with retail GMV.
2. **Credit risk is textbook-high on German Credit** — default **30.0%**. Implication: score-band underwriting and DTI-style splits belong on the Bank P0 pack, not a footnote.
3. **Fraud review must respect stratification** — extract fraud rate **2.40%** because all frauds were kept; full ULB base rate is ~**0.17%**. Implication: never quote extract % as booked-loss without the footnote.
4. **Retention pressure shows early** — Telco churn **26.54%** as bank/telco proxy. Implication: save plays belong on early-tenure / month-to-month style cohorts before spray discounts.
5. **Retail value is concentrated** — **1,028 Champions** (~20%, fuller Retail II extract) drive disproportionate GMV; viewed→paid **35%**. Implication: win-back At Risk / Hibernating and fix cart drop before broad acquisition spend.
6. **Delivery is the loudest ops alarm** — late **55.15%**, OTIF **44.79%**. Implication: reset promise windows on hot DataCo categories/cities before new corridor CapEx narratives.
7. **Care quality and formulary cash** — 30-day readmit **34.78%**; expiring ≤60d **₹0.91 Cr**. Implication: discharge triage + formulary transfer/promote are board-visible Care levers.
8. **Forecast vs stock** — MAPE **14.69%**, turns **12.28x**. Implication: fix high-MAPE categories selectively; many SKUs can be worked with naive + turns without a new ML stack.

---

## Recommended actions (on these extracts)

| Priority | Action | Lever | Data risk |
|---|---|---|---|
| 1 | Reset promise dates on late-hot DataCo categories/cities | Late 55% → OTIF | Sample, not live WMS |
| 2 | Win-back At Risk + Hibernating RFM | GMV concentration | Snapshot RFM (Champions from fuller extract); no campaign lift |
| 3 | Discharge triage on high readmit specialties | 34.8% `<30` flag | Enriched diabetes sample |
| 4 | Queue high-residual claims (95th-pctile OLS residual tail) for manual review | Residual-tail flags (5.01%) | Residual ≠ investigated fraud |
| 5 | Do not treat group ₹ Cr as one P&L | Exec rollup only | Mixed calendars + FX; last Q = 2018Q1 |

---

## Business Impact

| Decision Area | Impact (on these extracts) |
|---|---|
| Revenue Protection | Champion concentration + cart conversion visibility for lifecycle spend |
| Cost Optimization | Formulary ≤60d value and inventory turns highlight write-off / overstock risk |
| Service Quality | Late delivery and OTIF pages make promise-date resets measurable |
| Risk Reduction | Default, fraud-band, churn, readmit, and claims residual flags for review queues |
| Executive Visibility | One Fluent Light report instead of four disconnected BU decks |

---

## Tools Used

| Tool | Use |
|---|---|
| **SQL** | Staging, quality checks, RFM, market-entry, KPI marts (`sql/01`–`05`) |
| **Python** | Mart rebuild / residual flags (`scripts/build_marts.py`) |
| **Excel** | Dictionary / Cleaning log / KPI recon (`excel/apex_group_dictionary_recon.xlsx`) |
| **Power BI** | 14-page command center report (`dashboard/ApexGroup.pbip`), DAX, star-style semantic model |
| Delivery | Page PNGs + silent walkthrough (`screenshots/`, `artifacts/`) |

---

## Repo Structure

```text
apex-group-command-center/
├── README.md
├── LICENSE
├── artifacts/                 # apex-group-demo.mp4
├── dashboard/                 # ApexGroup.pbip + Report + SemanticModel
├── data/
│   ├── landing/               # public extracts + DATA_SOURCES.csv
│   ├── cleaned/
│   └── marts/                 # KPI / RFM / claims residuals (incl. sample RFM rebuild path)
├── excel/                     # Dictionary / Cleaning log / KPI recon
├── screenshots/               # 01–14 page PNGs
├── scripts/                   # build_marts.py (claims residuals; optional sample RFM)
└── sql/                       # staging · quality · KPI · RFM · market entry
```

---

## Screenshots

| Page | Preview |
|---|---|
| Group Executive Overview | ![Group](./screenshots/01-group-executive-overview.png) |
| Ops Efficiency Audit | ![Ops](./screenshots/02-ops-efficiency-audit.png) |
| Market Entry Scorecard | ![Market](./screenshots/03-market-entry-scorecard.png) |
| Loan Default Risk | ![Loans](./screenshots/04-loan-default-risk.png) |
| Card Fraud Patterns | ![Fraud](./screenshots/05-card-fraud-patterns.png) |
| Banking Churn Watch | ![Churn](./screenshots/06-banking-churn-watch.png) |
| Retail RFM Segments | ![RFM](./screenshots/07-retail-rfm-segments.png) |
| Cart Abandonment Funnel | ![Cart](./screenshots/08-cart-abandonment-funnel.png) |
| Retail Delivery Performance | ![Delivery](./screenshots/09-retail-delivery-performance.png) |
| Patient Readmission Risk | ![Readmit](./screenshots/10-patient-readmission-risk.png) |
| Medicine Supply & Expiry | ![Medicine](./screenshots/11-medicine-supply-expiry.png) |
| Claims Anomaly Watch | ![Claims](./screenshots/12-claims-anomaly-watch.png) |
| Demand Forecast Accuracy | ![Forecast](./screenshots/13-demand-forecast-accuracy.png) |
| Logistics + Inventory | ![Logistics](./screenshots/14-logistics-inventory.png) |

Silent walkthrough: [`artifacts/apex-group-demo.mp4`](./artifacts/apex-group-demo.mp4)

---

## Theme mapping (multi-domain coverage)

| Theme | Where it lives | Real source |
|---|---|---|
| Business performance diagnosis (QoQ) | Page 1 | Rolled public extracts |
| Operational efficiency / bottlenecks | Page 2 | Derived from real BU KPIs |
| Market-entry scorecard | Page 3 | DataCo regions |
| Loan default risk | Page 4 | German Credit |
| Card fraud patterns | Page 5 | ULB Credit Card Fraud |
| Customer churn | Page 6 | IBM Telco Churn |
| RFM segmentation | Page 7 | Online Retail II |
| Cart abandonment | Page 8 | Online Retail II cancels |
| Delivery performance | Page 9 | DataCo |
| 30-day readmission | Page 10 | Diabetes 130-US |
| Medicine stock / expiry | Page 11 | Diabetes formulary status |
| Insurance claims anomalies | Page 12 | Medical Cost Personal |
| Demand forecast accuracy | Page 13 | DataCo weekly demand |
| Logistics OTIF | Page 14 | DataCo |
| Inventory optimization / turns | Page 14 | DataCo product velocity |

---

## Future Enhancements

- Predictive models for churn / readmit with holdout metrics (beyond the current logistic baseline note)
- Richer demand forecasting where MAPE is structurally high
- Near-real-time refresh from warehouse / lakehouse feeds (currently CSV marts)
- Automated alert thresholds on late %, OTIF, Critical fraud band, and formulary ≤60d value

---

## Skills Demonstrated

Power BI, DAX, Data Modeling, KPI Development, Dashboard Design, Data Cleaning, Business Analysis, Executive Reporting, Power Query, Data Visualization, BI Strategy, SQL, Excel, Star Schema, RFM Analysis, Fraud Analytics, Churn Analysis, OTIF, Forecast MAPE, MIS Reporting

---

## How to View

1. Clone the repo and open [`dashboard/ApexGroup.pbip`](./dashboard/ApexGroup.pbip) in **Power BI Desktop** (paths point at `data/marts` and `data/cleaned`).
2. Or review page PNGs in [`screenshots/`](./screenshots/) and the walkthrough in [`artifacts/apex-group-demo.mp4`](./artifacts/apex-group-demo.mp4).
3. Optional: rebuild claims residual mart with `python scripts/build_marts.py`.

---

## Recruiter Note

If you are hiring for **Data Analyst**, **Business Analyst**, **Reporting Analyst**, **MIS Analyst**, or **Power BI Developer** roles, this project demonstrates the ability to turn complex multi-domain datasets into an executive-ready command center: clear business questions, documented sources and proxies, KPI reconciliation (SQL + Excel), a Power BI semantic model, and insight → action tables with explicit data risk — not just decorative charts.

---

## Author

**Nishant Tyagi** · [GitHub @tnishant082-dev](https://github.com/tnishant082-dev) · tnishant838@gmail.com
