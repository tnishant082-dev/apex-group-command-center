-- Apex Group staging views over cleaned CSVs (DuckDB / BigQuery-style)
CREATE OR REPLACE VIEW stg_bank_loans AS SELECT * FROM read_csv_auto('data/cleaned/bank_loans.csv');
CREATE OR REPLACE VIEW stg_bank_card_txns AS SELECT * FROM read_csv_auto('data/cleaned/bank_card_txns.csv');
CREATE OR REPLACE VIEW stg_bank_customers AS SELECT * FROM read_csv_auto('data/cleaned/bank_customers.csv');
CREATE OR REPLACE VIEW stg_mart_orders AS SELECT * FROM read_csv_auto('data/cleaned/mart_orders.csv');
CREATE OR REPLACE VIEW stg_mart_cart_sessions AS SELECT * FROM read_csv_auto('data/cleaned/mart_cart_sessions.csv');
CREATE OR REPLACE VIEW stg_care_admissions AS SELECT * FROM read_csv_auto('data/cleaned/care_admissions.csv');
CREATE OR REPLACE VIEW stg_care_medicine_stock AS SELECT * FROM read_csv_auto('data/cleaned/care_medicine_stock.csv');
CREATE OR REPLACE VIEW stg_care_claims AS SELECT * FROM read_csv_auto('data/cleaned/care_claims.csv');
CREATE OR REPLACE VIEW stg_logistics_demand_weekly AS SELECT * FROM read_csv_auto('data/cleaned/logistics_demand_weekly.csv');
CREATE OR REPLACE VIEW stg_logistics_shipments AS SELECT * FROM read_csv_auto('data/cleaned/logistics_shipments.csv');
CREATE OR REPLACE VIEW stg_logistics_inventory AS SELECT * FROM read_csv_auto('data/cleaned/logistics_inventory.csv');
CREATE OR REPLACE VIEW stg_group_bu_quarterly AS SELECT * FROM read_csv_auto('data/cleaned/group_bu_quarterly.csv');
CREATE OR REPLACE VIEW stg_market_entry_scorecard AS SELECT * FROM read_csv_auto('data/cleaned/market_entry_scorecard.csv');
CREATE OR REPLACE VIEW stg_ops_bottlenecks AS SELECT * FROM read_csv_auto('data/cleaned/ops_bottlenecks.csv');
