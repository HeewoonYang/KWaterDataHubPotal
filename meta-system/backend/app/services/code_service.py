"""
코드사전 비즈니스 로직
"""
from typing import Optional, Tuple, List
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.code import StdCodeGroup, StdCode
from app.schemas.code import CodeGroupCreate, CodeGroupUpdate, CodeCreate, CodeUpdate
from app.core.exceptions import NotFoundException, DuplicateException


# ============================================================================
# 코드그룹
# ============================================================================

async def get_code_groups(
    db: AsyncSession,
    page: int = 1,
    size: int = 50,
    system_prefix: Optional[str] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = None,
    order: str = "asc",
) -> Tuple[List[StdCodeGroup], int]:
    """코드그룹 목록 조회"""
    query = select(StdCodeGroup)
    count_query = select(func.count(StdCodeGroup.group_id))

    if system_prefix:
        query = query.where(StdCodeGroup.system_prefix == system_prefix)
        count_query = count_query.where(StdCodeGroup.system_prefix == system_prefix)

    if search:
        search_filter = or_(
            StdCodeGroup.logical_name.ilike(f"%{search}%"),
            StdCodeGroup.physical_name.ilike(f"%{search}%"),
            StdCodeGroup.code_id.ilike(f"%{search}%"),
            StdCodeGroup.code_desc.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    sort_column = getattr(StdCodeGroup, sort_by, None) if sort_by else StdCodeGroup.group_id
    if sort_column is None:
        sort_column = StdCodeGroup.group_id
    if order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())

    offset = (page - 1) * size
    query = query.offset(offset).limit(size)

    result = await db.execute(query)
    items = list(result.scalars().all())
    return items, total


async def get_code_group(db: AsyncSession, group_id: int) -> StdCodeGroup:
    """코드그룹 단건 조회"""
    result = await db.execute(
        select(StdCodeGroup).where(StdCodeGroup.group_id == group_id)
    )
    group = result.scalar_one_or_none()
    if not group:
        raise NotFoundException("코드그룹", group_id)
    return group


async def create_code_group(db: AsyncSession, data: CodeGroupCreate) -> StdCodeGroup:
    """코드그룹 등록"""
    existing = await db.execute(
        select(StdCodeGroup).where(StdCodeGroup.code_id == data.code_id)
    )
    if existing.scalar_one_or_none():
        raise DuplicateException("코드그룹", "코드ID", data.code_id)

    group = StdCodeGroup(**data.model_dump())
    db.add(group)
    await db.commit()
    await db.refresh(group)
    return group


async def update_code_group(db: AsyncSession, group_id: int, data: CodeGroupUpdate) -> StdCodeGroup:
    """코드그룹 수정"""
    group = await get_code_group(db, group_id)
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(group, key, value)
    await db.commit()
    await db.refresh(group)
    return group


async def get_group_by_code_id(db: AsyncSession, code_id: str) -> dict:
    """코드그룹을 code_id(문자열)로 조회 → 그룹정보 + 하위 코드 배열 반환"""
    result = await db.execute(
        select(StdCodeGroup).where(StdCodeGroup.code_id == code_id)
    )
    group = result.scalar_one_or_none()
    if not group:
        raise NotFoundException("코드그룹", code_id)

    # 하위 코드 조회 (active만, 정렬순서)
    codes_result = await db.execute(
        select(StdCode)
        .where(StdCode.group_id == group.group_id, StdCode.status == "active")
        .order_by(StdCode.sort_order)
    )
    codes = list(codes_result.scalars().all())

    return {
        "group_id": group.group_id,
        "code_id": group.code_id,
        "logical_name": group.logical_name,
        "physical_name": group.physical_name,
        "code_desc": group.code_desc,
        "codes": [
            {
                "code_id": c.code_id,
                "code_value": c.code_value,
                "code_name": c.code_name,
                "sort_order": c.sort_order,
                "description": c.description,
            }
            for c in codes
        ],
    }


async def get_system_prefixes(db: AsyncSession) -> List[dict]:
    """시스템 접두어 목록 (필터용)"""
    result = await db.execute(
        select(
            StdCodeGroup.system_prefix,
            StdCodeGroup.system_name,
            func.count(StdCodeGroup.group_id).label("group_count"),
        )
        .where(StdCodeGroup.status == "active")
        .group_by(StdCodeGroup.system_prefix, StdCodeGroup.system_name)
        .order_by(StdCodeGroup.system_prefix)
    )
    return [
        {"system_prefix": row[0], "system_name": row[1], "group_count": row[2]}
        for row in result.all()
    ]


# ============================================================================
# 코드
# ============================================================================

async def get_codes(
    db: AsyncSession,
    group_id: int,
    page: int = 1,
    size: int = 100,
    search: Optional[str] = None,
    sort_by: Optional[str] = None,
    order: str = "asc",
) -> Tuple[List[StdCode], int]:
    """코드 목록 조회 (그룹 필터 필수)"""
    query = select(StdCode).where(StdCode.group_id == group_id)
    count_query = select(func.count(StdCode.code_id)).where(StdCode.group_id == group_id)

    if search:
        search_filter = or_(
            StdCode.code_value.ilike(f"%{search}%"),
            StdCode.code_name.ilike(f"%{search}%"),
            StdCode.description.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 정렬 (기본: sort_order)
    sort_column = getattr(StdCode, sort_by, None) if sort_by else StdCode.sort_order
    if sort_column is None:
        sort_column = StdCode.sort_order
    if order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())

    offset = (page - 1) * size
    query = query.offset(offset).limit(size)

    result = await db.execute(query)
    items = list(result.scalars().all())
    return items, total


async def get_code(db: AsyncSession, code_id: int) -> StdCode:
    """코드 단건 조회"""
    result = await db.execute(select(StdCode).where(StdCode.code_id == code_id))
    code = result.scalar_one_or_none()
    if not code:
        raise NotFoundException("코드", code_id)
    return code


async def create_code(db: AsyncSession, data: CodeCreate) -> StdCode:
    """코드 등록"""
    code = StdCode(**data.model_dump())
    db.add(code)
    await db.commit()
    await db.refresh(code)
    return code


async def update_code(db: AsyncSession, code_id: int, data: CodeUpdate) -> StdCode:
    """코드 수정"""
    code = await get_code(db, code_id)
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(code, key, value)
    await db.commit()
    await db.refresh(code)
    return code


async def delete_code(db: AsyncSession, code_id: int) -> StdCode:
    """코드 소프트 삭제"""
    code = await get_code(db, code_id)
    code.status = "deprecated"
    await db.commit()
    await db.refresh(code)
    return code


async def get_code_tree(db: AsyncSession, group_id: int) -> List[dict]:
    """코드 계층 트리 조회"""
    result = await db.execute(
        select(StdCode)
        .where(StdCode.group_id == group_id, StdCode.status == "active")
        .order_by(StdCode.sort_order)
    )
    codes = list(result.scalars().all())

    # 부모-자식 관계 구성
    code_map = {}
    roots = []
    for code in codes:
        node = {
            "code_id": code.code_id,
            "code_value": code.code_value,
            "code_name": code.code_name,
            "children": [],
        }
        code_map[code.code_id] = node
        if code.parent_id and code.parent_id in code_map:
            code_map[code.parent_id]["children"].append(node)
        else:
            roots.append(node)

    return roots
