-- KPI marts aligned to python/outputs/kpi_snapshot.json
SELECT ROUND(AVG(default_flag)*100,2) AS bank_default_rate_pct FROM stg_bank_loans;
SELECT ROUND(AVG(fraud_flag)*100,3) AS bank_fraud_rate_pct FROM stg_bank_card_txns;
SELECT ROUND(AVG(churned)*100,2) AS bank_churn_rate_pct FROM stg_bank_customers;
SELECT ROUND(AVG(late_flag)*100,2) AS mart_late_delivery_pct FROM stg_mart_orders;
SELECT ROUND(AVG(readmit_30_flag)*100,2) AS care_readmit_30_pct FROM stg_care_admissions;
SELECT ROUND(AVG(anomaly_flag)*100,2) AS care_claims_anomaly_pct FROM stg_care_claims;
SELECT ROUND(AVG(ape)*100,2) AS logistics_mape_pct FROM stg_logistics_demand_weekly;
SELECT ROUND(AVG(otif)*100,2) AS logistics_otif_pct FROM stg_logistics_shipments;
SELECT ROUND(AVG(inventory_turns),2) AS logistics_avg_turns FROM stg_logistics_inventory;
SELECT COUNT(*) AS markets_enter_count FROM stg_market_entry_scorecard WHERE recommendation='Enter';
SELECT COUNT(*) AS high_severity_bottlenecks FROM stg_ops_bottlenecks WHERE severity='High';
SELECT quarter, bu, revenue_cr, ebitda_cr FROM stg_group_bu_quarterly ORDER BY quarter, bu;
