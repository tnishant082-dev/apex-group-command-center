-- Quality checks over staging views (see sql/01_staging.sql)
-- Expect 0-row results for failure queries; row-count / null% / date-range are diagnostic.
-- Counts below match excel/apex_group_dictionary_recon.xlsx → Row Counts (these extracts).

-- =============================================================================
-- 1) PK uniqueness (expect n = 0)
-- =============================================================================
SELECT 'bank_loans_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT loan_id FROM stg_bank_loans GROUP BY 1 HAVING COUNT(*) > 1);
SELECT 'mart_orders_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT order_id FROM stg_mart_orders GROUP BY 1 HAVING COUNT(*) > 1);
SELECT 'care_claims_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT claim_id FROM stg_care_claims GROUP BY 1 HAVING COUNT(*) > 1);
SELECT 'care_admissions_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT admission_id FROM stg_care_admissions GROUP BY 1 HAVING COUNT(*) > 1);
SELECT 'bank_customers_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT customer_id FROM stg_bank_customers GROUP BY 1 HAVING COUNT(*) > 1);

-- =============================================================================
-- 2) Flag domains (expect n = 0)
-- =============================================================================
SELECT 'loan_default_domain' AS check_id, COUNT(*) AS n FROM stg_bank_loans WHERE default_flag NOT IN (0, 1);
SELECT 'fraud_domain' AS check_id, COUNT(*) AS n FROM stg_bank_card_txns WHERE fraud_flag NOT IN (0, 1);
SELECT 'churn_domain' AS check_id, COUNT(*) AS n FROM stg_bank_customers WHERE churned NOT IN (0, 1);
SELECT 'late_domain' AS check_id, COUNT(*) AS n FROM stg_mart_orders WHERE late_flag NOT IN (0, 1);
SELECT 'readmit_domain' AS check_id, COUNT(*) AS n FROM stg_care_admissions WHERE readmit_30_flag NOT IN (0, 1);
SELECT 'anomaly_domain' AS check_id, COUNT(*) AS n FROM stg_care_claims WHERE anomaly_flag NOT IN (0, 1);
SELECT 'otif_domain' AS check_id, COUNT(*) AS n FROM stg_logistics_shipments WHERE otif NOT IN (0, 1);

-- =============================================================================
-- 3) Non-negative amounts (expect n = 0)
-- =============================================================================
SELECT 'negative_principal' AS check_id, COUNT(*) AS n FROM stg_bank_loans WHERE principal_inr < 0;
SELECT 'negative_gmv' AS check_id, COUNT(*) AS n FROM stg_mart_orders WHERE gmv_inr < 0;
SELECT 'negative_claim' AS check_id, COUNT(*) AS n FROM stg_care_claims WHERE claim_amount_inr < 0;

-- =============================================================================
-- 4) Row counts vs expected (these GitHub extracts)
-- =============================================================================
SELECT 'bank_loans_rows' AS check_id, COUNT(*) AS n, 1000 AS expected,
       CASE WHEN COUNT(*) = 1000 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_bank_loans;
SELECT 'bank_card_txns_rows' AS check_id, COUNT(*) AS n, 20492 AS expected,
       CASE WHEN COUNT(*) = 20492 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_bank_card_txns;
SELECT 'bank_customers_rows' AS check_id, COUNT(*) AS n, 7043 AS expected,
       CASE WHEN COUNT(*) = 7043 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_bank_customers;
SELECT 'mart_orders_rows' AS check_id, COUNT(*) AS n, 22000 AS expected,
       CASE WHEN COUNT(*) = 22000 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_mart_orders;
SELECT 'care_admissions_rows' AS check_id, COUNT(*) AS n, 23000 AS expected,
       CASE WHEN COUNT(*) = 23000 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_care_admissions;
SELECT 'care_claims_rows' AS check_id, COUNT(*) AS n, 1338 AS expected,
       CASE WHEN COUNT(*) = 1338 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_care_claims;
SELECT 'care_medicine_stock_rows' AS check_id, COUNT(*) AS n, 521 AS expected,
       CASE WHEN COUNT(*) = 521 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_care_medicine_stock;
