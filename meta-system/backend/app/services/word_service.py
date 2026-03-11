"""
단어사전 비즈니스 로직
"""
from typing import Optional, Tuple, List
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.word import StdWord
from app.schemas.word import WordCreate, WordUpdate
from app.core.exceptions import NotFoundException, DuplicateException


async def get_words(
    db: AsyncSession,
    page: int = 1,
    size: int = 50,
    search: Optional[str] = None,
    is_class_word: Optional[bool] = None,
    status: Optional[str] = None,
    sort_by: Optional[str] = None,
    order: str = "asc",
) -> Tuple[List[StdWord], int]:
    """단어 목록 조회 (페이지네이션 + 필터)"""
    query = select(StdWord)
    count_query = select(func.count(StdWord.word_id))

    # 필터
    if search:
        search_filter = or_(
            StdWord.logical_name.ilike(f"%{search}%"),
            StdWord.physical_name.ilike(f"%{search}%"),
            StdWord.physical_desc.ilike(f"%{search}%"),
            StdWord.description.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)

    if is_class_word is not None:
        query = query.where(StdWord.is_class_word == is_class_word)
        count_query = count_query.where(StdWord.is_class_word == is_class_word)

    if status:
        query = query.where(StdWord.status == status)
        count_query = count_query.where(StdWord.status == status)

    # 전체 건수
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 정렬
    sort_column = getattr(StdWord, sort_by, None) if sort_by else StdWord.word_id
    if sort_column is None:
        sort_column = StdWord.word_id
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


async def get_word(db: AsyncSession, word_id: int) -> StdWord:
    """단어 단건 조회"""
    result = await db.execute(select(StdWord).where(StdWord.word_id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        raise NotFoundException("단어", word_id)
    return word


async def create_word(db: AsyncSession, data: WordCreate) -> StdWord:
    """단어 등록"""
    # 중복 검사
    existing = await db.execute(
        select(StdWord).where(
            or_(
                StdWord.logical_name == data.logical_name,
                StdWord.physical_name == data.physical_name,
            )
        )
    )
    if existing.scalar_one_or_none():
        raise DuplicateException("단어", "논리명/물리명", data.logical_name)

    word = StdWord(**data.model_dump())
    db.add(word)
    await db.commit()
    await db.refresh(word)
    return word


async def update_word(db: AsyncSession, word_id: int, data: WordUpdate) -> StdWord:
    """단어 수정"""
    word = await get_word(db, word_id)
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(word, key, value)
    await db.commit()
    await db.refresh(word)
    return word


async def delete_word(db: AsyncSession, word_id: int) -> StdWord:
    """단어 소프트 삭제"""
    word = await get_word(db, word_id)
    word.status = "deprecated"
    await db.commit()
    await db.refresh(word)
    return word
