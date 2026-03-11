"""
단어사전 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class WordBase(BaseModel):
    """단어 기본 필드"""
    logical_name: str = Field(..., max_length=200, description="논리명")
    physical_name: str = Field(..., max_length=100, description="물리명")
    physical_desc: Optional[str] = Field(None, max_length=500, description="물리의미")
    is_class_word: bool = Field(False, description="속성분류어 여부")
    synonym: Optional[str] = Field(None, max_length=500, description="동의어")
    description: Optional[str] = Field(None, description="설명")


class WordCreate(WordBase):
    """단어 등록"""
    pass


class WordUpdate(BaseModel):
    """단어 수정 (부분 업데이트)"""
    logical_name: Optional[str] = Field(None, max_length=200)
    physical_name: Optional[str] = Field(None, max_length=100)
    physical_desc: Optional[str] = Field(None, max_length=500)
    is_class_word: Optional[bool] = None
    synonym: Optional[str] = Field(None, max_length=500)
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(active|inactive|deprecated)$")


class WordResponse(WordBase):
    """단어 응답"""
    word_id: int
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
