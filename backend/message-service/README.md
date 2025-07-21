# 消息服务 (Message Service)

消息服务是聊天应用的核心微服务之一，负责处理用户之间的消息传递和会话管理。

## 功能

- 发送和接收消息
- 创建和管理会话（私聊和群聊）
- 消息状态管理（已发送、已送达、已读）
- 支持多种消息类型（文本、图片、视频、音频、文件等）

## 技术栈

- Go
- PostgreSQL
- JWT认证
- RESTful API

## 目录结构

```
├── api/            # API定义
├── cmd/            # 应用入口
├── config/         # 配置管理
├── docs/           # 文档
├── internal/       # 内部代码
│   ├── delivery/   # 处理HTTP请求
│   ├── domain/     # 领域模型和接口
│   ├── repository/ # 数据访问层
│   └── service/    # 业务逻辑层
├── pkg/            # 公共包
│   ├── auth/       # 认证工具
│   ├── logger/     # 日志工具
│   └── utils/      # 通用工具
└── test/           # 测试
```

## 环境变量

服务通过`.env`文件或环境变量进行配置：

```
# 服务配置
HTTP_PORT=8082
GRPC_PORT=9082
LOG_LEVEL=debug

# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=chatapp
DB_SSLMODE=disable

# JWT配置
JWT_SECRET_KEY=your_super_secret_key_change_in_production
JWT_EXPIRATION_HOURS=24

# Kafka配置
KAFKA_BROKER=localhost:9092
KAFKA_TOPIC=messages

# Redis配置
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# 微服务端点配置
USER_SVC_HOST=localhost
USER_SVC_PORT=8081
GROUP_SVC_HOST=localhost
GROUP_SVC_PORT=8083
MEDIA_SVC_HOST=localhost
MEDIA_SVC_PORT=8084
NOTIFY_SVC_HOST=localhost
NOTIFY_SVC_PORT=8085
```

## 运行服务

### 本地运行

1. 确保PostgreSQL数据库已启动并创建了相应的数据库
2. 配置`.env`文件
3. 运行服务：

```bash
go run cmd/main.go
```

### 使用Docker

```bash
# 构建镜像
docker build -t chatapp/message-service .

# 运行容器
docker run -p 8082:8082 --name message-service chatapp/message-service
```

## API端点

### 公共API

- `GET /health` - 健康检查

### 需要认证的API

#### 消息相关

- `POST /api/v1/messages` - 发送消息
- `GET /api/v1/messages/{id}` - 获取消息
- `PUT /api/v1/messages/{id}/status` - 更新消息状态
- `GET /api/v1/conversations/{id}/messages` - 获取会话消息

#### 会话相关

- `POST /api/v1/conversations` - 创建会话
- `GET /api/v1/conversations` - 获取用户会话列表
- `GET /api/v1/conversations/{id}` - 获取会话详情

## 认证

所有需要认证的API都需要在请求头中包含有效的JWT令牌：

```
Authorization: Bearer {token}
```