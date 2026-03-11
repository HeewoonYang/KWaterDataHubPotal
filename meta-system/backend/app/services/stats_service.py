"""
통계 비즈니스 로직
"""
from sqlalchemy import select, func, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.word import StdWord
from app.models.domain import StdDomainGroup, StdDomain
from app.models.term import StdTerm
from app.models.code import StdCodeGroup, StdCode
from app.models.history import StdChangeHistory


async def get_summary(db: AsyncSession) -> dict:
    """전체 사전 요약 통계"""
    # 각 사전별 건수 조회
    word_count = (await db.execute(select(func.count(StdWord.word_id)))).scalar() or 0
    domain_group_count = (await db.execute(select(func.count(StdDomainGroup.group_id)))).scalar() or 0
    domain_count = (await db.execute(select(func.count(StdDomain.domain_id)))).scalar() or 0
    term_count = (await db.execute(select(func.count(StdTerm.term_id)))).scalar() or 0
    code_group_count = (await db.execute(select(func.count(StdCodeGroup.group_id)))).scalar() or 0
    code_count = (await db.execute(select(func.count(StdCode.code_id)))).scalar() or 0
    history_count = (await db.execute(select(func.count(StdChangeHistory.history_id)))).scalar() or 0

    return {
        "dictionaries": [
            {"name": "단어사전", "type": "word", "count": word_count},
            {"name": "도메인그룹", "type": "domain_group", "count": domain_group_count},
            {"name": "도메인사전", "type": "domain", "count": domain_count},
            {"name": "용어사전", "type": "term", "count": term_count},
            {"name": "코드그룹", "type": "code_group", "count": code_group_count},
            {"name": "코드사전", "type": "code", "count": code_count},
        ],
        "total_records": word_count + domain_count + term_count + code_count,
        "total_changes": history_count,
    }


async def get_domain_distribution(db: AsyncSession) -> list:
    """도메인그룹별 분포 통계"""
    result = await db.execute(
        select(
            StdDomainGroup.group_name,
            func.count(StdDomain.domain_id).label("domain_count"),
        )
        .outerjoin(StdDomain, StdDomain.group_id == StdDomainGroup.group_id)
        .group_by(StdDomainGroup.group_name, StdDomainGroup.sort_order)
        .order_by(StdDomainGroup.sort_order)
    )
    return [
        {"group_name": row[0], "domain_count": row[1]}
        for row in result.all()
    ]


async def get_data_type_distribution(db: AsyncSession) -> dict:
    """데이터유형별 분포 통계"""
    # 도메인 데이터유형 분포
    domain_result = await db.execute(
        select(
            StdDomain.data_type,
            func.count(StdDomain.domain_id).label("count"),
        )
        .where(StdDomain.status == "active")
        .group_by(StdDomain.data_type)
        .order_by(func.count(StdDomain.domain_id).desc())
    )

    # 용어 데이터유형 분포
    term_result = await db.execute(
        select(
            StdTerm.data_type,
            func.count(StdTerm.term_id).label("count"),
        )
        .where(StdTerm.status == "active", StdTerm.data_type.isnot(None))
        .group_by(StdTerm.data_type)
        .order_by(func.count(StdTerm.term_id).desc())
    )

    return {
        "domain_types": [
            {"data_type": row[0], "count": row[1]} for row in domain_result.all()
        ],
        "term_types": [
            {"data_type": row[0], "count": row[1]} for row in term_result.all()
        ],
    }


async def get_code_group_distribution(db: AsyncSession) -> list:
    """시스템 접두어별 코드그룹/코드 분포"""
    result = await db.execute(
        select(
            StdCodeGroup.system_prefix,
            StdCodeGroup.system_name,
            func.count(func.distinct(StdCodeGroup.group_id)).label("group_count"),
            func.count(StdCode.code_id).label("code_count"),
        )
        .outerjoin(StdCode, StdCode.group_id == StdCodeGroup.group_id)
        .where(StdCodeGroup.status == "active")
        .group_by(StdCodeGroup.system_prefix, StdCodeGroup.system_name)
        .order_by(StdCodeGroup.system_prefix)
    )
    return [
        {
            "system_prefix": row[0],
            "system_name": row[1],
            "group_count": row[2],
            "code_count": row[3],
        }
        for row in result.all()
    ]
