from pydantic import BaseModel, Field
from typing import List

class TaskItme(BaseModel):
    task_name: str = Field(..., description="任务名称")
    start_time: str = Field(..., description="开始时间，格式 YYYY-MM-DD HH:MM:SS")
    end_time: str = Field(..., description="结束时间，格式 YYYY-MM-DD HH:MM:SS")
    priority: str = Field(..., description="优先级: high, medium, low")
    reason: str = Field(..., description="排期原因")

class ScheduleResponse(BaseModel):
    tasks: List[TaskItme]

class ChatRequest(BaseModel):
    user_input: str