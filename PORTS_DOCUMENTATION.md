# TraeChatDemo 服务端口配置文档

## 概述

本文档详细记录了 TraeChatDemo 项目中所有服务的端口配置信息，包括前端、后端微服务、数据库等组件的端口分配。

## 端口分配表

### 前端服务

| 服务名称 | 端口 | 协议 | 说明 |
|---------|------|------|------|
| Flutter Web App | 动态分配 | HTTP | Flutter调试服务端口由系统自动分配 |
| Flutter DevTools | 9101 | HTTP | Flutter开发工具端口 |

### 后端微服务

| 服务名称 | 容器名称 | 内部端口 | 外部端口 | 协议 | 说明 |
|---------|----------|----------|----------|------|------|
| API网关 | chatapp-api-gateway | 8080 | 8080 | HTTP | 统一API入口，处理路由和CORS |
| 用户服务 | chatapp-user-service | 8081 | 8081 | HTTP | 用户注册、登录、认证 |
| 消息服务 | chatapp-message-service | 8082 | 8082 | HTTP/WebSocket | 即时消息处理 |
| 群组服务 | chatapp-group-service | 8083 | 8083 | HTTP | 群组管理 |
| 媒体服务 | chatapp-media-service | 8084 | 8084 | HTTP | 文件上传下载 |
| 通知服务 | chatapp-notification-service | 8085 | 8085 | HTTP | 推送通知 |

### 数据库服务

| 服务名称 | 容器名称 | 内部端口 | 外部端口 | 协议 | 说明 |
|---------|----------|----------|----------|------|------|
| PostgreSQL | chatapp-postgres | 5432 | 5432 | TCP | 主数据库 |
| Redis | chatapp-redis | 6379 | 6379 | TCP | 缓存和消息队列 |

## 网络架构

### 请求流向

```
前端 (Flutter) → API网关 (8080) → 各微服务 (8081-8085)
                     ↓
                数据库层 (PostgreSQL:5432, Redis:6379)
```

### CORS配置

**API网关CORS设置：**
- **允许的源**: `*` (所有域名)
- **允许的方法**: `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`
- **允许的头**: `Content-Type`, `Authorization`, `X-Requested-With`

## 端口使用规则

### 后端服务端口规则
- **8080**: API网关 - 统一入口
- **8081-8085**: 微服务端口，按服务类型递增
- **5432**: PostgreSQL 标准端口
- **6379**: Redis 标准端口

### 前端端口说明
- Flutter Web应用的调试端口由Flutter CLI自动分配
- 实际的Web应用通过浏览器访问，端口对用户透明
- 开发时可通过Flutter DevTools (端口9101) 进行调试

## 环境配置

### 前端配置 (app_config.yaml)
```yaml
api_base_url: "http://localhost:8080"  # 指向API网关
ws_base_url: "ws://localhost:8080/ws"   # WebSocket连接
```

### 后端配置 (docker-compose.yml)
```yaml
# 所有服务端口映射都是固定的
ports:
  - "8080:8080"  # API网关
  - "8081:8081"  # 用户服务
  - "8082:8082"  # 消息服务
  - "8083:8083"  # 群组服务
  - "8084:8084"  # 媒体服务
  - "8085:8085"  # 通知服务
  - "5432:5432"  # PostgreSQL
  - "6379:6379"  # Redis
```

## 跨域访问解决方案

### CORS 配置状态
✅ **已完全解决跨域访问问题**
✅ **前端API路径已修复**
✅ **最终验证**: 通过 - 所有API路径已统一为 `/api/v1/` 前缀

### CORS 实现详情
- **API网关配置**: 允许所有来源 (`*`)
- **允许的方法**: GET, POST, PUT, DELETE, OPTIONS
- **允许的头部**: Content-Type, Authorization, X-Requested-With
- **预检缓存**: 24小时 (86400秒)
- **响应头设置**:
  - `Access-Control-Allow-Origin: *`
  - `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
  - `Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With`
  - `Access-Control-Max-Age: 86400`

### CORS配置详情
1. **位置**: `/backend/api-gateway/config/config.go`
2. **配置**: 
   ```go
   CORS: CORSConfig{
       AllowedOrigins: []string{"*"},
       AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
       AllowedHeaders: []string{"Content-Type", "Authorization", "X-Requested-With"},
   }
   ```

### 测试验证
```bash
# 测试普通请求的CORS头
curl -v -H "Origin: http://localhost:3000" http://localhost:8080/api/v1/users/profile

# 测试预检请求
curl -v -X OPTIONS -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://localhost:8080/api/v1/users/login
```

### 网络架构
- 前端通过API网关统一访问后端服务
- 所有跨域请求都通过API网关处理
- 微服务之间通过Docker内部网络通信
- CORS中间件在API网关层统一处理

### 前端API配置
- 所有API请求都通过API网关 (http://localhost:8080)
- WebSocket连接也通过API网关 (ws://localhost:8080/ws)
- 避免直接访问微服务端口，确保统一的CORS处理

## 故障排除

### 常见端口问题
1. **端口被占用**: 使用 `lsof -i :端口号` 检查端口占用
2. **Docker端口映射失败**: 检查docker-compose.yml配置
3. **CORS错误**: 确认前端请求指向API网关而非直接访问微服务

### 检查命令
```bash
# 检查所有服务状态
docker-compose ps

# 检查端口占用
lsof -i :8080-8085

# 检查API网关日志
docker logs chatapp-api-gateway
```

## 安全考虑

### 生产环境建议
1. **CORS配置**: 生产环境应限制AllowedOrigins为具体域名
2. **端口暴露**: 只暴露API网关端口，微服务端口仅内网访问
3. **防火墙**: 配置防火墙规则限制外部访问

### 开发环境
- 当前配置适用于开发环境
- CORS设置为 `*` 便于开发调试
- 所有端口都暴露便于直接访问和调试

---

**最后更新**: 2025年1月
**维护者**: TraeChatDemo 开发团队