SELECT 'logistics_shipments_rows' AS check_id, COUNT(*) AS n, 20000 AS expected,
       CASE WHEN COUNT(*) = 20000 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_logistics_shipments;
SELECT 'logistics_demand_weekly_rows' AS check_id, COUNT(*) AS n, 1160 AS expected,
       CASE WHEN COUNT(*) = 1160 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_logistics_demand_weekly;
SELECT 'logistics_inventory_rows' AS check_id, COUNT(*) AS n, 118 AS expected,
       CASE WHEN COUNT(*) = 118 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_logistics_inventory;
SELECT 'market_entry_rows' AS check_id, COUNT(*) AS n, 10 AS expected,
       CASE WHEN COUNT(*) = 10 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_market_entry_scorecard;
SELECT 'ops_bottlenecks_rows' AS check_id, COUNT(*) AS n, 10 AS expected,
       CASE WHEN COUNT(*) = 10 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_ops_bottlenecks;
SELECT 'group_bu_quarterly_rows' AS check_id, COUNT(*) AS n, 24 AS expected,
       CASE WHEN COUNT(*) = 24 THEN 'OK' ELSE 'DRIFT' END AS status FROM stg_group_bu_quarterly;

-- =============================================================================
-- 5) Null % diagnostics (informational)
-- =============================================================================
SELECT 'care_claims_anomaly_reason_null_pct' AS check_id,
       ROUND(100.0 * AVG(CASE WHEN anomaly_reason IS NULL THEN 1 ELSE 0 END), 2) AS null_pct,
       96.94 AS expected_approx_pct
FROM stg_care_claims;
SELECT 'bank_loans_any_null_pct' AS check_id,
       ROUND(100.0 * AVG(CASE WHEN loan_id IS NULL OR default_flag IS NULL THEN 1 ELSE 0 END), 2) AS null_pct
FROM stg_bank_loans;
SELECT 'mart_orders_key_null_pct' AS check_id,
       ROUND(100.0 * AVG(CASE WHEN order_id IS NULL OR order_date IS NULL OR gmv_inr IS NULL THEN 1 ELSE 0 END), 2) AS null_pct
FROM stg_mart_orders;
SELECT 'care_admissions_key_null_pct' AS check_id,
       ROUND(100.0 * AVG(CASE WHEN admission_id IS NULL OR readmit_30_flag IS NULL THEN 1 ELSE 0 END), 2) AS null_pct
FROM stg_care_admissions;
SELECT 'logistics_shipments_key_null_pct' AS check_id,
       ROUND(100.0 * AVG(CASE WHEN otif IS NULL THEN 1 ELSE 0 END), 2) AS null_pct
FROM stg_logistics_shipments;

-- =============================================================================
-- 6) Date ranges per source (honest to these extracts)
-- =============================================================================
SELECT 'mart_orders_date_range' AS check_id,
       MIN(order_date) AS min_ts, MAX(order_date) AS max_ts
FROM stg_mart_orders;
-- Expected approx: 2015-01-01 → 2018-01-31 (DataCo sample calendar)

SELECT 'care_claims_date_range' AS check_id,
       MIN(claim_date) AS min_ts, MAX(claim_date) AS max_ts
FROM stg_care_claims;
-- Expected: 2018-01-01 → 2019-12-31 (synthetic claim calendar on Medical Cost rows)

SELECT 'logistics_shipments_date_range' AS check_id,
       MIN(ship_date) AS min_ts, MAX(ship_date) AS max_ts
FROM stg_logistics_shipments;
-- Expected approx: 2015-01-03 → 2018-02-06

SELECT 'group_bu_quarter_span' AS check_id,
       MIN(quarter) AS min_q, MAX(quarter) AS max_q
FROM stg_group_bu_quarterly;

-- =============================================================================
-- 7) Recommendation / severity domain checks
-- =============================================================================
SELECT 'market_rec_domain' AS check_id, COUNT(*) AS n
FROM stg_market_entry_scorecard
WHERE recommendation NOT IN ('Enter', 'Pilot', 'Watch');
SELECT 'ops_severity_domain' AS check_id, COUNT(*) AS n
FROM stg_ops_bottlenecks
WHERE severity NOT IN ('High', 'Medium', 'Low');
