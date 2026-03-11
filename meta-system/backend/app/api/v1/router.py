"""
API v1 라우터 — 모든 엔드포인트 통합
"""
from fastapi import APIRouter

from app.api.v1 import words, domains, terms, codes, stats, import_export

api_router = APIRouter()

api_router.include_router(words.router, prefix="/words", tags=["단어사전"])
api_router.include_router(domains.router, prefix="", tags=["도메인사전"])
api_router.include_router(terms.router, prefix="/terms", tags=["용어사전"])
api_router.include_router(codes.router, prefix="", tags=["코드사전"])
api_router.include_router(stats.router, prefix="/stats", tags=["통계"])
api_router.include_router(import_export.router, prefix="", tags=["임포트/엑스포트"])
