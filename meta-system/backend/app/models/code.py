"""
표준 코드사전 ORM 모델 (코드그룹 + 코드)
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Date, ForeignKey, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class StdCodeGroup(Base):
    """표준 코드그룹"""
    __tablename__ = "std_code_group"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive','deprecated')", name="ck_std_code_group_status"),
        {"schema": "meta"},
    )

    group_id = Column(Integer, primary_key=True, autoincrement=True)
    system_prefix = Column(String(30), nullable=False, comment="시스템접두어")
    system_name = Column(String(100), comment="시스템명")
    logical_name = Column(String(200), nullable=False, comment="논리명")
    physical_name = Column(String(200), nullable=False, comment="물리명")
    code_desc = Column(Text, comment="코드설명")
    code_type = Column(String(30), comment="코드구분")
    data_length = Column(Integer, comment="길이")
    code_id = Column(String(50), nullable=False, unique=True, comment="코드ID")
    status = Column(String(20), default="active", comment="상태")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 관계
    codes = relationship("StdCode", back_populates="group", lazy="selectin")


class StdCode(Base):
    """표준 코드사전"""
    __tablename__ = "std_code"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive','deprecated')", name="ck_std_code_status"),
        UniqueConstraint("group_id", "code_value", name="uq_std_code_group_value"),
        {"schema": "meta"},
    )

    code_id = Column(Integer, primary_key=True, autoincrement=True)
    group_id = Column(Integer, ForeignKey("meta.std_code_group.group_id", ondelete="CASCADE"), nullable=False)
    code_value = Column(String(100), nullable=False, comment="코드값")
    code_name = Column(String(500), nullable=False, comment="코드값명")
    sort_order = Column(Integer, default=0, comment="정렬순서")
    parent_code_name = Column(String(200), comment="부모코드명")
    parent_code_value = Column(String(100), comment="부모코드값")
    parent_id = Column(Integer, ForeignKey("meta.std_code.code_id"), comment="부모코드 FK")
    description = Column(Text, comment="설명")
    effective_from = Column(Date, comment="적용시작일자")
    effective_to = Column(Date, comment="적용종료일자")
    status = Column(String(20), default="active", comment="상태")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 관계
    group = relationship("StdCodeGroup", back_populates="codes")
    children = relationship("StdCode", lazy="selectin")
