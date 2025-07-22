# TraeChatDemo 聊天应用

## 项目概述

TraeChatDemo 是一个现代化的聊天应用，采用微服务架构设计，前端使用 Flutter 开发跨平台客户端，后端使用 Go 语言开发多个微服务。该应用支持即时消息、群组聊天、媒体分享和用户管理等功能。

## 系统架构

### 前端 (Flutter)

前端采用 Flutter 框架开发，实现了跨平台（iOS、Android、Web）的统一用户体验。

- **目录结构**:
  - `assets/`: 存放字体、图片等静态资源
  - `lib/`: 主要代码目录
    - `core/`: 核心功能和工具
    - `data/`: 数据层，包括API客户端和本地存储
    - `domain/`: 领域层，包括实体模型和业务逻辑
    - `presentation/`: 表现层，包括UI组件和页面
    - `utils/`: 工具类
  - `l10n.yaml`: 国际化配置

### 后端 (Go微服务)

后端采用微服务架构，使用 Go 语言开发，各服务之间通过 API 网关进行通信。

- **服务组件**:
  - `api-gateway/`: API网关，负责请求路由和服务发现
  - `user-service/`: 用户服务，处理用户注册、登录和个人资料管理
  - `message-service/`: 消息服务，处理即时消息的发送和接收
  - `group-service/`: 群组服务，管理群组创建和成员管理
  - `media-service/`: 媒体服务，处理图片、视频等媒体文件的上传和分享
  - `notification-service/`: 通知服务，管理推送通知

## 功能特点

- 实时消息传递
- 群组聊天
- 多媒体消息支持（图片、视频、文件）
- 用户认证和授权
- 消息历史记录和搜索
- 推送通知
- 跨平台支持

## 最新更新

### 2024年最新修复和改进

- **代码质量优化**: 修复了 Go 语言中的变量重复声明问题
  - 修复 `group-service/internal/handler/group_handler.go` 中多个函数的 `err` 变量重复声明
  - 修复 `media-service/internal/service/media_service.go` 中 `UploadFile` 函数的 `err` 变量重复声明
- **WebSocket 功能完善**: 增强了实时消息传递能力
  - 完善 `message-service` 的 WebSocket 连接管理
  - 添加客户端管理器和消息路由功能
  - 实现内存存储作为数据库备选方案
- **前端功能增强**: 优化用户体验
  - 改进 WebSocket 连接和消息处理逻辑
  - 添加本地存储功能
  - 完善消息视图模型和状态管理
- **项目结构优化**: 完善微服务架构
  - 更新依赖管理和配置文件
  - 统一代码风格和错误处理

## 技术栈

### 前端
- Flutter/Dart
- Provider/Bloc (状态管理)
- Dio (网络请求)
- WebSocket (实时通信)
- Hive/SharedPreferences (本地存储)

### 后端
- Go
- gRPC (服务间通信)
- RESTful API
- PostgreSQL (主数据库)
- Redis (缓存和消息队列)
- Docker (容器化)

## 开发环境设置

### 前端

1. 安装 Flutter SDK
2. 克隆仓库
3. 安装依赖：
   ```
   cd frontend
   flutter pub get
   ```
4. 运行应用：
   ```
   flutter run
   ```

### 后端

1. 安装 Go
2. 安装 Docker 和 Docker Compose
3. 启动服务：
   ```
   cd backend
   docker-compose up -d
   ```

## API文档

各微服务的API文档位于各自的 `docs` 目录下。

## 贡献指南

1. Fork 仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 LICENSE 文件