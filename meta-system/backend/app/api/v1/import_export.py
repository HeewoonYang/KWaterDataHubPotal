"""
엑셀 임포트/엑스포트 API 엔드포인트
"""
from fastapi import APIRouter, Depends, UploadFile, File, Path, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services import import_service

router = APIRouter()


@router.post("/import/{dict_type}", summary="엑셀 임포트")
async def import_excel(
    dict_type: str,
    file: UploadFile = File(..., description="엑셀 파일 (.xlsx)"),
    db: AsyncSession = Depends(get_db),
):
    """엑셀 파일을 업로드하여 사전 데이터를 적재합니다.

    - dict_type: word (단어사전), domain (도메인사전), term (용어사전)
    """
    file_bytes = await file.read()

    if dict_type == "word":
        result = await import_service.import_word_dict(db, file_bytes)
    elif dict_type == "domain":
        result = await import_service.import_domain_dict(db, file_bytes)
    elif dict_type == "term":
        result = await import_service.import_term_dict(db, file_bytes)
    else:
        return {"error": f"지원하지 않는 사전 유형: {dict_type}"}

    return result


@router.get("/export/{dict_type}", summary="엑셀 엑스포트")
async def export_excel(
    dict_type: str = Path(..., description="사전 유형 (word/domain/term)"),
    db: AsyncSession = Depends(get_db),
):
    """사전 데이터를 엑셀 파일로 다운로드합니다."""
    return await import_service.export_dict(db, dict_type)


@router.get("/history", summary="변경이력 조회")
async def get_history(
    dict_type: str = Query(None, description="사전 유형 필터"),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    """변경이력 조회"""
    from sqlalchemy import select, func
    from app.models.history import StdChangeHistory

    query = select(StdChangeHistory)
    count_query = select(func.count(StdChangeHistory.history_id))

    if dict_type:
        query = query.where(StdChangeHistory.dict_type == dict_type)
        count_query = count_query.where(StdChangeHistory.dict_type == dict_type)

    total = (await db.execute(count_query)).scalar() or 0

    query = query.order_by(StdChangeHistory.changed_at.desc())
    offset = (page - 1) * size
    query = query.offset(offset).limit(size)

    result = await db.execute(query)
    items = result.scalars().all()

    return {
        "items": [
            {
                "history_id": h.history_id,
                "dict_type": h.dict_type,
                "record_id": h.record_id,
                "action": h.action,
                "change_desc": h.change_desc,
                "prev_value": h.prev_value,
                "new_value": h.new_value,
                "changed_by": h.changed_by,
                "changed_at": h.changed_at.isoformat() if h.changed_at else None,
            }
            for h in items
        ],
        "total": total,
        "page": page,
        "size": size,
        "pages": (total + size - 1) // size if size > 0 else 0,
    }
