from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Any

from models import schemas, models
from core.database import engine, get_db
from core.llm_engine import parse_user_intent_to_schedule

models.Base.metadata.create_all(bind=engine)
app = FastAPI(title="Smart Schedule Agent API", version="1.0")

@app.post("/api/chat", response_model=schemas.ScheduleResponse)
async def chat_with_agent(request: schemas.ChatRequest, db: Session = Depends(get_db)):
    """
    接收用户输入 -> 大模型解析 -> 存入数据库 -> 返回结果
    """
    # 用户数据接受并传输给大模型进行解析
    user_text = request.user_input
    
    schedule_data = parse_user_intent_to_schedule(user_text)
    
    if not schedule_data or "tasks" not in schedule_data:
        raise HTTPException(status_code=500, detail="模型解析失败，请重试")
    
    # 将解析出的数据遍历存入数据库
    saved_tasks = []
    for task_data in schedule_data["tasks"]:
        start_dt = datetime.strptime(task_data["start_time"], "%Y-%m-%d %H:%M:%S")
        end_dt = datetime.strptime(task_data["end_time"], "%Y-%m-%d %H:%M:%S")
        
        db_task = models.Task(
            task_name=task_data["task_name"],
            start_time=start_dt,
            end_time=end_dt,
            priority=task_data["priority"],
            reason=task_data["reason"]
        )
        db.add(db_task)
        saved_tasks.append(task_data)
        
    db.commit()
    
    return {"tasks": saved_tasks}

@app.get("/api/schedule", response_model=List[schemas.TaskResponse])
async def get_schedule(db: Session = Depends(get_db)):
    """
    获取所有日程列表，按开始时间升序排列 (App 端打开日历时调用)
    """
    tasks = db.query(models.Task).order_by(models.Task.start_time.asc()).all()
    return tasks

@app.put("/api/schedule/{task_id}/status", response_model=schemas.TaskResponse)
async def update_task_status(task_id: int, status_update: schemas.TaskStatusUpdate, db: Session = Depends(get_db)):
    """
    更新某个日程的状态 (App 端点击“完成”打勾时调用)
    """
    db_task: Any = db.query(models.Task).filter(models.Task.id == task_id).first()
    
    if not db_task:
        raise HTTPException(status_code=404, detail="未找到该日程")

    db_task.status = status_update.status
    db.commit()
    db.refresh(db_task)
    return db_task

@app.delete("/api/schedule/{task_id}")
async def delete_task(task_id: int, db: Session = Depends(get_db)):
    """
    删除某个日程 (App 端左滑删除时调用)
    """
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    
    if not db_task:
        raise HTTPException(status_code=404, detail="未找到该日程")
        
    db.delete(db_task)
    db.commit()
    return {"message": "日程已成功删除"}

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Smart Schedule Agent API is running"}

