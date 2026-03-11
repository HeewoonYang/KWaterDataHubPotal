"""
공통 Pydantic 스키마
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class StatusMessage(BaseModel):
    """상태 메시지 응답"""
    message: str
    success: bool = True


class ImportResult(BaseModel):
    """엑셀 임포트 결과"""
    total_rows: int
    success_count: int
    error_count: int
    errors: list[dict] = []
    message: str
