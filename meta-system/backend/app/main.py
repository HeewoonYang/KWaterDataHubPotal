"""
K-water DataHub 메타데이터 표준사전 관리 시스템 — FastAPI 진입점
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.api.v1.router import api_router

app = FastAPI(
    title="K-water 메타데이터 표준사전 API",
    description="K-water DataHub Portal 메타데이터 관리 시스템 — 단어/도메인/용어/코드 표준사전 API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS 미들웨어
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(api_router, prefix="/api/v1")


@app.get("/", tags=["헬스체크"])
async def root():
    """서버 상태 확인"""
    return {
        "service": "K-water 메타데이터 표준사전 API",
        "version": "1.0.0",
        "status": "running",
    }


@app.get("/health", tags=["헬스체크"])
async def health_check():
    """헬스체크 엔드포인트"""
    return {"status": "healthy"}
