"""
용어사전 API 엔드포인트
"""
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.term import TermCreate, TermUpdate, TermResponse
from app.schemas.common import StatusMessage
from app.core.pagination import PageResponse
from app.services import term_service

router = APIRouter()


@router.get("", response_model=PageResponse[TermResponse], summary="용어 목록 조회")
async def list_terms(
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    search: Optional[str] = Query(None, description="검색어 (논리명/물리명/영문의미)"),
    domain_group_id: Optional[int] = Query(None, description="도메인그룹 ID"),
    data_type: Optional[str] = Query(None, description="데이터유형"),
    is_personal_info: Optional[bool] = Query(None, description="개인정보 필터"),
    status: Optional[str] = Query(None, description="상태 필터"),
    sort_by: Optional[str] = Query(None),
    order: str = Query("asc", pattern="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
):
    """용어사전 목록 조회 (41,359건 대응 서버사이드 페이지네이션)"""
    items, total = await term_service.get_terms(
        db, page=page, size=size, search=search,
        domain_group_id=domain_group_id, data_type=data_type,
        is_personal_info=is_personal_info, status=status,
        sort_by=sort_by, order=order,
    )
    return PageResponse.create(
        items=[TermResponse.model_validate(item) for item in items],
        total=total, page=page, size=size,
    )


@router.get("/{term_id}", response_model=TermResponse, summary="용어 상세 조회")
async def get_term(term_id: int, db: AsyncSession = Depends(get_db)):
    """용어 단건 조회"""
    term = await term_service.get_term(db, term_id)
    return TermResponse.model_validate(term)


@router.post("", response_model=TermResponse, status_code=201, summary="용어 등록")
async def create_term(data: TermCreate, db: AsyncSession = Depends(get_db)):
    """신규 용어 등록"""
    term = await term_service.create_term(db, data)
    return TermResponse.model_validate(term)


@router.put("/{term_id}", response_model=TermResponse, summary="용어 수정")
async def update_term(term_id: int, data: TermUpdate, db: AsyncSession = Depends(get_db)):
    """용어 정보 수정"""
    term = await term_service.update_term(db, term_id, data)
    return TermResponse.model_validate(term)


@router.delete("/{term_id}", response_model=StatusMessage, summary="용어 삭제")
async def delete_term(term_id: int, db: AsyncSession = Depends(get_db)):
    """용어 소프트 삭제"""
    await term_service.delete_term(db, term_id)
    return StatusMessage(message=f"용어(ID: {term_id})가 비활성화되었습니다.")
