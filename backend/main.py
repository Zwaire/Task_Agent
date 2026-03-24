from fastapi import FastAPI, HTTPException 
from models.schemas import ChatRequest, ScheduleResponse
from core.llm_engine import parse_user_intent_to_schedule

app = FastAPI(title="Smart Schedule Agent API", version="1.0")

@app.post("/api/chat", response_model=ScheduleResponse)
async def chat_with_agent(request: ChatRequest):
    '''
    接受用户的自然语言输入，调用 Qwen 模型生成日期排期
    '''
    user_text = request.user_input

    schedule_data = parse_user_intent_to_schedule(user_text)

    if not schedule_data:
        raise HTTPException(status_code=400, detail="无法生成排期，请检查输入内容")
    
    return schedule_data

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Smart Schedule Agent API is running"}