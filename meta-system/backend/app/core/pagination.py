"""
페이지네이션 유틸리티
"""
from typing import TypeVar, Generic, List, Optional
from pydantic import BaseModel, Field

T = TypeVar("T")


class PageParams(BaseModel):
    """오프셋 기반 페이지네이션 파라미터"""
    page: int = Field(default=1, ge=1, description="페이지 번호")
    size: int = Field(default=50, ge=1, le=200, description="페이지 크기")

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size


class PageResponse(BaseModel, Generic[T]):
    """페이지네이션 응답"""
    items: List[T]
    total: int = Field(description="전체 건수")
    page: int = Field(description="현재 페이지")
    size: int = Field(description="페이지 크기")
    pages: int = Field(description="전체 페이지 수")

    @classmethod
    def create(cls, items: List[T], total: int, page: int, size: int):
        pages = (total + size - 1) // size if size > 0 else 0
        return cls(items=items, total=total, page=page, size=size, pages=pages)


class SortParams(BaseModel):
    """정렬 파라미터"""
    sort_by: Optional[str] = Field(default=None, description="정렬 컬럼")
    order: str = Field(default="asc", pattern="^(asc|desc)$", description="정렬 방향")
