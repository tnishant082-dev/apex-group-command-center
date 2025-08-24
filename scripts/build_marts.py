#!/usr/bin/env python3
"""
Rebuild one real mart from landing/cleaned extracts.

Default: claims residual flags from Medical Cost Personal (landing)
  → data/marts/mart_claims_residuals.csv
  → refreshes anomaly_flag / anomaly_reason on data/cleaned/care_claims.csv
  → refreshes claims_anomaly_pct on data/marts/mart_care_kpi.csv

  Method: OLS charges ~ age + bmi + smoker + children + intercept.
  anomaly_flag = 1 when residual_usd >= 95th percentile of residual_usd
  (positive residual = above expected). Rate is computed from flags — not forced.

Optional: RFM from Online Retail II landing sample
  → data/marts/mart_retail_rfm_from_sample.csv

  Note: Dashboard PNG Champions = 1,028 used a fuller Online Retail II extract
  than the GitHub landing sample. The published mart_retail_rfm.csv (Champions=1028)
  is left untouched by this path; sample rebuild writes a separate file and yields
  fewer customers — documented, not a silent drift.

Usage (repo root):
  python scripts/build_marts.py
  python scripts/build_marts.py --mart claims
  python scripts/build_marts.py --mart rfm
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
# Portfolio convention for INR roll on Medical Cost USD charges (not a market FX feed).
FX_INR_PER_USD = 83.0


def build_claims_residuals() -> Path:
    landing = ROOT / "data/landing/insurance_medical_cost.csv"
    cleaned_path = ROOT / "data/cleaned/care_claims.csv"
    mart_path = ROOT / "data/marts/mart_claims_residuals.csv"
    care_kpi_path = ROOT / "data/marts/mart_care_kpi.csv"

    land = pd.read_csv(landing)
    cleaned = pd.read_csv(cleaned_path)

    if len(land) != len(cleaned):
        raise SystemExit(
            f"Row mismatch landing({len(land)}) vs cleaned care_claims({len(cleaned)})"
        )
    if not np.allclose(land["charges"].values, cleaned["charges"].values):
        raise SystemExit("charges column drift between landing and cleaned care_claims")

    smoker = (land["smoker"].astype(str).str.lower() == "yes").astype(float)
    X = np.column_stack(
        [
            land["age"].to_numpy(dtype=float),
            land["bmi"].to_numpy(dtype=float),
            smoker.to_numpy(dtype=float),
            land["children"].to_numpy(dtype=float),
            np.ones(len(land)),
        ]
    )
    y = land["charges"].to_numpy(dtype=float)
    coef, _, _, _ = np.linalg.lstsq(X, y, rcond=None)
    expected_usd = X @ coef
    residual_usd = y - expected_usd

    # Flag positive-tail residuals at/above the 95th percentile (above OLS expected cost).
    threshold = float(np.percentile(residual_usd, 95))
    flag = (residual_usd >= threshold).astype(int)

    reasons: list[str] = []
    for i in range(len(land)):
        if flag[i] == 0:
            reasons.append("")
            continue
        row = land.iloc[i]
        is_smoker = str(row["smoker"]).lower() == "yes"
        high_bmi = float(row["bmi"]) >= 30.0
        # Allowed reasons: high_residual | smoker_and_high_residual |
        # high_bmi_and_high_residual | other_high_residual (never provider/coding/duplicate labels).
        if is_smoker:
            reasons.append("smoker_and_high_residual")
        elif high_bmi:
            reasons.append("high_bmi_and_high_residual")
        else:
            reasons.append("high_residual")

    expected_inr = expected_usd * FX_INR_PER_USD
    residual_inr = residual_usd * FX_INR_PER_USD
    claim_amount_inr = land["charges"] * FX_INR_PER_USD

    mart = pd.DataFrame(
        {
            "claim_id": cleaned["claim_id"].values,
            "claim_date": cleaned["claim_date"].values,
            "age": land["age"].values,
            "sex": land["sex"].values,
            "bmi": land["bmi"].values,
            "children": land["children"].values,
            "smoker": land["smoker"].values,
            "payer": land["region"].values,
            "charges_usd": land["charges"].values,
            "claim_amount_inr": claim_amount_inr.round(2),
            "expected_cost_inr": expected_inr.round(2),
            "residual_inr": residual_inr.round(2),
            "anomaly_flag": flag,
            "anomaly_reason": [r if r else pd.NA for r in reasons],
        }
    )
    mart_path.parent.mkdir(parents=True, exist_ok=True)
    mart.to_csv(mart_path, index=False)

    cleaned = cleaned.copy()
    cleaned["anomaly_flag"] = flag
    cleaned["anomaly_reason"] = [r if r else pd.NA for r in reasons]
    cleaned.to_csv(cleaned_path, index=False)

    anomaly_pct = round(100.0 * float(flag.mean()), 2)
    if care_kpi_path.exists():
        kpi = pd.read_csv(care_kpi_path)
        if "claims_anomaly_pct" in kpi.columns:
            kpi["claims_anomaly_pct"] = anomaly_pct
            kpi.to_csv(care_kpi_path, index=False)

    print(f"Wrote {mart_path.relative_to(ROOT)} ({len(mart):,} rows)")
    print(
        f"Claims anomaly rate: {anomaly_pct}% "
        f"(flagged {int(flag.sum())}/{len(flag)}; residual_usd p95={threshold:.4f})"
    )
    print(f"OLS coef [age, bmi, smoker, children, intercept]: {coef.round(4).tolist()}")
    print("Reason counts (flagged):")
    print(pd.Series([r for r in reasons if r]).value_counts().to_string())
    return mart_path


def build_rfm() -> Path:
    """Rebuild RFM from the GitHub landing sample only.

    Writes data/marts/mart_retail_rfm_from_sample.csv and does NOT overwrite
    mart_retail_rfm.csv (published Champions=1028 from a fuller Online Retail II
    extract used for the dashboard PNG).
    """
    landing = ROOT / "data/landing/online_retail_ii_sample.csv"
    mart_path = ROOT / "data/marts/mart_retail_rfm_from_sample.csv"

    retail = pd.read_csv(landing)
    retail["InvoiceDate"] = pd.to_datetime(retail["InvoiceDate"])
    df = retail[
        (retail["Quantity"] > 0)
        & (retail["CustomerID"].notna())
        & (retail["Price"] >= 0)
    ].copy()
    df["line_gmv"] = df["Quantity"] * df["Price"]
    # FX roll GBP→INR for a single unit (portfolio convention; not statutory)
    gbp_to_inr = 100.0
    df["line_gmv_inr"] = df["line_gmv"] * gbp_to_inr

    as_of = df["InvoiceDate"].max()
    agg = (
        df.groupby("CustomerID", as_index=False)
        .agg(
            recency_days=("InvoiceDate", lambda s: (as_of - s.max()).days),
            frequency=("Invoice", "nunique"),
            monetary=("line_gmv_inr", "sum"),
        )
        .rename(columns={"CustomerID": "customer_id"})
    )

    # Quintile scores; R inverted so 5 = most recent
    agg["r_score"] = pd.qcut(
        agg["recency_days"], 5, labels=[5, 4, 3, 2, 1]
    ).astype(int)
    agg["f_score"] = pd.qcut(
        agg["frequency"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]
    ).astype(int)
    agg["m_score"] = pd.qcut(
        agg["monetary"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]
    ).astype(int)

    def segment(r: pd.Series) -> str:
        if r.r_score >= 4 and r.f_score >= 4 and r.m_score >= 4:
            return "Champions"
        if r.r_score >= 3 and r.f_score >= 3:
            return "Loyal"
        if r.r_score >= 3 and r.f_score <= 2:
            return "Potential"
        if r.r_score <= 2 and r.f_score >= 3:
            return "At Risk"
        return "Hibernating"

    agg["segment"] = agg.apply(segment, axis=1)
    out = agg[
        [
            "customer_id",
            "recency_days",
            "frequency",
            "monetary",
            "r_score",
            "f_score",
            "m_score",
            "segment",
        ]
    ]
    out.to_csv(mart_path, index=False)
    print(f"Wrote {mart_path.relative_to(ROOT)} ({len(out):,} customers)")
    print(out["segment"].value_counts().to_string())
    print(
        "Note: sample landing → fewer customers than fuller-extract dashboard PNG "
        "(Champions=1,028 in mart_retail_rfm.csv; left untouched)."
    )
    return mart_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Rebuild Apex Group mart CSVs")
    parser.add_argument(
        "--mart",
        choices=("claims", "rfm"),
        default="claims",
        help="Which mart to rebuild (default: claims residual flags)",
    )
    args = parser.parse_args()
    if args.mart == "claims":
        build_claims_residuals()
    else:
        build_rfm()


if __name__ == "__main__":
    main()
