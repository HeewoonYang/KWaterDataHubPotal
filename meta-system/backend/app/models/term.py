"""
표준 용어사전 ORM 모델
"""
from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class StdTerm(Base):
    """표준 용어사전"""
    __tablename__ = "std_term"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive','deprecated')", name="ck_std_term_status"),
        {"schema": "meta"},
    )

    term_id = Column(Integer, primary_key=True, autoincrement=True)
    logical_name = Column(String(300), nullable=False, comment="논리명")
    physical_name = Column(String(200), nullable=False, unique=True, comment="물리명")
    english_name = Column(String(500), comment="영문의미")
    domain_logical_name = Column(String(200), comment="도메인논리명")
    domain_id = Column(Integer, ForeignKey("meta.std_domain.domain_id"), comment="도메인 FK")
    domain_abbr = Column(String(100), comment="도메인논리약어")
    domain_group_id = Column(Integer, ForeignKey("meta.std_domain_group.group_id"), comment="도메인그룹 FK")
    data_type = Column(String(30), comment="데이터유형")
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
    domain = relationship("StdDomain", lazy="selectin")
    domain_group = relationship("StdDomainGroup", lazy="selectin")
