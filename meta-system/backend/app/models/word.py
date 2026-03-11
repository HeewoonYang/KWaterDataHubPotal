"""
표준 단어사전 ORM 모델
"""
from sqlalchemy import Column, Integer, String, Boolean, Text, DateTime, CheckConstraint
from sqlalchemy.sql import func

from app.database import Base


class StdWord(Base):
    """표준 단어사전"""
    __tablename__ = "std_word"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive','deprecated')", name="ck_std_word_status"),
        {"schema": "meta"},
    )

    word_id = Column(Integer, primary_key=True, autoincrement=True)
    logical_name = Column(String(200), nullable=False, unique=True, comment="논리명")
    physical_name = Column(String(100), nullable=False, unique=True, comment="물리명")
    physical_desc = Column(String(500), comment="물리의미")
    is_class_word = Column(Boolean, default=False, comment="속성분류어 여부")
    synonym = Column(String(500), comment="동의어")
    description = Column(Text, comment="설명")
    status = Column(String(20), default="active", comment="상태")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
