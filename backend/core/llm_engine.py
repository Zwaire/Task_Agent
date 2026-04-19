import os
import json
from dotenv import load_dotenv
from core.prompts import get_scheduler_system_prompt
from typing import Any
from openai import OpenAI

load_dotenv()

# 👇 核心修改 1：初始化 OpenAI 客户端，并将其基准地址指向阿里云百炼的兼容接口
client = OpenAI(
    api_key=os.getenv("DASHSCOPE_API_KEY"),
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
)

def parse_user_intent_to_schedule(user_input: str) -> dict:
    '''
    调用Qwen模型，将用户的自然语言解析成 JSON 格式的数据
    '''
    system_prompt = get_scheduler_system_prompt()

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_input}
    ]

    try:
        # 👇 核心修改 2：使用标准 openai 格式调用大模型，无视本地 SDK 路由校验
        completion = client.chat.completions.create(
            model='qwen3.5-flash',
            messages=messages,
            # OpenAI 兼容模式不需要显式指定 result_format='message'
        )
        
        # 👇 核心修改 3：按 OpenAI 的标准数据结构提取文本
        reply_content = completion.choices[0].message.content

        # 原本的 JSON 字符串清洗和提取逻辑保持不变
        reply_content = reply_content.strip()
        if reply_content.startswith("```json"):
            reply_content = reply_content[7:]
        if reply_content.endswith("```"):
            reply_content = reply_content[:-3]

        schedule_data = json.loads(reply_content.strip())
        return schedule_data

    except json.JSONDecodeError:
        print("Error: 模型返回的内容无法解析为 JSON。")
        # 此时如果解析失败，将大模型返回的原始字符串打印出来方便排错
        print(reply_content) 
        return {}
    except Exception as e:
        # OpenAI 的错误类会自动抛出包含状态码和原因的异常
        print(f"调用发生未知错误: {e}")
        return {}

if __name__ == "__main__":
    test_input = """我明天上午满课，下午2点有个会要开大概一小时。
    明天晚上我得抽空把之前那个软体机器人的代码模块分析报告写一下，估计得花两个小时。
    哦对了，后天早上我还得去一趟教务处交个情况说明的材料，越早越好。
    帮我把这些事情安排一下吧。
    """

    print(f"用户输入：{test_input}\n")
    result = parse_user_intent_to_schedule(test_input)

    if result:
        print("解析结果：")
        print(json.dumps(result, indent=4, ensure_ascii=False))