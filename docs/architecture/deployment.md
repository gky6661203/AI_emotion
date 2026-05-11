# 系统部署指南

本系统包括四个核心部分：PostgreSQL 数据库、Node.js (TS) 业务后端、Python AI 引擎、以及基于 ArkUI 的鸿蒙前端应用。

## 1. 基础设施部署 (Docker)

数据库等基础服务推荐使用 Docker Compose 部署。

```bash
cd infra/docker
docker-compose up -d postgres
```
初始化脚本会自动执行 `infra/sql/` 目录下的所有迁移文件（包含 `001` 和 `002`），确保包含完整的认证表结构（验证码、第三方登录、Token表等）。

## 2. 后端服务部署 (Node.js)

### 环境要求
- Node.js >= 18
- npm >= 9

### 配置与启动
1. 复制 `.env.example` 到 `.env`，设置以下核心环境变量：
   ```env
   DATABASE_URL=postgres://postgres:password@localhost:5432/aiemotion
   JWT_SECRET=your_super_secret_key_here
   REFRESH_SECRET=your_super_refresh_secret_key_here
   ```
2. 安装依赖并构建：
   ```bash
   cd services/ts-api
   npm install
   npm run build
   ```
3. 生产环境启动（推荐使用 PM2）：
   ```bash
   pm2 start dist/index.js --name "ai-emotion-api"
   ```

## 3. Python AI 引擎部署

### 环境要求
- Python >= 3.10

### 配置与启动
1. 创建虚拟环境并安装依赖：
   ```bash
   cd services/ai-engine
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
2. 启动服务（生产环境建议使用 Gunicorn + Uvicorn）：
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8090 --workers 4
   ```

## 4. 鸿蒙客户端打包 (DevEco Studio)

1. 在 DevEco Studio 中打开 `entry` 目录。
2. 配置应用签名（Build -> Generate Key and CSR）。
3. 确认 `entry/src/main/ets/services/ApiService.ets` 中的 `BASE_URL` 指向生产服务器地址。
4. 构建 HAP/APP 包（Build -> Build Hap(s)/APP(s) -> Build APP）。