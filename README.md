# Task Agent (智能日程 Agent)

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=flat-square&logo=flutter)
![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?style=flat-square&logo=fastapi)
![Python](https://img.shields.io/badge/Language-Python_3.8+-blue?style=flat-square&logo=python)
![LLM](https://img.shields.io/badge/LLM-Qwen_(通义千问)-orange?style=flat-square)

一个基于大语言模型（LLM）驱动的跨端智能日程规划助手。

来源是作者觉得现在的TODO工具要自己一个个进行安排内容，非常麻烦且容易遗忘。原本是想要嵌入到 wechat 中但是由于技术有限无法实现QAQ

主要功能是配置了一个 API，直接用文字输入任务安排（一般是语音转文字），之后就能够生成任务编排进行通知。


## ✨ 核心特性

- **功能**：接入阿里云 DashScope (Qwen) 大模型，精准解析非结构化长文本，自动推导相对时间与任务时长。
- **跨端**：使用 Flutter 构建，支持 Android/Windows。提供直观的周视图日历与任务列表交互（打勾完成、左滑删除）。
- **后端**：基于 FastAPI 构建全异步 RESTful API，SQLAlchemy + SQLite 提供可靠的本地持久化记忆。

## 🏗️ 架构设计

项目采用前后端分离架构，分为 `frontend` 和 `backend` 两个主要模块：

* **大脑中枢 (Backend)**：接收自然语言输入，注入当前系统时间等 Context 构建 Prompt，调用 Qwen 模型输出严格的 JSON 排期格式，落库后返回给客户端。
* **交互躯干 (Frontend)**：负责数据可视化（日历/列表）与状态管理。并在本地计算提前量，向手机操作系统注册底层的定时闹钟（AlarmManager）以实现系统级消息推送。

## 🚀 快速上手 (Getting Started)

### 1. 环境准备
- 确保已安装 [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.19+ 推荐)。
- 确保已安装 Python 3.8+ 环境。
- 申请阿里云 [DashScope API Key](https://dashscope.console.aliyun.com/)。

### 2. 启动后端服务 (FastAPI)

```bash
# 1. 进入后端目录
cd backend

# 2. 安装 Python 依赖包
pip install -r requirements.txt

# 3. 配置环境变量
# 在 backend/ 目录下创建 .env 文件，并填入你的 API Key：
# DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxx

# 4. 启动服务 (默认运行在 [http://127.0.0.1:8000](http://127.0.0.1:8000))
# 若需局域网手机调试，请使用 --host 0.0.0.0
uvicorn main:app --reload
```
启动后，可访问 http://127.0.0.1:8000/docs 查看并测试自动生成的 Swagger API 接口文档。

### 3. 运行前端应用 (Flutter)
```
# 1. 进入前端目录
cd frontend

# 2. 获取依赖
flutter pub get

# 3. 配置后端地址
# ⚠️ 注意：请打开 `lib/screens/home_screen.dart`，
# 将 `backendUrl` 修改为你电脑真实的局域网 IP (例如 [http://192.168.1.100:8000](http://192.168.1.100:8000))

# 4. 运行应用 (连接手机或模拟器)
flutter run
```

### 4. 构建生产版本 (Android APK)
```
cd frontend
flutter build apk --release
# 生成的安装包位于: build/app/outputs/flutter-apk/app-release.apk
```

注：对于 Android 13+ 设备，初次安装打开后请务必同意“通知”与“精确闹钟”权限，并在系统设置中允许后台活动，以确保定时提醒准时触发。