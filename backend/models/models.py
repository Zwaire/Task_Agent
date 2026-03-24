# backend/models/models.py
from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from core.database import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    task_name = Column(String, index=True, nullable=False)
    
    # 存储为 datetime 对象，方便后续按时间查询和排序
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    
    priority = Column(String, nullable=False)
    reason = Column(String)
    
    status = Column(String, default="pending")  # pending: 待办, completed: 已完成
    
    created_at = Column(DateTime, default=datetime.now)