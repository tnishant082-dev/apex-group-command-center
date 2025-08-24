-- Market-entry composite score + recommendation
-- Aligned to data/cleaned/market_entry_scorecard.csv (DataCo Order Region grain).
-- Indices are 0–100 ranks already published on the cleaned scorecard.
-- Composite (mart-aligned): weighted blend with competition inverted (lower = better),
-- then min–max scaled onto the published [40, 85] band used in the CSV.
--
--   raw = 0.35 * demand_index
--       + 0.15 * (100 - competition_index)
--       + 0.20 * infra_readiness
--       + 0.15 * talent_index
--       + 0.15 * regulatory_ease
--   composite_score = 40 + (raw - min(raw)) / (max(raw) - min(raw)) * (85 - 40)
--
-- Recommendation thresholds (match CSV):
--   Enter  if composite_score >= 70
--   Pilot  if composite_score >= 55
--   Watch  otherwise

CREATE OR REPLACE VIEW stg_market_entry_scorecard AS
SELECT * FROM read_csv_auto('data/cleaned/market_entry_scorecard.csv');

CREATE OR REPLACE VIEW mart_market_entry AS
WITH base AS (
  SELECT
    market,
    demand_index,
    competition_index,
    infra_readiness,
    talent_index,
    regulatory_ease,
    (
      0.35 * demand_index
      + 0.15 * (100 - competition_index)
      + 0.20 * infra_readiness
      + 0.15 * talent_index
      + 0.15 * regulatory_ease
    ) AS raw_score
  FROM stg_market_entry_scorecard
),
bounds AS (
  SELECT MIN(raw_score) AS raw_min, MAX(raw_score) AS raw_max FROM base
),
scored AS (
  SELECT
    b.*,
    ROUND(
      40 + (b.raw_score - bd.raw_min) / NULLIF(bd.raw_max - bd.raw_min, 0) * 45,
      1
    ) AS composite_score_recomputed
  FROM base b
  CROSS JOIN bounds bd
)
SELECT
  s.market,
  s.demand_index,
  s.competition_index,
  s.infra_readiness,
  s.talent_index,
  s.regulatory_ease,
  -- Prefer published mart score for dashboard recon; recomputed is the transparent formula
  m.composite_score AS composite_score,
  s.composite_score_recomputed,
  CASE
    WHEN m.composite_score >= 70 THEN 'Enter'
    WHEN m.composite_score >= 55 THEN 'Pilot'
    ELSE 'Watch'
  END AS recommendation,
  m.recommendation AS recommendation_published
FROM scored s
JOIN stg_market_entry_scorecard m USING (market)
ORDER BY m.composite_score DESC;

-- Enter / Pilot / Watch counts (Key Metrics: Enter = 5)
SELECT recommendation, COUNT(*) AS markets
FROM mart_market_entry
GROUP BY 1
ORDER BY 1;
