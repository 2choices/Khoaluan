import json
import logging
import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from mlxtend.frequent_patterns import apriori, association_rules
from mlxtend.preprocessing import TransactionEncoder

from app.cache import redis_client

logger = logging.getLogger(__name__)

CACHE_TTL = 3600


class BasketAnalysisService:
    def __init__(self, db: Session):
        self.db = db

    def _get_transactions(self, tenant_id: str) -> list[list[str]]:
        """Lấy danh sách giao dịch (mỗi order = 1 transaction)."""
        cache_key = f"ai:basket:txns:{tenant_id}"
        cached = redis_client.get(cache_key)
        if cached:
            return json.loads(cached)

        query = text("""
            SELECT o.id as order_id, oi.product_id
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            WHERE o.tenant_id = :tenant_id
              AND o.status IN ('completed', 'confirmed')
        """)
        try:
            result = self.db.execute(query, {"tenant_id": tenant_id})
        except SQLAlchemyError as error:
            self.db.rollback()
            logger.warning("Failed to load basket transactions: %s", error)
            return []

        orders: dict[str, list[str]] = {}
        for row in result:
            r = row._mapping
            oid = str(r["order_id"])
            pid = str(r["product_id"])
            if oid not in orders:
                orders[oid] = []
            orders[oid].append(pid)

        transactions = list(orders.values())
        if transactions:
            redis_client.setex(cache_key, CACHE_TTL, json.dumps(transactions))

        return transactions

    def get_suggestions(
        self,
        tenant_id: str,
        product_ids: list[str],
        min_support: float = 0.01,
        min_confidence: float = 0.3,
    ) -> list[dict]:
        """Tìm association rules cho các sản phẩm đang trong giỏ hàng."""
        transactions = self._get_transactions(tenant_id)

        if len(transactions) < 10:
            return []

        # Encode transactions
        te = TransactionEncoder()
        te_array = te.fit(transactions).transform(transactions)
        df = pd.DataFrame(te_array, columns=te.columns_)

        # Find frequent itemsets
        try:
            frequent = apriori(df, min_support=min_support, use_colnames=True)
            if frequent.empty:
                return []

            rules = association_rules(frequent, metric="confidence", min_threshold=min_confidence)
            if rules.empty:
                return []
        except Exception as e:
            logger.error(f"Apriori error: {e}")
            return []

        # Filter rules where antecedents match current basket
        product_set = set(product_ids)
        suggestions = []

        for _, rule in rules.iterrows():
            antecedents = set(rule["antecedents"])
            consequents = set(rule["consequents"])

            if antecedents.issubset(product_set) and not consequents.issubset(product_set):
                suggestions.append({
                    "antecedents": list(antecedents),
                    "consequents": list(consequents),
                    "confidence": round(float(rule["confidence"]), 4),
                    "support": round(float(rule["support"]), 4),
                    "lift": round(float(rule["lift"]), 4),
                })

        suggestions.sort(key=lambda x: x["confidence"], reverse=True)
        return suggestions[:20]
