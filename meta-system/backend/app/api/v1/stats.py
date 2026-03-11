"""
통계 API 엔드포인트
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services import stats_service

router = APIRouter()


@router.get("/summary", summary="전체 통계 요약")
async def get_summary(db: AsyncSession = Depends(get_db)):
    """전체 사전별 건수 및 변경 통계"""
    return await stats_service.get_summary(db)


@router.get("/domain-distribution", summary="도메인그룹별 분포")
async def get_domain_distribution(db: AsyncSession = Depends(get_db)):
    """도메인그룹별 도메인 건수 분포"""
    return await stats_service.get_domain_distribution(db)


@router.get("/data-types", summary="데이터유형별 분포")
async def get_data_type_distribution(db: AsyncSession = Depends(get_db)):
    """데이터유형별 도메인/용어 분포"""
    return await stats_service.get_data_type_distribution(db)


@router.get("/code-groups", summary="코드그룹별 분포")
async def get_code_group_distribution(db: AsyncSession = Depends(get_db)):
    """시스템 접두어별 코드그룹/코드 분포"""
    return await stats_service.get_code_group_distribution(db)
