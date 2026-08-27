-- Quality checks (expect 0-row results for failures)
-- 1) PK uniqueness
SELECT 'bank_loans_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT loan_id FROM stg_bank_loans GROUP BY 1 HAVING COUNT(*)>1);
SELECT 'mart_orders_dup' AS check_id, COUNT(*) AS n FROM (
  SELECT order_id FROM stg_mart_orders GROUP BY 1 HAVING COUNT(*)>1);
-- 2) Flag domains
SELECT 'loan_default_domain' AS check_id, COUNT(*) AS n FROM stg_bank_loans WHERE default_flag NOT IN (0,1);
SELECT 'fraud_domain' AS check_id, COUNT(*) AS n FROM stg_bank_card_txns WHERE fraud_flag NOT IN (0,1);
SELECT 'churn_domain' AS check_id, COUNT(*) AS n FROM stg_bank_customers WHERE churned NOT IN (0,1);
SELECT 'late_domain' AS check_id, COUNT(*) AS n FROM stg_mart_orders WHERE late_flag NOT IN (0,1);
SELECT 'readmit_domain' AS check_id, COUNT(*) AS n FROM stg_care_admissions WHERE readmit_30_flag NOT IN (0,1);
-- 3) Non-negative amounts
SELECT 'negative_principal' AS check_id, COUNT(*) AS n FROM stg_bank_loans WHERE principal_inr < 0;
SELECT 'negative_gmv' AS check_id, COUNT(*) AS n FROM stg_mart_orders WHERE gmv_inr < 0;
