"""
용어사전 비즈니스 로직
"""
from typing import Optional, Tuple, List
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.term import StdTerm
from app.schemas.term import TermCreate, TermUpdate
from app.core.exceptions import NotFoundException, DuplicateException


async def get_terms(
    db: AsyncSession,
    page: int = 1,
    size: int = 50,
    search: Optional[str] = None,
    domain_group_id: Optional[int] = None,
    data_type: Optional[str] = None,
    is_personal_info: Optional[bool] = None,
    status: Optional[str] = None,
    sort_by: Optional[str] = None,
    order: str = "asc",
) -> Tuple[List[StdTerm], int]:
    """용어 목록 조회 (페이지네이션 + 필터)"""
    query = select(StdTerm)
    count_query = select(func.count(StdTerm.term_id))

    # 필터
    if search:
        search_filter = or_(
            StdTerm.logical_name.ilike(f"%{search}%"),
            StdTerm.physical_name.ilike(f"%{search}%"),
            StdTerm.english_name.ilike(f"%{search}%"),
            StdTerm.description.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)

    if domain_group_id:
        query = query.where(StdTerm.domain_group_id == domain_group_id)
        count_query = count_query.where(StdTerm.domain_group_id == domain_group_id)

    if data_type:
        query = query.where(StdTerm.data_type == data_type)
        count_query = count_query.where(StdTerm.data_type == data_type)

    if is_personal_info is not None:
        query = query.where(StdTerm.is_personal_info == is_personal_info)
        count_query = count_query.where(StdTerm.is_personal_info == is_personal_info)

    if status:
        query = query.where(StdTerm.status == status)
        count_query = count_query.where(StdTerm.status == status)

    # 전체 건수
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 정렬
    sort_column = getattr(StdTerm, sort_by, None) if sort_by else StdTerm.term_id
    if sort_column is None:
        sort_column = StdTerm.term_id
    if order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())

    # 페이지네이션
    offset = (page - 1) * size
    query = query.offset(offset).limit(size)

    result = await db.execute(query)
    items = list(result.scalars().all())
    return items, total


async def get_term(db: AsyncSession, term_id: int) -> StdTerm:
    """용어 단건 조회"""
    result = await db.execute(select(StdTerm).where(StdTerm.term_id == term_id))
    term = result.scalar_one_or_none()
    if not term:
        raise NotFoundException("용어", term_id)
    return term


async def create_term(db: AsyncSession, data: TermCreate) -> StdTerm:
    """용어 등록"""
    existing = await db.execute(
        select(StdTerm).where(StdTerm.physical_name == data.physical_name)
    )
    if existing.scalar_one_or_none():
        raise DuplicateException("용어", "물리명", data.physical_name)

    term = StdTerm(**data.model_dump())
    db.add(term)
    await db.commit()
    await db.refresh(term)
    return term


async def update_term(db: AsyncSession, term_id: int, data: TermUpdate) -> StdTerm:
    """용어 수정"""
    term = await get_term(db, term_id)
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(term, key, value)
    await db.commit()
    await db.refresh(term)
    return term


async def delete_term(db: AsyncSession, term_id: int) -> StdTerm:
    """용어 소프트 삭제"""
    term = await get_term(db, term_id)
    term.status = "deprecated"
    await db.commit()
    await db.refresh(term)
    return term
