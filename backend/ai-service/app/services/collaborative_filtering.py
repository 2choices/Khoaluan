import json
import logging
import numpy as np
import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sklearn.metrics.pairwise import cosine_similarity

from app.cache import redis_client

logger = logging.getLogger(__name__)

CACHE_TTL = 3600  # 1 hour


class CollaborativeFilteringService:
    def __init__(self, db: Session):
        self.db = db

    def _get_order_data(self, tenant_id: str) -> pd.DataFrame:
        """Lấy dữ liệu đơn hàng để xây user-item matrix."""
        cache_key = f"ai:cf:data:{tenant_id}"
        cached = redis_client.get(cache_key)
        if cached:
            return pd.DataFrame(json.loads(cached))

        query = text("""
            SELECT o.customer_id, oi.product_id, SUM(oi.quantity) as quantity
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            WHERE o.tenant_id = :tenant_id
              AND o.status IN ('completed', 'confirmed')
              AND o.customer_id IS NOT NULL
            GROUP BY o.customer_id, oi.product_id
        """)
        try:
            result = self.db.execute(query, {"tenant_id": tenant_id})
            rows = [dict(r._mapping) for r in result]
        except SQLAlchemyError as error:
            self.db.rollback()
            logger.warning("Failed to load collaborative filtering data: %s", error)
            rows = []

        if rows:
            redis_client.setex(cache_key, CACHE_TTL, json.dumps(rows))

        return pd.DataFrame(rows) if rows else pd.DataFrame(columns=["customer_id", "product_id", "quantity"])

    def _build_user_item_matrix(self, df: pd.DataFrame):
        """Tạo user-item matrix từ dữ liệu đơn hàng."""
        if df.empty:
            return None, [], []

        matrix = df.pivot_table(
            index="customer_id",
            columns="product_id",
            values="quantity",
            fill_value=0,
        )
        return matrix, list(matrix.index), list(matrix.columns)

    def recommend(self, tenant_id: str, customer_id: str = None, product_id: str = None, limit: int = 10):
        """User-based collaborative filtering."""
        df = self._get_order_data(tenant_id)

        if df.empty:
            return {"product_ids": [], "scores": [], "method": "no_data"}

        if customer_id:
            return self._user_based_recommend(df, customer_id, limit)
        elif product_id:
            return self.similar_products(tenant_id, product_id, limit)
        else:
            # Popular products fallback
            return self._popular_products(df, limit)

    def _user_based_recommend(self, df: pd.DataFrame, customer_id: str, limit: int):
        """Gợi ý dựa trên user tương tự."""
        matrix, users, products = self._build_user_item_matrix(df)

        if matrix is None or customer_id not in users:
            return self._popular_products(df, limit)

        user_idx = users.index(customer_id)
        similarity = cosine_similarity(matrix.values)
        user_sim = similarity[user_idx]

        # Weighted sum of similar users' ratings
        scores = np.zeros(len(products))
        for i, sim in enumerate(user_sim):
            if i != user_idx and sim > 0:
                scores += sim * matrix.values[i]

        # Exclude already purchased
        purchased = set(df[df["customer_id"] == customer_id]["product_id"].tolist())
        result = []
        for idx in np.argsort(scores)[::-1]:
            pid = products[idx]
            if pid not in purchased and scores[idx] > 0:
                result.append((pid, float(scores[idx])))
            if len(result) >= limit:
                break

        return {
            "product_ids": [r[0] for r in result],
            "scores": [round(r[1], 4) for r in result],
            "method": "user_based_cf",
        }

    def similar_products(self, tenant_id: str, product_id: str, limit: int = 10):
        """Item-based collaborative filtering."""
        df = self._get_order_data(tenant_id)

        if df.empty:
            return {"product_ids": [], "scores": [], "method": "no_data"}

        matrix, users, products = self._build_user_item_matrix(df)
        if matrix is None or product_id not in products:
            return {"product_ids": [], "scores": [], "method": "item_not_found"}

        item_similarity = cosine_similarity(matrix.values.T)
        item_idx = products.index(product_id)
        sim_scores = item_similarity[item_idx]

        result = []
        for idx in np.argsort(sim_scores)[::-1]:
            if products[idx] != product_id and sim_scores[idx] > 0:
                result.append((products[idx], float(sim_scores[idx])))
            if len(result) >= limit:
                break

        return {
            "product_ids": [r[0] for r in result],
            "scores": [round(r[1], 4) for r in result],
            "method": "item_based_cf",
        }

    def _popular_products(self, df: pd.DataFrame, limit: int):
        """Fallback: sản phẩm bán chạy nhất."""
        popular = df.groupby("product_id")["quantity"].sum().sort_values(ascending=False).head(limit)
        max_qty = popular.max() if len(popular) > 0 else 1

        return {
            "product_ids": popular.index.tolist(),
            "scores": [round(float(q / max_qty), 4) for q in popular.values],
            "method": "popularity",
        }
