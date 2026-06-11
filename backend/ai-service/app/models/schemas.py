from pydantic import BaseModel
from typing import Optional


class RecommendationRequest(BaseModel):
    tenant_id: str
    customer_id: Optional[str] = None
    product_id: Optional[str] = None
    limit: int = 10


class RecommendationResponse(BaseModel):
    product_ids: list[str]
    scores: list[float]
    method: str


class BasketAnalysisRequest(BaseModel):
    tenant_id: str
    product_ids: list[str]
    min_support: float = 0.01
    min_confidence: float = 0.3


class AssociationRule(BaseModel):
    antecedents: list[str]
    consequents: list[str]
    confidence: float
    support: float
    lift: float


class CustomerSegmentRequest(BaseModel):
    tenant_id: str
    n_clusters: int = 4


class CustomerSegment(BaseModel):
    customer_id: str
    segment: int
    segment_name: str
    rfm_score: Optional[str] = None


class ForecastRequest(BaseModel):
    tenant_id: str
    periods: int = 30
    frequency: str = "D"


class ForecastPoint(BaseModel):
    date: str
    value: float
    lower: float
    upper: float


class AnomalyRequest(BaseModel):
    tenant_id: str
    contamination: float = 0.05
