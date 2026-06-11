import json
import logging
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

from app.cache import redis_client

logger = logging.getLogger(__name__)

CACHE_TTL = 3600

SEGMENT_NAMES = {
    0: "Champions",
    1: "Loyal Customers",
    2: "At Risk",
    3: "Lost",
}


class CustomerSegmentationService:
    def __init__(self, db: Session):
        self.db = db

    def _get_rfm_data(self, tenant_id: str) -> pd.DataFrame:
        """Tính RFM cho mỗi khách hàng."""
        cache_key = f"ai:rfm:data:{tenant_id}"
        cached = redis_client.get(cache_key)
        if cached:
            return pd.DataFrame(json.loads(cached))

        query = text("""
            SELECT
                o.customer_id,
                MAX(o.created_at) as last_order,
                COUNT(o.id) as frequency,
                SUM(o.total_amount) as monetary
            FROM orders o
            WHERE o.tenant_id = :tenant_id
              AND o.status IN ('completed', 'confirmed')
              AND o.customer_id IS NOT NULL
            GROUP BY o.customer_id
        """)
        try:
            result = self.db.execute(query, {"tenant_id": tenant_id})
            rows = [dict(r._mapping) for r in result]
        except SQLAlchemyError as error:
            self.db.rollback()
            logger.warning("Failed to load customer RFM data: %s", error)
            rows = []

        if not rows:
            return pd.DataFrame(columns=["customer_id", "recency", "frequency", "monetary"])

        df = pd.DataFrame(rows)
        now = datetime.utcnow()
        df["recency"] = df["last_order"].apply(
            lambda x: (now - pd.to_datetime(x).replace(tzinfo=None)).days if x else 999
        )
        df["frequency"] = df["frequency"].astype(int)
        df["monetary"] = df["monetary"].astype(float)
        df = df[["customer_id", "recency", "frequency", "monetary"]]

        redis_client.setex(cache_key, CACHE_TTL, df.to_json(orient="records"))
        return df

    def segment(self, tenant_id: str, n_clusters: int = 4) -> list[dict]:
        """K-Means clustering trên RFM data."""
        df = self._get_rfm_data(tenant_id)

        if df.empty or len(df) < n_clusters:
            return []

        features = df[["recency", "frequency", "monetary"]].values
        scaler = StandardScaler()
        scaled = scaler.fit_transform(features)

        kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        df["segment"] = kmeans.fit_predict(scaled)

        # Sort clusters by monetary (descending) to assign meaningful names
        cluster_order = (
            df.groupby("segment")["monetary"]
            .mean()
            .sort_values(ascending=False)
            .index.tolist()
        )
        name_map = {}
        for i, cluster_id in enumerate(cluster_order):
            name_map[cluster_id] = SEGMENT_NAMES.get(i, f"Segment {i}")

        results = []
        for _, row in df.iterrows():
            seg = int(row["segment"])
            results.append({
                "customer_id": str(row["customer_id"]),
                "segment": seg,
                "segment_name": name_map.get(seg, f"Segment {seg}"),
                "rfm_score": f"R{int(row['recency'])}F{int(row['frequency'])}M{int(row['monetary'])}",
            })

        return results

    def get_rfm_score(self, tenant_id: str, customer_id: str) -> dict:
        """RFM score cho 1 khách hàng cụ thể."""
        df = self._get_rfm_data(tenant_id)

        if df.empty:
            return {"error": "No data available"}

        customer = df[df["customer_id"] == customer_id]
        if customer.empty:
            return {"error": "Customer not found"}

        row = customer.iloc[0]

        # Score 1-5 for each RFM dimension
        for col in ["recency", "frequency", "monetary"]:
            ascending = col == "recency"
            df[f"{col}_score"] = pd.qcut(
                df[col].rank(method="first"),
                q=5,
                labels=[5, 4, 3, 2, 1] if ascending else [1, 2, 3, 4, 5],
            ).astype(int)

        c = df[df["customer_id"] == customer_id].iloc[0]

        return {
            "customer_id": customer_id,
            "recency_days": int(row["recency"]),
            "frequency": int(row["frequency"]),
            "monetary": float(row["monetary"]),
            "r_score": int(c["recency_score"]),
            "f_score": int(c["frequency_score"]),
            "m_score": int(c["monetary_score"]),
            "rfm_total": int(c["recency_score"] + c["frequency_score"] + c["monetary_score"]),
        }
