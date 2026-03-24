from pydantic import BaseModel, Field
from typing import List
from datetime import datetime

class TaskItme(BaseModel):
    task_name: str = Field(..., description="任务名称")
    start_time: str = Field(..., description="开始时间，格式 YYYY-MM-DD HH:MM:SS")
    end_time: str = Field(..., description="结束时间，格式 YYYY-MM-DD HH:MM:SS")
    priority: str = Field(..., description="优先级: high, medium, low")
    reason: str = Field(..., description="排期原因")

class TaskResponse(BaseModel):
    id: int
    task_name: str
    start_time: datetime
    end_time: datetime
    priority: str
    reason: str
    status: str

    model_config = {"from_attributes": True}


class ScheduleResponse(BaseModel):
    tasks: List[TaskItme]

class ChatRequest(BaseModel):
    user_input: str

class TaskStatusUpdate(BaseModel):
    status: str