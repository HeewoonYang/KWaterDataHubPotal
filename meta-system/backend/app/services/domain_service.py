"""
도메인사전 비즈니스 로직
"""
from typing import Optional, Tuple, List
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.domain import StdDomainGroup, StdDomain
from app.schemas.domain import DomainGroupCreate, DomainCreate, DomainUpdate
from app.core.exceptions import NotFoundException, DuplicateException


# ============================================================================
# 도메인그룹
# ============================================================================

async def get_domain_groups(db: AsyncSession) -> List[StdDomainGroup]:
    """도메인그룹 전체 조회"""
    result = await db.execute(
        select(StdDomainGroup).order_by(StdDomainGroup.sort_order)
    )
    return list(result.scalars().all())


async def get_domain_group(db: AsyncSession, group_id: int) -> StdDomainGroup:
    """도메인그룹 단건 조회"""
    result = await db.execute(
        select(StdDomainGroup).where(StdDomainGroup.group_id == group_id)
    )
    group = result.scalar_one_or_none()
    if not group:
        raise NotFoundException("도메인그룹", group_id)
    return group


# ============================================================================
# 도메인
# ============================================================================

async def get_domains(
    db: AsyncSession,
    page: int = 1,
    size: int = 50,
    group_id: Optional[int] = None,
    data_type: Optional[str] = None,
    is_personal_info: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = None,
    order: str = "asc",
) -> Tuple[List[StdDomain], int]:
    """도메인 목록 조회"""
    query = select(StdDomain)
    count_query = select(func.count(StdDomain.domain_id))

    # 필터
    if group_id:
        query = query.where(StdDomain.group_id == group_id)
        count_query = count_query.where(StdDomain.group_id == group_id)

    if data_type:
        query = query.where(StdDomain.data_type == data_type)
        count_query = count_query.where(StdDomain.data_type == data_type)

    if is_personal_info is not None:
        query = query.where(StdDomain.is_personal_info == is_personal_info)
        count_query = count_query.where(StdDomain.is_personal_info == is_personal_info)

    if search:
        search_filter = or_(
            StdDomain.domain_name.ilike(f"%{search}%"),
            StdDomain.domain_logical_name.ilike(f"%{search}%"),
            StdDomain.description.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)

    # 전체 건수
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 정렬
    sort_column = getattr(StdDomain, sort_by, None) if sort_by else StdDomain.domain_id
    if sort_column is None:
        sort_column = StdDomain.domain_id
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


async def get_domain(db: AsyncSession, domain_id: int) -> StdDomain:
    """도메인 단건 조회"""
    result = await db.execute(
        select(StdDomain).where(StdDomain.domain_id == domain_id)
    )
    domain = result.scalar_one_or_none()
    if not domain:
        raise NotFoundException("도메인", domain_id)
    return domain


async def create_domain(db: AsyncSession, data: DomainCreate) -> StdDomain:
    """도메인 등록"""
    existing = await db.execute(
        select(StdDomain).where(StdDomain.domain_logical_name == data.domain_logical_name)
    )
    if existing.scalar_one_or_none():
        raise DuplicateException("도메인", "도메인논리명", data.domain_logical_name)

    domain = StdDomain(**data.model_dump())
    db.add(domain)
    await db.commit()
    await db.refresh(domain)
    return domain


async def update_domain(db: AsyncSession, domain_id: int, data: DomainUpdate) -> StdDomain:
    """도메인 수정"""
    domain = await get_domain(db, domain_id)
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(domain, key, value)
    await db.commit()
    await db.refresh(domain)
    return domain


async def delete_domain(db: AsyncSession, domain_id: int) -> StdDomain:
    """도메인 소프트 삭제"""
    domain = await get_domain(db, domain_id)
    domain.status = "deprecated"
    await db.commit()
    await db.refresh(domain)
    return domain
