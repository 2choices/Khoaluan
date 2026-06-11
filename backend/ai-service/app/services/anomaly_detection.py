import logging
import pandas as pd
import numpy as np
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sklearn.ensemble import IsolationForest

logger = logging.getLogger(__name__)


class AnomalyDetectionService:
    def __init__(self, db: Session):
        self.db = db

    def detect(self, tenant_id: str, contamination: float = 0.05) -> dict:
        """Phát hiện bất thường trong doanh số bằng Isolation Forest."""
        query = text("""
            SELECT
                DATE(created_at) as date,
                COUNT(id) as order_count,
                SUM(total_amount) as revenue,
                AVG(total_amount) as avg_order_value
            FROM orders
            WHERE tenant_id = :tenant_id
              AND status IN ('completed', 'confirmed')
            GROUP BY DATE(created_at)
            ORDER BY date
        """)
        try:
            result = self.db.execute(query, {"tenant_id": tenant_id})
            rows = [dict(r._mapping) for r in result]
        except SQLAlchemyError as error:
            self.db.rollback()
            logger.warning("Failed to load anomaly detection data: %s", error)
            rows = []

        if len(rows) < 20:
            return {"anomalies": [], "message": "Cần ít nhất 20 ngày dữ liệu"}

        df = pd.DataFrame(rows)
        df["date"] = pd.to_datetime(df["date"])
        df["order_count"] = df["order_count"].astype(int)
        df["revenue"] = df["revenue"].astype(float)
        df["avg_order_value"] = df["avg_order_value"].astype(float)

        # Day of week feature
        df["day_of_week"] = df["date"].dt.dayofweek

        features = df[["order_count", "revenue", "avg_order_value", "day_of_week"]].values

        model = IsolationForest(
            contamination=contamination,
            random_state=42,
            n_estimators=100,
        )
        df["anomaly"] = model.fit_predict(features)
        df["anomaly_score"] = model.score_samples(features)

        anomalies = df[df["anomaly"] == -1].copy()

        results = []
        for _, row in anomalies.iterrows():
            results.append({
                "date": row["date"].strftime("%Y-%m-%d"),
                "order_count": int(row["order_count"]),
                "revenue": float(row["revenue"]),
                "avg_order_value": round(float(row["avg_order_value"]), 0),
                "anomaly_score": round(float(row["anomaly_score"]), 4),
                "severity": "high" if row["anomaly_score"] < -0.3 else "medium",
            })

        # Summary stats
        normal = df[df["anomaly"] == 1]
        avg_revenue = float(normal["revenue"].mean()) if not normal.empty else 0
        avg_orders = float(normal["order_count"].mean()) if not normal.empty else 0

        return {
            "anomalies": results,
            "total_days_analyzed": len(df),
            "anomaly_count": len(results),
            "normal_avg_revenue": round(avg_revenue, 0),
            "normal_avg_orders": round(avg_orders, 1),
        }
