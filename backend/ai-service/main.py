import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

from app.routers import recommendations, analytics, health

app = FastAPI(
    title="OMNIGO AI Service",
    version="1.0.0",
    description="AI/ML microservice for product recommendations, customer analytics, and forecasting",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, tags=["Health"])
app.include_router(recommendations.router, prefix="/api/v1/ai", tags=["Recommendations"])
app.include_router(analytics.router, prefix="/api/v1/ai", tags=["Analytics"])

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=True,
        log_level="info",
    )
