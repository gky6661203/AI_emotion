# 运维与监控手册

## 1. 监控指标

在日常运维中，建议重点监控以下指标：
- **数据库连接数**：由于 Node.js 和 Python 都会连接 PostgreSQL，确保 `max_connections` 分配充足。
- **登录失败率**：监控 `login_failures` 的突增，这可能意味着针对系统的暴力破解攻击。
- **AI 引擎延迟**：Python 端的情绪提取和风险评估会直接影响消息流的响应时间，建议 P99 延迟控制在 1500ms 内。

## 2. 数据库维护与备份

### 定时备份
使用 `pg_dump` 设置每日定时备份：
```bash
0 2 * * * pg_dump -U postgres aiemotion > /backup/aiemotion_$(date +\%Y\%m\%d).sql
```

### 清理过期数据
系统中存在一些生命周期较短的表（例如 `verification_codes` 和过期的 `refresh_tokens`）。可以设置定时任务清理以节约存储：
```sql
DELETE FROM verification_codes WHERE expires_at < NOW() - INTERVAL '7 days';
DELETE FROM refresh_tokens WHERE expires_at < NOW() - INTERVAL '30 days';
```

## 3. 安全策略说明

1. **防暴力破解**：Node.js 后端已经内置了 `MAX_LOGIN_FAILURES` 控制，当失败达到 5 次时，账户会自动锁定 30 分钟。
2. **Refresh Token 轮换**：每次通过 `refresh` 接口获取新 Token 时，旧的 Refresh Token 都会被标记为 `revoked = true`，以防止重放攻击。
3. **数据隔离与脱敏**：
   - 接口层面：获取用户信息接口 `/api/auth/me` 已经对 `phone` 和 `email` 字段进行了打码脱敏（如 `138****1234`）。
   - 数据库层面：所有的密码均采用 `pbkdf2` 强散列算法配合独立 `salt` 进行加密存储。
   - 权限隔离：对于带有 `is_anonymous = true` 的用户，系统为其分配了专属的 `anonymous` 角色（Role）。对于特定路由可以使用 `requireRole('user')` 等中间件阻断匿名用户的访问。