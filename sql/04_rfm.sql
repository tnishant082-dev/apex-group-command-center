-- Retail RFM: Recency / Frequency / Monetary + segment CASE
-- Grain: one row per CustomerID from Online Retail II (positive qty, non-null customer)
-- Aligned to data/marts/mart_retail_rfm.csv segment logic.
-- DuckDB / BigQuery-style over landing extract (or a fuller Online Retail II load).

CREATE OR REPLACE VIEW stg_retail_lines AS
SELECT
  CAST(CustomerID AS BIGINT) AS customer_id,
  Invoice AS invoice_id,
  CAST(InvoiceDate AS TIMESTAMP) AS invoice_ts,
  Quantity AS qty,
  Price AS unit_price,
  Quantity * Price AS line_gmv
FROM read_csv_auto('data/landing/online_retail_ii_sample.csv')
WHERE CustomerID IS NOT NULL
  AND Quantity > 0
  AND Price >= 0;

-- Snapshot = max invoice date in the extract
CREATE OR REPLACE VIEW mart_retail_rfm AS
WITH snap AS (
  SELECT MAX(invoice_ts) AS as_of FROM stg_retail_lines
),
cust AS (
  SELECT
    l.customer_id,
    DATE_DIFF('day', MAX(l.invoice_ts), s.as_of) AS recency_days,
    COUNT(DISTINCT l.invoice_id) AS frequency,
    SUM(l.line_gmv) AS monetary
  FROM stg_retail_lines l
  CROSS JOIN snap s
  GROUP BY 1
),
scored AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- R: lower recency is better → score 5..1
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score_raw,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM cust
),
rfm AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- invert NTILE so 5 = most recent
    CAST(6 - r_score_raw AS INTEGER) AS r_score,
    CAST(f_score AS INTEGER) AS f_score,
    CAST(m_score AS INTEGER) AS m_score
  FROM scored
)
SELECT
  customer_id,
  recency_days,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
    WHEN r_score >= 3 AND f_score <= 2 THEN 'Potential'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
    ELSE 'Hibernating'
  END AS segment
FROM rfm;

-- Segment rollup (compare to Key Metrics / Page 7)
SELECT segment, COUNT(*) AS customers
FROM mart_retail_rfm
GROUP BY 1
ORDER BY customers DESC;
