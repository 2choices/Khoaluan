import logging
import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

logger = logging.getLogger(__name__)


class ForecastingService:
    def __init__(self, db: Session):
        self.db = db

    def _get_revenue_timeseries(self, tenant_id: str) -> pd.DataFrame:
        """Lấy doanh thu theo ngày."""
        query = text("""
            SELECT
                DATE(created_at) as ds,
                SUM(total_amount) as y
            FROM orders
            WHERE tenant_id = :tenant_id
              AND status IN ('completed', 'confirmed')
            GROUP BY DATE(created_at)
            ORDER BY ds
        """)
        try:
            result = self.db.execute(query, {"tenant_id": tenant_id})
            rows = [dict(r._mapping) for r in result]
        except SQLAlchemyError as error:
            self.db.rollback()
            logger.warning("Failed to load revenue timeseries: %s", error)
            rows = []

        if not rows:
            return pd.DataFrame(columns=["ds", "y"])

        df = pd.DataFrame(rows)
        df["ds"] = pd.to_datetime(df["ds"])
        df["y"] = df["y"].astype(float)
        return df

    def forecast(self, tenant_id: str, periods: int = 30, frequency: str = "D") -> list[dict]:
        """Dự đoán doanh thu bằng Prophet. Fallback ARIMA nếu Prophet fail."""
        df = self._get_revenue_timeseries(tenant_id)

        if len(df) < 14:
            return self._simple_forecast(df, periods)

        try:
            return self._prophet_forecast(df, periods)
        except Exception as e:
            logger.warning(f"Prophet failed, using simple forecast: {e}")
            return self._simple_forecast(df, periods)

    def _prophet_forecast(self, df: pd.DataFrame, periods: int) -> list[dict]:
        """Forecast bằng Facebook Prophet."""
        from prophet import Prophet

        model = Prophet(
            daily_seasonality=True,
            weekly_seasonality=True,
            yearly_seasonality=False,
            changepoint_prior_scale=0.05,
        )
        model.fit(df)

        future = model.make_future_dataframe(periods=periods)
        forecast = model.predict(future)

        # Chỉ lấy phần dự đoán tương lai
        future_forecast = forecast.tail(periods)
        results = []
        for _, row in future_forecast.iterrows():
            results.append({
                "date": row["ds"].strftime("%Y-%m-%d"),
                "value": round(max(0, float(row["yhat"])), 0),
                "lower": round(max(0, float(row["yhat_lower"])), 0),
                "upper": round(max(0, float(row["yhat_upper"])), 0),
            })

        return results

    def _simple_forecast(self, df: pd.DataFrame, periods: int) -> list[dict]:
        """Fallback đơn giản: dùng trung bình 7 ngày gần nhất."""
        if df.empty:
            return []

        recent = df.tail(7)
        avg = float(recent["y"].mean())
        std = float(recent["y"].std()) if len(recent) > 1 else avg * 0.2

        last_date = df["ds"].max()
        results = []
        for i in range(1, periods + 1):
            date = last_date + pd.Timedelta(days=i)
            results.append({
                "date": date.strftime("%Y-%m-%d"),
                "value": round(max(0, avg), 0),
                "lower": round(max(0, avg - 1.96 * std), 0),
                "upper": round(avg + 1.96 * std, 0),
            })

        return results
