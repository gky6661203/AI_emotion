# 认证与用户系统 API 文档

本模块处理系统的用户注册、登录、匿名用户生成及鉴权逻辑。采用 JWT 双 Token（Access Token + Refresh Token）机制保障安全。

## 1. 发送验证码 (Mock)
- **POST** `/api/auth/send-code`
- **Body**: 
  - `account` (string): 邮箱或手机号
  - `type` (string): 'register', 'login', 'reset_password'
- **返回**: 成功状态。验证码通过日志模拟发送。

## 2. 注册
- **POST** `/api/auth/register`
- **Body**:
  - `account` (string): 邮箱或手机号
  - `password` (string): 至少8位，包含字母和数字
  - `code` (string): 收到的验证码
  - `nickname` (string, optional): 昵称
- **返回**: `201 Created`，包含新创建的用户信息。

## 3. 登录
- **POST** `/api/auth/login`
- **Body**:
  - `account` (string): 邮箱或手机号
  - `password` (string)
- **返回**: 包含用户信息及 `token` (Access Token) 和 `refreshToken`。
- **安全机制**: 连续失败 5 次将锁定账号 30 分钟。

## 4. 第三方登录
- **POST** `/api/auth/login/third-party`
- **Body**:
  - `provider` (string): 'wechat', 'qq', 'weibo'
  - `provider_id` (string): 第三方唯一标识
  - `provider_data` (object, optional): 第三方用户资料（如 nickname）
- **返回**: 如果是新用户将自动注册。返回 Access Token 和 Refresh Token。

## 5. 匿名用户生成
- **POST** `/api/auth/anonymous`
- **Body**:
  - `campus` (string, optional): 校区
  - `enrollment_year` (number, optional): 入学年份
- **返回**: 随机分配昵称的匿名用户及 Tokens，角色标记为 `anonymous`。

## 6. 刷新 Token
- **POST** `/api/auth/refresh`
- **Body**:
  - `refreshToken` (string)
- **返回**: 新的 `token` 和 `refreshToken`。旧的 Refresh Token 将被立即使效（防重放攻击）。

## 7. 获取当前用户信息
- **GET** `/api/auth/me`
- **Headers**: `Authorization: Bearer <AccessToken>`
- **返回**: 当前用户资料（邮箱、手机号等敏感信息会进行脱敏处理，如 `138****1234`）。

## 8. 登出
- **POST** `/api/auth/logout`
- **Headers**: `Authorization: Bearer <AccessToken>`
- **Body**: `refreshToken` (string)
- **返回**: 将 Refresh Token 标记为无效。