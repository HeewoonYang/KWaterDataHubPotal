"""
코드사전 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date


# ============================================================================
# 코드그룹
# ============================================================================

class CodeGroupBase(BaseModel):
    """코드그룹 기본 필드"""
    system_prefix: str = Field(..., max_length=30, description="시스템접두어")
    system_name: Optional[str] = Field(None, max_length=100, description="시스템명")
    logical_name: str = Field(..., max_length=200, description="논리명")
    physical_name: str = Field(..., max_length=200, description="물리명")
    code_desc: Optional[str] = Field(None, description="코드설명")
    code_type: Optional[str] = Field(None, max_length=30, description="코드구분")
    data_length: Optional[int] = Field(None, description="길이")
    code_id: str = Field(..., max_length=50, description="코드ID")


class CodeGroupCreate(CodeGroupBase):
    """코드그룹 등록"""
    pass


class CodeGroupUpdate(BaseModel):
    """코드그룹 수정"""
    system_prefix: Optional[str] = Field(None, max_length=30)
    system_name: Optional[str] = Field(None, max_length=100)
    logical_name: Optional[str] = Field(None, max_length=200)
    physical_name: Optional[str] = Field(None, max_length=200)
    code_desc: Optional[str] = None
    code_type: Optional[str] = Field(None, max_length=30)
    data_length: Optional[int] = None
    status: Optional[str] = Field(None, pattern="^(active|inactive|deprecated)$")


class CodeGroupResponse(CodeGroupBase):
    """코드그룹 응답"""
    group_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    code_count: Optional[int] = Field(None, description="소속 코드 수")

    class Config:
        from_attributes = True


# ============================================================================
# 코드
# ============================================================================

class CodeBase(BaseModel):
    """코드 기본 필드"""
    group_id: int = Field(..., description="코드그룹 ID")
    code_value: str = Field(..., max_length=100, description="코드값")
    code_name: str = Field(..., max_length=500, description="코드값명")
    sort_order: int = Field(0, description="정렬순서")
    parent_code_name: Optional[str] = Field(None, max_length=200, description="부모코드명")
    parent_code_value: Optional[str] = Field(None, max_length=100, description="부모코드값")
    parent_id: Optional[int] = Field(None, description="부모코드 ID")
    description: Optional[str] = Field(None, description="설명")
    effective_from: Optional[date] = Field(None, description="적용시작일자")
    effective_to: Optional[date] = Field(None, description="적용종료일자")


class CodeCreate(CodeBase):
    """코드 등록"""
    pass


class CodeUpdate(BaseModel):
    """코드 수정"""
    code_value: Optional[str] = Field(None, max_length=100)
    code_name: Optional[str] = Field(None, max_length=500)
    sort_order: Optional[int] = None
    parent_code_name: Optional[str] = Field(None, max_length=200)
    parent_code_value: Optional[str] = Field(None, max_length=100)
    parent_id: Optional[int] = None
    description: Optional[str] = None
    effective_from: Optional[date] = None
    effective_to: Optional[date] = None
    status: Optional[str] = Field(None, pattern="^(active|inactive|deprecated)$")


class CodeResponse(CodeBase):
    """코드 응답"""
    code_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    group_logical_name: Optional[str] = Field(None, description="코드그룹 논리명")

    class Config:
        from_attributes = True


class CodeTreeNode(BaseModel):
    """코드 트리 노드"""
    code_id: int
    code_value: str
    code_name: str
    children: list["CodeTreeNode"] = []

    class Config:
        from_attributes = True
