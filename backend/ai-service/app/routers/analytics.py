from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.schemas import (
    CustomerSegmentRequest,
    CustomerSegment,
    ForecastRequest,
    ForecastPoint,
    AnomalyRequest,
)
from app.services.customer_segmentation import CustomerSegmentationService
from app.services.forecasting import ForecastingService
from app.services.anomaly_detection import AnomalyDetectionService

router = APIRouter()


@router.post("/analytics/segments", response_model=list[CustomerSegment])
async def segment_customers(
    request: CustomerSegmentRequest,
    db: Session = Depends(get_db),
):
    """Phân nhóm khách hàng bằng K-Means + RFM."""
    service = CustomerSegmentationService(db)
    return service.segment(
        tenant_id=request.tenant_id,
        n_clusters=request.n_clusters,
    )


@router.get("/analytics/rfm/{customer_id}")
async def get_customer_rfm(
    customer_id: str,
    tenant_id: str,
    db: Session = Depends(get_db),
):
    """Phân tích RFM cho một khách hàng."""
    service = CustomerSegmentationService(db)
    return service.get_rfm_score(tenant_id=tenant_id, customer_id=customer_id)


@router.post("/analytics/forecast", response_model=list[ForecastPoint])
async def forecast_revenue(
    request: ForecastRequest,
    db: Session = Depends(get_db),
):
    """Dự đoán doanh thu bằng Prophet/ARIMA."""
    service = ForecastingService(db)
    return service.forecast(
        tenant_id=request.tenant_id,
        periods=request.periods,
        frequency=request.frequency,
    )


@router.post("/analytics/anomalies")
async def detect_anomalies(
    request: AnomalyRequest,
    db: Session = Depends(get_db),
):
    """Phát hiện bất thường bằng Isolation Forest."""
    service = AnomalyDetectionService(db)
    return service.detect(
        tenant_id=request.tenant_id,
        contamination=request.contamination,
    )
