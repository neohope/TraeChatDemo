# ChatApp 快速启动指南

## 项目概述

ChatApp 是一个完整的聊天应用，包含后端微服务架构和 Flutter 前端。

### 技术栈
- **后端**: Go 微服务架构
- **前端**: Flutter (支持 iOS、Android、Web)
- **数据库**: PostgreSQL
- **缓存**: Redis
- **容器化**: Docker & Docker Compose

## 快速启动

### 前置要求

1. **Docker & Docker Compose**
   ```bash
   # 检查 Docker 版本
   docker --version
   docker-compose --version
   ```

2. **Go 1.19+** (用于本地开发)
   ```bash
   go version
   ```

3. **Flutter 3.0+** (用于前端开发)
   ```bash
   flutter --version
   ```

### 启动后端服务

1. **进入后端目录**
   ```bash
   cd backend
   ```

2. **启动所有服务**
   ```bash
   docker-compose up -d
   ```

3. **查看服务状态**
   ```bash
   docker-compose ps
   ```

4. **查看日志**
   ```bash
   # 查看所有服务日志
   docker-compose logs -f
   
   # 查看特定服务日志
   docker-compose logs -f api-gateway
   ```

### 服务端口说明

| 服务 | 端口 | 描述 |
|------|------|------|
| API Gateway | 8080 | 统一入口 |
| User Service | 8081 | 用户管理 |
| Message Service | 8082 | 消息处理 |
| Group Service | 8083 | 群组管理 |
| Media Service | 8084 | 媒体文件 |
| Notification Service | 8085 | 通知推送 |
| PostgreSQL | 5432 | 数据库 |
| Redis | 6379 | 缓存 |

### 启动前端应用

1. **进入前端目录**
   ```bash
   cd frontend
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   # Web 版本
   flutter run -d chrome
   
   # iOS 模拟器
   flutter run -d ios
   
   # Android 模拟器
   flutter run -d android
   ```

## 健康检查

### 后端服务健康检查

```bash
# API Gateway
curl http://localhost:8080/health

# 用户服务
curl http://localhost:8081/health

# 消息服务
curl http://localhost:8082/health

# 群组服务
curl http://localhost:8083/health

# 媒体服务
curl http://localhost:8084/health

# 通知服务
curl http://localhost:8085/health
```

### 数据库连接测试

```bash
# 连接 PostgreSQL
docker exec -it chatapp-postgres psql -U postgres -d chatapp

# 连接 Redis
docker exec -it chatapp-redis redis-cli
```

## 开发模式

### 本地开发后端服务

1. **启动基础设施**
   ```bash
   cd backend
   docker-compose up -d postgres redis
   ```

2. **设置环境变量**
   ```bash
   export DB_HOST=localhost
   export DB_PORT=5432
   export DB_USER=postgres
   export DB_PASSWORD=postgres
   export DB_NAME=chatapp
   export REDIS_ADDR=localhost:6379
   ```

3. **运行特定服务**
   ```bash
   # 用户服务
   cd user-service
   go run cmd/main.go
   
   # 消息服务
   cd message-service
   go run cmd/main.go
   
   # 其他服务类似...
   ```

### 前端开发

1. **热重载开发**
   ```bash
   cd frontend
   flutter run --hot
   ```

2. **构建发布版本**
   ```bash
   # Web
   flutter build web
   
   # Android APK
   flutter build apk
   
   # iOS
   flutter build ios
   ```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 查看端口占用
   lsof -i :8080
   
   # 停止所有服务
   docker-compose down
   ```

2. **数据库连接失败**
   ```bash
   # 重启数据库
   docker-compose restart postgres
   
   # 查看数据库日志
   docker-compose logs postgres
   ```

3. **服务启动失败**
   ```bash
   # 重新构建镜像
   docker-compose build --no-cache
   
   # 清理并重启
   docker-compose down -v
   docker-compose up -d
   ```

4. **前端依赖问题**
   ```bash
   # 清理缓存
   flutter clean
   flutter pub get
   
   # 重新生成代码
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### 日志查看

```bash
# 实时查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f user-service

# 查看最近的日志
docker-compose logs --tail=100 api-gateway
```

## API 文档

各微服务的详细 API 文档位于：
- [API Gateway](./backend/api-gateway/README.md)
- [User Service](./backend/user-service/README.md)
- [Message Service](./backend/message-service/README.md)
- [Group Service](./backend/group-service/README.md)
- [Media Service](./backend/media-service/README.md)
- [Notification Service](./backend/notification-service/README.md)

## 下一步

1. **配置环境变量**: 根据实际需求修改 `docker-compose.yml` 中的环境变量
2. **数据库迁移**: 运行数据库迁移脚本初始化表结构
3. **SSL 配置**: 为生产环境配置 HTTPS
4. **监控配置**: 添加 Prometheus + Grafana 监控
5. **CI/CD**: 配置自动化部署流水线

## 贡献

请参考 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解如何为项目贡献代码。

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](./LICENSE) 文件。