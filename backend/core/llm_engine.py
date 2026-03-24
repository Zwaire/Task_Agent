import os
import json
import dashscope
from dotenv import load_dotenv
from core.prompts import get_scheduler_system_prompt

load_dotenv()
dashscope.api_key = os.getenv("DASH_SCOPE_API_KEY")

def parse_user_intent_to_schedule(user_input: str) -> dict:


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