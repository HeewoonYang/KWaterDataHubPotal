"""
도메인사전 API 엔드포인트
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.domain import (
    DomainGroupResponse, DomainCreate, DomainUpdate, DomainResponse,
)
from app.schemas.common import StatusMessage
from app.core.pagination import PageResponse
from app.services import domain_service

router = APIRouter()


# ============================================================================
# 도메인그룹
# ============================================================================

@router.get("/domain-groups", response_model=List[DomainGroupResponse], summary="도메인그룹 목록")
async def list_domain_groups(db: AsyncSession = Depends(get_db)):
    """도메인그룹 전체 목록 (11건)"""
    groups = await domain_service.get_domain_groups(db)
    return [DomainGroupResponse.model_validate(g) for g in groups]


@router.get("/domain-groups/{group_id}", response_model=DomainGroupResponse, summary="도메인그룹 상세")
async def get_domain_group(group_id: int, db: AsyncSession = Depends(get_db)):
    """도메인그룹 단건 조회"""
    group = await domain_service.get_domain_group(db, group_id)
    return DomainGroupResponse.model_validate(group)


# ============================================================================
# 도메인
# ============================================================================

@router.get("/domains", response_model=PageResponse[DomainResponse], summary="도메인 목록 조회")
async def list_domains(
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    group_id: Optional[int] = Query(None, description="도메인그룹 ID 필터"),
    data_type: Optional[str] = Query(None, description="데이터유형 필터"),
    is_personal_info: Optional[bool] = Query(None, description="개인정보 필터"),
    search: Optional[str] = Query(None, description="검색어"),
    sort_by: Optional[str] = Query(None),
    order: str = Query("asc", pattern="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
):
    """도메인사전 목록 조회"""
    items, total = await domain_service.get_domains(
        db, page=page, size=size, group_id=group_id,
        data_type=data_type, is_personal_info=is_personal_info,
        search=search, sort_by=sort_by, order=order,
    )
    return PageResponse.create(
        items=[DomainResponse.model_validate(item) for item in items],
        total=total, page=page, size=size,
    )


@router.get("/domains/{domain_id}", response_model=DomainResponse, summary="도메인 상세")
async def get_domain(domain_id: int, db: AsyncSession = Depends(get_db)):
    """도메인 단건 조회"""
    domain = await domain_service.get_domain(db, domain_id)
    return DomainResponse.model_validate(domain)


@router.post("/domains", response_model=DomainResponse, status_code=201, summary="도메인 등록")
async def create_domain(data: DomainCreate, db: AsyncSession = Depends(get_db)):
    """신규 도메인 등록"""
    domain = await domain_service.create_domain(db, data)
    return DomainResponse.model_validate(domain)


@router.put("/domains/{domain_id}", response_model=DomainResponse, summary="도메인 수정")
async def update_domain(domain_id: int, data: DomainUpdate, db: AsyncSession = Depends(get_db)):
    """도메인 정보 수정"""
    domain = await domain_service.update_domain(db, domain_id, data)
    return DomainResponse.model_validate(domain)


@router.delete("/domains/{domain_id}", response_model=StatusMessage, summary="도메인 삭제")
async def delete_domain(domain_id: int, db: AsyncSession = Depends(get_db)):
    """도메인 소프트 삭제"""
    await domain_service.delete_domain(db, domain_id)
    return StatusMessage(message=f"도메인(ID: {domain_id})이 비활성화되었습니다.")
