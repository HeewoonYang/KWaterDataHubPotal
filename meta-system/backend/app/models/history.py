"""
변경이력 ORM 모델
"""
from sqlalchemy import Column, BigInteger, Integer, String, Text, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func

from app.database import Base


class StdChangeHistory(Base):
    """표준사전 변경이력"""
    __tablename__ = "std_change_history"
    __table_args__ = (
        CheckConstraint(
            "dict_type IN ('word','domain_group','domain','term','code_group','code')",
            name="ck_history_dict_type"
        ),
        CheckConstraint(
            "action IN ('create','update','delete','import')",
            name="ck_history_action"
        ),
        {"schema": "meta"},
    )

    history_id = Column(BigInteger, primary_key=True, autoincrement=True)
    dict_type = Column(String(20), nullable=False, comment="사전종류")
    record_id = Column(Integer, nullable=False, comment="대상레코드PK")
    action = Column(String(10), nullable=False, comment="변경유형")
    change_desc = Column(Text, comment="변경설명")
    prev_value = Column(JSONB, comment="변경전값")
    new_value = Column(JSONB, comment="변경후값")
    changed_by = Column(String(100), comment="변경자")
    changed_at = Column(DateTime(timezone=True), server_default=func.now())
