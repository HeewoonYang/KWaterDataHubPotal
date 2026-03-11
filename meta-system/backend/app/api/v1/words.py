"""
단어사전 API 엔드포인트
"""
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.word import WordCreate, WordUpdate, WordResponse
from app.schemas.common import StatusMessage
from app.core.pagination import PageResponse
from app.services import word_service

router = APIRouter()


@router.get("", response_model=PageResponse[WordResponse], summary="단어 목록 조회")
async def list_words(
    page: int = Query(1, ge=1, description="페이지 번호"),
    size: int = Query(50, ge=1, le=200, description="페이지 크기"),
    search: Optional[str] = Query(None, description="검색어 (논리명/물리명/설명)"),
    is_class_word: Optional[bool] = Query(None, description="속성분류어 필터"),
    status: Optional[str] = Query(None, description="상태 필터"),
    sort_by: Optional[str] = Query(None, description="정렬 컬럼"),
    order: str = Query("asc", pattern="^(asc|desc)$", description="정렬 방향"),
    db: AsyncSession = Depends(get_db),
):
    """단어사전 목록을 페이지네이션으로 조회합니다."""
    items, total = await word_service.get_words(
        db, page=page, size=size, search=search,
        is_class_word=is_class_word, status=status,
        sort_by=sort_by, order=order,
    )
    return PageResponse.create(
        items=[WordResponse.model_validate(item) for item in items],
        total=total, page=page, size=size,
    )


@router.get("/{word_id}", response_model=WordResponse, summary="단어 상세 조회")
async def get_word(word_id: int, db: AsyncSession = Depends(get_db)):
    """단어 단건 상세 조회"""
    word = await word_service.get_word(db, word_id)
    return WordResponse.model_validate(word)


@router.post("", response_model=WordResponse, status_code=201, summary="단어 등록")
async def create_word(data: WordCreate, db: AsyncSession = Depends(get_db)):
    """신규 단어 등록"""
    word = await word_service.create_word(db, data)
    return WordResponse.model_validate(word)


@router.put("/{word_id}", response_model=WordResponse, summary="단어 수정")
async def update_word(word_id: int, data: WordUpdate, db: AsyncSession = Depends(get_db)):
    """단어 정보 수정"""
    word = await word_service.update_word(db, word_id, data)
    return WordResponse.model_validate(word)


@router.delete("/{word_id}", response_model=StatusMessage, summary="단어 삭제")
async def delete_word(word_id: int, db: AsyncSession = Depends(get_db)):
    """단어 소프트 삭제 (status → deprecated)"""
    await word_service.delete_word(db, word_id)
    return StatusMessage(message=f"단어(ID: {word_id})가 비활성화되었습니다.")
