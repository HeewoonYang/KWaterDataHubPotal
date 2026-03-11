"""
표준 도메인사전 ORM 모델 (도메인그룹 + 도메인)
"""
from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class StdDomainGroup(Base):
    """표준 도메인그룹 (11종)"""
    __tablename__ = "std_domain_group"
    __table_args__ = {"schema": "meta"}

    group_id = Column(Integer, primary_key=True, autoincrement=True)
    group_name = Column(String(50), nullable=False, unique=True, comment="도메인그룹명")
    description = Column(Text, comment="설명")
    sort_order = Column(Integer, default=0, comment="정렬순서")
    is_active = Column(Boolean, default=True, comment="활성여부")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 관계
    domains = relationship("StdDomain", back_populates="group", lazy="selectin")


class StdDomain(Base):
    """표준 도메인사전"""
    __tablename__ = "std_domain"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive','deprecated')", name="ck_std_domain_status"),
        {"schema": "meta"},
    )

    domain_id = Column(Integer, primary_key=True, autoincrement=True)
    group_id = Column(Integer, ForeignKey("meta.std_domain_group.group_id"), nullable=False)
    domain_name = Column(String(200), nullable=False, comment="도메인명")
    domain_logical_name = Column(String(200), nullable=False, unique=True, comment="도메인논리명")
    data_type = Column(String(30), nullable=False, comment="데이터유형")
    data_length = Column(Integer, comment="길이")
    data_scale = Column(Integer, comment="소수점")
    is_personal_info = Column(Boolean, default=False, comment="개인정보여부")
    is_encrypted = Column(Boolean, default=False, comment="암호화여부")
    scramble_type = Column(String(50), comment="스크램블유형")
    description = Column(Text, comment="설명")
    status = Column(String(20), default="active", comment="상태")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # 관계
    group = relationship("StdDomainGroup", back_populates="domains")
