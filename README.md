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
- 用户搜索和好友查找
- 消息历史记录和搜索
- 推送通知
- 跨平台支持

## 最新更新

### 最新修复和改进

#### 🔍 用户搜索功能完善
- **好友查找服务**: 完整实现用户搜索和好友发现功能
  - 完善 `user-service` 的 `SearchUsers` API，支持按用户名、全名、邮箱进行智能搜索
  - 实现数据库层面的模糊匹配和精确匹配优先排序
  - 支持分页查询（limit/offset参数）和多种查询参数格式（q/keyword）
  - 修复SA1029静态分析警告，使用自定义类型替代字符串作为context键
  - 只返回活跃用户，自动过滤敏感信息

#### 🛠️ 数据解析稳定性修复
- **Null值处理优化**: 彻底解决前端数据解析错误
  - 修复 `Conversation.fromJson` 方法中 `id` 和 `title` 字段的null值处理
  - 修复 `Message.fromJson` 方法中 `id`、`senderId` 和 `content` 字段的null值处理
  - 修复 `User.fromJson` 方法中 `id`、`username`、`displayName` 和 `email` 字段的null值处理
  - 修复 `ConversationModel.fromJson` 方法中 `id`、`name` 和 `lastMessageTime` 字段的null值处理
  - 解决 `TypeError: null: type 'Null' is not a subtype of type 'String'` 错误
  - 为所有必需的字符串字段添加空值保护（`?? ''`）
  - 为DateTime字段添加null值检查和默认值处理

#### 🔧 代码质量优化
- **Go语言修复**: 修复了变量重复声明问题
  - 修复 `group-service/internal/handler/group_handler.go` 中多个函数的 `err` 变量重复声明
  - 修复 `media-service/internal/service/media_service.go` 中 `UploadFile` 函数的 `err` 变量重复声明

#### 🐛 字符串访问安全性修复
- **RangeError修复**: 彻底解决前端字符串访问越界问题
  - 修复 `search_page.dart` 中 `_getAvatarText` 方法的空字符串访问问题
  - 修复 `chat_list_widget.dart` 中 `_getAvatarText` 方法的空字符串访问问题
  - 为所有字符串 `substring` 操作添加非空检查
  - 使用 `isNotEmpty` 条件判断避免 `RangeError (end): Invalid value: Only valid value is 0: 1`
  - 为空字符串情况提供默认头像文本 `'?'`

#### 🌐 跨域访问完全解决
- **CORS配置优化**: 彻底解决前端跨域访问问题
  - API网关配置CORS允许所有来源访问
  - 前端API路径统一修复为 `/api/v1/` 前缀
  - 修复 `chat_viewmodel.dart`、`group_repository.dart`、`notification_repository.dart`、`settings_repository.dart`、`user_viewmodel.dart` 中的API路径
  - 确保所有请求通过API网关统一处理

#### 🔌 WebSocket功能完善
- **实时通信增强**: 提升消息传递能力
  - 完善 `message-service` 的 WebSocket 连接管理
  - 添加客户端管理器和消息路由功能
  - 实现内存存储作为数据库备选方案

#### 📱 前端架构优化
- **Provider配置修复**: 解决依赖注入问题
  - 修复 `FriendViewModel` 的Provider配置错误
  - 统一 `ApiService` 和 `NotificationService` 的单例模式
  - 优化依赖注入和状态管理

#### 🚀 跨平台支持扩展
- **多平台文件生成**: 使用Gemini AI生成完整的平台支持
  - 添加iOS平台支持文件（Xcode项目、Info.plist、Firebase配置）
  - 添加Windows平台支持文件（CMake配置、C++代码）
  - 完善Android、Linux、macOS平台配置
  - 支持真正的跨平台部署

#### 📚 文档完善
- **项目文档更新**: 完善开发和部署指南
  - 更新 `PORTS_DOCUMENTATION.md` 详细记录端口配置
  - 完善 `QUICK_START.md` 快速启动指南
  - 添加 `DEVELOPMENT_TODO.md` 开发任务清单
  - 创建便捷的启动脚本（`start_all.sh`、`start_backend.sh`、`start_frontend.sh`）

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

### 快速启动（推荐）

项目已配置固定端口，避免调试时端口变化问题：

**服务端口配置：**

| 服务类型 | 服务名称 | 端口 | 访问地址 | 说明 |
|---------|---------|------|----------|------|
| 前端 | Flutter Web | 动态分配 | 浏览器自动打开 | 调试端口自动分配 |
| 后端 | API网关 | 8080 | http://localhost:8080 | 统一API入口 |
| 后端 | 用户服务 | 8081 | http://localhost:8081 | 用户认证管理 |
| 后端 | 消息服务 | 8082 | http://localhost:8082 | 即时消息处理 |
| 后端 | 群组服务 | 8083 | http://localhost:8083 | 群组管理 |
| 后端 | 媒体服务 | 8084 | http://localhost:8084 | 文件上传下载 |
| 后端 | 通知服务 | 8085 | http://localhost:8085 | 推送通知 |
| 数据库 | PostgreSQL | 5432 | localhost:5432 | 主数据库 |
| 缓存 | Redis | 6379 | localhost:6379 | 缓存和消息队列 |

**跨域访问解决方案：**
- ✅ API网关已配置CORS允许所有来源 (`*`)
- ✅ 前端统一通过API网关访问后端服务
- ✅ 支持预检请求 (OPTIONS) 处理
- ✅ 设置适当的CORS头信息

**一键启动所有服务：**
```bash
./start_all.sh
```

**分别启动服务：**
```bash
# 启动后端服务
./start_backend.sh

# 启动前端服务（固定端口8090）
./start_frontend.sh
```

**停止所有服务：**
```bash
./stop_services.sh
```

### 手动设置

#### 前端

1. 安装 Flutter SDK
2. 克隆仓库
3. 安装依赖：
   ```bash
   cd frontend
   flutter pub get
   ```
4. 运行应用：
   ```bash
   flutter run -d chrome
   ```

#### 后端

1. 安装 Go
2. 安装 Docker 和 Docker Compose
3. 启动服务：
   ```bash
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