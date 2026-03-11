"""
용어사전 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class TermBase(BaseModel):
    """용어 기본 필드"""
    logical_name: str = Field(..., max_length=300, description="논리명")
    physical_name: str = Field(..., max_length=200, description="물리명")
    english_name: Optional[str] = Field(None, max_length=500, description="영문의미")
    domain_logical_name: Optional[str] = Field(None, max_length=200, description="도메인논리명")
    domain_id: Optional[int] = Field(None, description="도메인 ID")
    domain_abbr: Optional[str] = Field(None, max_length=100, description="도메인논리약어")
    domain_group_id: Optional[int] = Field(None, description="도메인그룹 ID")
    data_type: Optional[str] = Field(None, max_length=30, description="데이터유형")
    data_length: Optional[int] = Field(None, description="길이")
    data_scale: Optional[int] = Field(None, description="소수점")
    is_personal_info: bool = Field(False, description="개인정보여부")
    is_encrypted: bool = Field(False, description="암호화여부")
    scramble_type: Optional[str] = Field(None, max_length=50, description="스크램블유형")
    description: Optional[str] = Field(None, description="설명")


class TermCreate(TermBase):
    """용어 등록"""
    pass


class TermUpdate(BaseModel):
    """용어 수정 (부분 업데이트)"""
    logical_name: Optional[str] = Field(None, max_length=300)
    physical_name: Optional[str] = Field(None, max_length=200)
    english_name: Optional[str] = Field(None, max_length=500)
    domain_logical_name: Optional[str] = Field(None, max_length=200)
    domain_id: Optional[int] = None
    domain_abbr: Optional[str] = Field(None, max_length=100)
    domain_group_id: Optional[int] = None
    data_type: Optional[str] = Field(None, max_length=30)
    data_length: Optional[int] = None
    data_scale: Optional[int] = None
    is_personal_info: Optional[bool] = None
    is_encrypted: Optional[bool] = None
    scramble_type: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(active|inactive|deprecated)$")


class TermResponse(TermBase):
    """용어 응답"""
    term_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    group_name: Optional[str] = Field(None, description="도메인그룹명")

    class Config:
        from_attributes = True
