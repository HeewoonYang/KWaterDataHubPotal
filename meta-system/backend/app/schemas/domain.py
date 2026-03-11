"""
도메인사전 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ============================================================================
# 도메인그룹
# ============================================================================

class DomainGroupBase(BaseModel):
    """도메인그룹 기본 필드"""
    group_name: str = Field(..., max_length=50, description="도메인그룹명")
    description: Optional[str] = Field(None, description="설명")
    sort_order: int = Field(0, description="정렬순서")
    is_active: bool = Field(True, description="활성여부")


class DomainGroupCreate(DomainGroupBase):
    """도메인그룹 등록"""
    pass


class DomainGroupResponse(DomainGroupBase):
    """도메인그룹 응답"""
    group_id: int
    created_at: datetime
    updated_at: datetime
    domain_count: Optional[int] = Field(None, description="소속 도메인 수")

    class Config:
        from_attributes = True


# ============================================================================
# 도메인
# ============================================================================

class DomainBase(BaseModel):
    """도메인 기본 필드"""
    group_id: int = Field(..., description="도메인그룹 ID")
    domain_name: str = Field(..., max_length=200, description="도메인명")
    domain_logical_name: str = Field(..., max_length=200, description="도메인논리명")
    data_type: str = Field(..., max_length=30, description="데이터유형")
    data_length: Optional[int] = Field(None, description="길이")
    data_scale: Optional[int] = Field(None, description="소수점")
    is_personal_info: bool = Field(False, description="개인정보여부")
    is_encrypted: bool = Field(False, description="암호화여부")
    scramble_type: Optional[str] = Field(None, max_length=50, description="스크램블유형")
    description: Optional[str] = Field(None, description="설명")


class DomainCreate(DomainBase):
    """도메인 등록"""
    pass


class DomainUpdate(BaseModel):
    """도메인 수정 (부분 업데이트)"""
    group_id: Optional[int] = None
    domain_name: Optional[str] = Field(None, max_length=200)
    domain_logical_name: Optional[str] = Field(None, max_length=200)
    data_type: Optional[str] = Field(None, max_length=30)
    data_length: Optional[int] = None
    data_scale: Optional[int] = None
    is_personal_info: Optional[bool] = None
    is_encrypted: Optional[bool] = None
    scramble_type: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(active|inactive|deprecated)$")


class DomainResponse(DomainBase):
    """도메인 응답"""
    domain_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    group_name: Optional[str] = Field(None, description="도메인그룹명")

    class Config:
        from_attributes = True
