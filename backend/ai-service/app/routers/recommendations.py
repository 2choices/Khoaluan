from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    BasketAnalysisRequest,
    AssociationRule,
)
from app.services.collaborative_filtering import CollaborativeFilteringService
from app.services.basket_analysis import BasketAnalysisService

router = APIRouter()


@router.post("/recommendations/products", response_model=RecommendationResponse)
async def get_product_recommendations(
    request: RecommendationRequest,
    db: Session = Depends(get_db),
):
    """Gợi ý sản phẩm dựa trên Collaborative Filtering."""
    service = CollaborativeFilteringService(db)
    return service.recommend(
        tenant_id=request.tenant_id,
        customer_id=request.customer_id,
        product_id=request.product_id,
        limit=request.limit,
    )


@router.post("/recommendations/similar/{product_id}", response_model=RecommendationResponse)
async def get_similar_products(
    product_id: str,
    tenant_id: str,
    limit: int = 10,
    db: Session = Depends(get_db),
):
    """Sản phẩm tương tự (item-based CF)."""
    service = CollaborativeFilteringService(db)
    return service.similar_products(
        tenant_id=tenant_id,
        product_id=product_id,
        limit=limit,
    )


@router.post("/recommendations/basket", response_model=list[AssociationRule])
async def get_basket_suggestions(
    request: BasketAnalysisRequest,
    db: Session = Depends(get_db),
):
    """Gợi ý combo dựa trên phân tích giỏ hàng (Apriori)."""
    service = BasketAnalysisService(db)
    return service.get_suggestions(
        tenant_id=request.tenant_id,
        product_ids=request.product_ids,
        min_support=request.min_support,
        min_confidence=request.min_confidence,
    )
