# API Gateway

API Gateway是聊天应用的统一入口点，负责路由请求到相应的微服务，并提供认证、授权、限流等功能。

## 功能特性

### 🔐 认证与授权
- JWT令牌验证
- 用户身份识别
- 请求头注入用户信息

### 🚦 流量管理
- 请求限流
- CORS支持
- 请求日志记录

### 🔄 服务代理
- 智能路由到后端服务
- 健康检查
- 负载均衡支持

### 📊 监控
- 服务健康状态监控
- 请求性能监控
- 错误日志记录

## 架构设计

```
客户端请求 → API Gateway → 后端微服务
     ↓
  [认证中间件]
     ↓
  [限流中间件]
     ↓
  [日志中间件]
     ↓
  [代理服务]
```

## 路由配置

### 公开端点（无需认证）
- `GET /health` - 健康检查
- `POST /api/v1/users/register` - 用户注册
- `POST /api/v1/users/login` - 用户登录

### 受保护端点（需要认证）
- `/api/v1/users/*` - 用户服务
- `/api/v1/groups/*` - 群组服务
- `/api/v1/messages/*` - 消息服务
- `/api/v1/media/*` - 媒体服务
- `/api/v1/notifications/*` - 通知服务
- `/api/v1/ws` - WebSocket连接

## 环境变量

```bash
# 服务配置
HTTP_PORT=8080
LOG_LEVEL=info

# JWT配置
JWT_SECRET_KEY=your-secret-key

# 后端服务地址
USER_SERVICE_URL=http://localhost:8081
GROUP_SERVICE_URL=http://localhost:8082
MESSAGE_SERVICE_URL=http://localhost:8083
MEDIA_SERVICE_URL=http://localhost:8084
NOTIFICATION_SERVICE_URL=http://localhost:8085

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_RPS=100
```

## 快速开始

### 本地开发

1. 安装依赖
```bash
go mod download
```

2. 设置环境变量
```bash
cp .env.example .env
# 编辑.env文件
```

3. 运行服务
```bash
go run cmd/main.go
```

### Docker部署

1. 构建镜像
```bash
docker build -t api-gateway .
```

2. 运行容器
```bash
docker run -p 8080:8080 \
  -e JWT_SECRET_KEY=your-secret-key \
  -e USER_SERVICE_URL=http://user-service:8081 \
  api-gateway
```

## API文档

### 健康检查

```http
GET /health
```

响应示例：
```json
{
  "status": "healthy",
  "services": {
    "users": true,
    "groups": true,
    "messages": true,
    "media": true,
    "notifications": true
  }
}
```

### 认证流程

1. 用户登录获取JWT令牌
2. 在请求头中携带令牌：`Authorization: Bearer <token>`
3. API Gateway验证令牌并转发请求
4. 后端服务通过请求头获取用户信息：`X-User-ID`, `X-User-Email`

## 中间件说明

### 认证中间件
- 验证JWT令牌
- 提取用户信息
- 注入用户上下文

### 限流中间件
- 基于IP地址限流
- 可配置请求频率
- 防止服务过载

### CORS中间件
- 支持跨域请求
- 可配置允许的域名
- 预检请求处理

### 日志中间件
- 记录所有请求
- 性能监控
- 错误追踪

## 监控与运维

### 健康检查
API Gateway会定期检查后端服务的健康状态，通过`/health`端点可以查看整体系统状态。

### 日志格式
```json
{
  "timestamp": "2025-07-01T10:00:00Z",
  "level": "info",
  "message": "HTTP Request",
  "method": "GET",
  "path": "/api/v1/users/profile",
  "remote_addr": "192.168.1.100",
  "duration": "50ms"
}
```

### 错误处理
- 400: 客户端请求错误
- 401: 未授权访问
- 404: 服务不存在
- 429: 请求频率超限
- 503: 后端服务不可用

## 性能优化

1. **连接池**：使用HTTP客户端连接池
2. **缓存**：JWT令牌验证结果缓存
3. **压缩**：响应内容压缩
4. **超时控制**：合理设置请求超时时间

## 安全考虑

1. **JWT安全**：使用强密钥，定期轮换
2. **HTTPS**：生产环境强制使用HTTPS
3. **限流**：防止DDoS攻击
4. **日志脱敏**：避免记录敏感信息

## 扩展功能

- [ ] 服务发现集成
- [ ] 负载均衡算法
- [ ] 熔断器模式
- [ ] 分布式追踪
- [ ] 指标收集
- [ ] 配置热更新