"""
코드사전 API 엔드포인트
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.code import (
    CodeGroupCreate, CodeGroupUpdate, CodeGroupResponse,
    CodeCreate, CodeUpdate, CodeResponse,
)
from app.schemas.common import StatusMessage
from app.core.pagination import PageResponse
from app.services import code_service

router = APIRouter()


# ============================================================================
# 코드그룹
# ============================================================================

@router.get("/code-groups", response_model=PageResponse[CodeGroupResponse], summary="코드그룹 목록")
async def list_code_groups(
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    system_prefix: Optional[str] = Query(None, description="시스템 접두어 필터"),
    search: Optional[str] = Query(None, description="검색어"),
    sort_by: Optional[str] = Query(None),
    order: str = Query("asc", pattern="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
):
    """코드그룹 목록 조회"""
    items, total = await code_service.get_code_groups(
        db, page=page, size=size, system_prefix=system_prefix,
        search=search, sort_by=sort_by, order=order,
    )
    return PageResponse.create(
        items=[CodeGroupResponse.model_validate(item) for item in items],
        total=total, page=page, size=size,
    )


@router.get("/code-groups/by-code-id/{code_id}", summary="코드그룹 code_id로 조회")
async def get_group_by_code_id(code_id: str, db: AsyncSession = Depends(get_db)):
    """코드그룹을 code_id(문자열)로 조회하여 그룹정보 + 하위 코드 목록 반환"""
    return await code_service.get_group_by_code_id(db, code_id)


@router.get("/code-groups/prefixes", summary="시스템 접두어 목록")
async def list_system_prefixes(db: AsyncSession = Depends(get_db)):
    """시스템 접두어 목록 (필터 드롭다운용)"""
    return await code_service.get_system_prefixes(db)


@router.get("/code-groups/{group_id}", response_model=CodeGroupResponse, summary="코드그룹 상세")
async def get_code_group(group_id: int, db: AsyncSession = Depends(get_db)):
    """코드그룹 단건 조회"""
    group = await code_service.get_code_group(db, group_id)
    return CodeGroupResponse.model_validate(group)


@router.post("/code-groups", response_model=CodeGroupResponse, status_code=201, summary="코드그룹 등록")
async def create_code_group(data: CodeGroupCreate, db: AsyncSession = Depends(get_db)):
    """신규 코드그룹 등록"""
    group = await code_service.create_code_group(db, data)
    return CodeGroupResponse.model_validate(group)


@router.put("/code-groups/{group_id}", response_model=CodeGroupResponse, summary="코드그룹 수정")
async def update_code_group(group_id: int, data: CodeGroupUpdate, db: AsyncSession = Depends(get_db)):
    """코드그룹 수정"""
    group = await code_service.update_code_group(db, group_id, data)
    return CodeGroupResponse.model_validate(group)


# ============================================================================
# 코드
# ============================================================================

@router.get("/codes", response_model=PageResponse[CodeResponse], summary="코드 목록 조회")
async def list_codes(
    group_id: int = Query(..., description="코드그룹 ID (필수)"),
    page: int = Query(1, ge=1),
    size: int = Query(100, ge=1, le=200),
    search: Optional[str] = Query(None, description="검색어"),
    sort_by: Optional[str] = Query(None),
    order: str = Query("asc", pattern="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
):
    """코드 목록 조회 (그룹 ID 필수 — 14만건 전체 조회 방지)"""
    items, total = await code_service.get_codes(
        db, group_id=group_id, page=page, size=size,
        search=search, sort_by=sort_by, order=order,
    )
    return PageResponse.create(
        items=[CodeResponse.model_validate(item) for item in items],
        total=total, page=page, size=size,
    )


@router.get("/codes/tree/{group_id}", summary="코드 트리 조회")
async def get_code_tree(group_id: int, db: AsyncSession = Depends(get_db)):
    """계층형 코드 트리 구조 조회"""
    return await code_service.get_code_tree(db, group_id)


@router.get("/codes/{code_id}", response_model=CodeResponse, summary="코드 상세")
async def get_code(code_id: int, db: AsyncSession = Depends(get_db)):
    """코드 단건 조회"""
    code = await code_service.get_code(db, code_id)
    return CodeResponse.model_validate(code)


@router.post("/codes", response_model=CodeResponse, status_code=201, summary="코드 등록")
async def create_code(data: CodeCreate, db: AsyncSession = Depends(get_db)):
    """신규 코드 등록"""
    code = await code_service.create_code(db, data)
    return CodeResponse.model_validate(code)


@router.put("/codes/{code_id}", response_model=CodeResponse, summary="코드 수정")
async def update_code(code_id: int, data: CodeUpdate, db: AsyncSession = Depends(get_db)):
    """코드 수정"""
    code = await code_service.update_code(db, code_id, data)
    return CodeResponse.model_validate(code)


@router.delete("/codes/{code_id}", response_model=StatusMessage, summary="코드 삭제")
async def delete_code(code_id: int, db: AsyncSession = Depends(get_db)):
    """코드 소프트 삭제"""
    await code_service.delete_code(db, code_id)
    return StatusMessage(message=f"코드(ID: {code_id})가 비활성화되었습니다.")
