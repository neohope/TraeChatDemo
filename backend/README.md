# ChatApp 后端微服务架构

## 架构概述

ChatApp 后端采用微服务架构，由以下几个核心服务组成：

1. **用户服务 (User Service)**：负责用户管理、认证和授权
2. **消息服务 (Message Service)**：处理用户之间的消息传递和会话管理
3. **群组服务 (Group Service)**：管理群组创建、成员和权限
4. **媒体服务 (Media Service)**：处理图片、视频、音频等媒体文件的上传和管理
5. **通知服务 (Notification Service)**：处理实时通知和推送
6. **API网关 (API Gateway)**：统一入口，路由请求到相应的微服务

## 技术栈

- **编程语言**：Go
- **数据库**：PostgreSQL
- **缓存**：Redis
- **消息队列**：Kafka
- **认证**：JWT
- **API**：RESTful API、WebSocket、gRPC
- **容器化**：Docker、Docker Compose

## 目录结构

```
├── api-gateway/           # API网关服务
├── user-service/          # 用户服务
├── message-service/       # 消息服务
├── group-service/         # 群组服务
├── media-service/         # 媒体服务
├── notification-service/  # 通知服务
└── docker-compose.yml     # Docker Compose配置文件
```

## 服务端口

| 服务 | HTTP端口 | gRPC端口 |
|------|---------|----------|
| API网关 | 8080 | - |
| 用户服务 | 8081 | 9081 |
| 消息服务 | 8082 | 9082 |
| 群组服务 | 8083 | 9083 |
| 媒体服务 | 8084 | 9084 |
| 通知服务 | 8085 | 9085 |

## 快速开始

### 前提条件

- Docker 和 Docker Compose
- Go 1.19 或更高版本（本地开发）
- PostgreSQL（本地开发）
- Redis（本地开发）

### 使用Docker Compose启动所有服务

```bash
# 在backend目录下运行
docker-compose up -d
```

这将启动所有微服务以及PostgreSQL和Redis。

### 本地开发单个服务

每个服务目录下都有详细的README.md文件，包含了如何单独运行该服务的说明。

一般步骤如下：

1. 确保PostgreSQL和Redis已启动
2. 配置服务的`.env`文件
3. 运行服务：

```bash
# 例如，运行用户服务
cd user-service
go run cmd/main.go
```

## API文档

每个服务都提供了RESTful API，详细的API文档可以在各服务的`docs`目录下找到。

## 服务间通信

服务间通信主要通过以下方式：

1. **REST API**：适用于简单的请求-响应模式
2. **gRPC**：适用于高性能的服务间通信
3. **Kafka**：适用于异步事件驱动的通信

## 数据库设计

每个微服务都有自己的数据库模式，详细的数据库设计可以在各服务的`docs`目录下找到。

## 认证和授权

系统使用JWT（JSON Web Token）进行认证。用户登录后，用户服务生成JWT令牌，客户端在后续请求中使用该令牌进行认证。

## 部署

### 开发环境

使用Docker Compose在本地启动所有服务：

```bash
docker-compose up -d
```

### 生产环境

对于生产环境，建议使用Kubernetes进行部署。每个服务目录下都有Kubernetes配置文件示例。

## 监控和日志

所有服务都使用结构化日志（使用zap库），可以轻松集成到ELK或其他日志管理系统中。

## 贡献指南

1. Fork仓库
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

[MIT](LICENSE)