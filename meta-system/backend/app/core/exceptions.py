"""
공통 예외 처리
"""
from fastapi import HTTPException, status


class NotFoundException(HTTPException):
    """리소스를 찾을 수 없음"""
    def __init__(self, resource: str, resource_id: int):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{resource}을(를) 찾을 수 없습니다. (ID: {resource_id})"
        )


class DuplicateException(HTTPException):
    """중복 데이터"""
    def __init__(self, resource: str, field: str, value: str):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"{resource}의 {field} '{value}'이(가) 이미 존재합니다."
        )


class ValidationException(HTTPException):
    """데이터 검증 오류"""
    def __init__(self, detail: str):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail
        )
