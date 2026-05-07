# AI 情绪感知的校园树洞与匿名搭子匹配系统

> 面向 OpenHarmony 6.0+ 的校园 AI 情绪陪伴、私密树洞、匿名搭子匹配与多设备协同系统。系统通过文本、语音、私密信件、手写信等多模态表达入口，识别学生情绪与需求，构建用户状态画像，并以智能推荐、匿名匹配、安全兜底和跨设备联动形成完整的校园心理陪伴生态。

## 一、项目定位

本项目定位为一个可上线、可参赛冲奖、前后端完整、AI 能力完整、多设备真实协同的校园心理陪伴与匿名轻社交系统。

## 二、系统一句话总结

本系统是一个基于多模态情绪感知、用户状态建模、隐私优先表达、匿名安全匹配和 OpenHarmony 多设备协同的校园 AI 心理陪伴生态系统。

## 三、核心链路

```text
用户表达情绪或需求
        ↓
AI 多模态情绪与意图识别
        ↓
用户心理状态画像更新
        ↓
分级推荐与安全决策
        ↓
私密陪伴 / 匿名搭子 / 放松内容 / 学习资源 / 心理资源
        ↓
多设备同步与长期成长记录
```

## 四、当前工程状态

当前已实现后端和 AI Engine 的第一阶段主链路：

```text
Core API
  ├─ 匿名用户
  ├─ 设备绑定
  ├─ 聊天消息
  ├─ 私密树洞
  ├─ 语音记录
  ├─ 情绪记录
  ├─ 状态画像
  ├─ 当前推荐
  └─ 情绪报告

AI Engine
  ├─ LLM Provider: rules / openai_compatible
  ├─ ASR Provider: placeholder
  ├─ Safety Provider: rules
  ├─ Prompt 模板
  └─ LLM 响应清洗
```

## 五、技术栈

- OpenHarmony 6.0+ / ArkTS / ArkUI
- Rust / Axum / Tokio / SQLx
- Python / FastAPI
- PostgreSQL / Redis / MinIO
- Docker Compose

## 六、项目目录结构

```text
race_emotion/
├── apps/
│   ├── openharmony/          # ArkUI / ArkTS 客户端
│   └── admin-web/            # 管理后台，后期建设
├── services/
│   ├── core-api/             # Rust 业务后端
│   └── ai-engine/            # Python AI 服务
├── infra/
│   ├── docker/               # Docker Compose 与服务编排
│   └── sql/                  # 数据库初始化脚本
├── docs/
│   ├── api/                  # API 文档
│   ├── architecture/         # 架构设计
│   ├── database/             # 数据库设计
│   ├── product/              # 产品文档
│   └── competition/          # 比赛答辩材料
├── scripts/                  # 开发与验证脚本
└── README.md
```

## 七、本地联调与 Smoke Test

### 启动基础设施

```powershell
.\scripts\dev.ps1 -Service infra
```

### 初始化数据库

```powershell
.\scripts\dev.ps1 -Service migrate
```

该命令会通过 Docker Compose 中的 PostgreSQL 容器执行：

```text
infra/sql/001_init_core_tables.sql
```

也可以直接运行：

```powershell
.\scripts\db_init.ps1
```

### 启动 AI Engine

```powershell
.\scripts\dev.ps1 -Service ai-engine
```

### 启动 Core API

```powershell
.\scripts\dev.ps1 -Service core-api
```

### 执行 Smoke Test

```powershell
.\scripts\dev.ps1 -Service smoke
```

或直接运行：

```powershell
.\scripts\smoke_test.ps1
```

也可以指定服务地址：

```powershell
.\scripts\smoke_test.ps1 -CoreApiUrl "http://localhost:8080" -AiEngineUrl "http://localhost:8090"
```

### 一键检查

在基础设施、Core API 和 AI Engine 已启动的情况下，可以执行：

```powershell
.\scripts\dev.ps1 -Service check
```

该命令会先执行数据库初始化，再运行 smoke test。

### Smoke Test 覆盖范围

- Core API 健康检查
- AI Engine 健康检查
- 创建匿名用户
- 绑定设备
- 发送聊天消息
- 创建私密树洞
- 创建语音记录
- 语音转写
- 语音分析
- 查询当前推荐
- 查询情绪报告

Python 版本也可直接运行：

```powershell
py .\scripts\smoke_test.py
```

可用环境变量：

```text
CORE_API_URL=http://localhost:8080
AI_ENGINE_URL=http://localhost:8090
SMOKE_TEST_TIMEOUT_SECONDS=10
```

## 八、核心数据表

```text
users
devices
chat_messages
emotion_records
user_state_vectors
private_letters
voice_records
risk_events
```

### 私密树洞表

```text
private_letters
├── id
├── user_id
├── title
├── content
├── content_type
├── allow_ai_analysis
├── ai_summary
├── keywords
├── emotion
├── emotion_intensity
├── write_to_emotion_profile
├── affect_recommendation
├── affect_matching
├── open_at
├── created_at
└── deleted_at
```

### 语音记录表

```text
voice_records
├── id
├── user_id
├── file_url
├── duration_seconds
├── transcript
├── emotion
├── emotion_intensity
├── voice_features
├── ai_summary
├── keywords
├── risk_level
├── allow_ai_analysis
├── write_to_emotion_profile
├── created_at
└── deleted_at
```

## 九、当前 API

详见：`docs/api/README.md`

当前主要接口：

```text
GET  /health
POST /api/auth/anonymous
POST /api/devices/bind
GET  /api/devices
POST /api/chat/messages
POST /api/private-letters
POST /api/voice-records
POST /api/voice-records/:id/transcribe
POST /api/voice-records/:id/analyze
GET  /api/recommendations/current
GET  /api/emotions/report
WS   /ws/devices/sync
```

## 十、后续开发路线

1. 匿名搭子候选池与匹配评分
2. 临时房间与共同专注 WebSocket
3. 真实 MinIO 文件上传
4. 真实 ASR Provider 接入
5. OpenHarmony ArkTS 客户端
6. 多设备真实状态广播
7. 管理后台与安全运营

## 十一、安全边界

系统定位为校园情绪陪伴和轻量支持工具，不替代专业心理咨询或医疗诊断。

```text
陪伴而不诊断
引导而不治疗
提示而不强制
安全优先于推荐
```
