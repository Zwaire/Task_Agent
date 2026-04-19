import os
import json
import dashscope
from dotenv import load_dotenv
from core.prompts import get_scheduler_system_prompt
from typing import Any

load_dotenv()
dashscope.api_key = os.getenv("DASHSCOPE_API_KEY")

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
        response: Any = dashscope.Generation.call(
            model='qwen3.5-flash',
            messages=messages,
            result_format='message'
        )
        
        if response.status_code  == 200:
            reply_content = response.output.choices[0].message.content

            reply_content = reply_content.strip()
            if reply_content.startswith("```json"):
                reply_content = reply_content[7:]
            if reply_content.endswith("```"):
                reply_content = reply_content[:-3]

            schedule_data = json.loads(reply_content.strip())
            return schedule_data
        else :
            print(f"API 调用失败，状态码: {response.status_code}")
            return {}

    except json.JSONDecodeError:
        print("Error: 模型返回的内容无法解析为 JSON。")
        print(reply_content)
        return {}
    except Exception as e:
        print(f"发生未知错误: {e}")
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