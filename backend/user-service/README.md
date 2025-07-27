# 用户服务 (User Service)

用户服务是聊天应用的核心微服务之一，负责用户管理、认证和授权。

## 功能

- 用户注册和登录
- 用户资料管理
- 用户搜索和好友查找
- JWT认证
- 密码管理

## 技术栈

- Go
- PostgreSQL
- JWT
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
HTTP_PORT=8081
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
docker build -t chatapp/user-service .

# 运行容器
docker run -p 8081:8081 --name user-service chatapp/user-service
```

## API端点

### 公共API

- `POST /api/v1/users/register` - 注册新用户
- `POST /api/v1/users/login` - 用户登录

### 需要认证的API

- `GET /api/v1/users/me` - 获取当前用户信息
- `GET /api/v1/users/{id}` - 获取指定用户信息
- `PUT /api/v1/users/{id}` - 更新用户信息
- `DELETE /api/v1/users/{id}` - 删除用户
- `GET /api/v1/users` - 获取用户列表
- `GET /api/v1/users/search` - 搜索用户（支持按用户名、全名、邮箱搜索）
- `GET /api/v1/users/recommended` - 获取推荐用户
- `POST /api/v1/users/change-password` - 修改密码

#### 用户搜索API详情

**搜索用户**
- **端点**: `GET /api/v1/users/search`
- **查询参数**:
  - `q` 或 `keyword`: 搜索关键词（必需）
  - `limit`: 返回结果数量限制（可选，默认10，最大100）
  - `offset`: 分页偏移量（可选，默认0）
- **功能特性**:
  - 支持按用户名、全名、邮箱进行模糊搜索
  - 精确匹配优先排序
  - 只返回活跃用户
  - 自动过滤敏感信息（如密码）
  - 支持分页查询
- **示例**:
  ```bash
  # 搜索包含"john"的用户
  GET /api/v1/users/search?q=john
  
  # 分页搜索
  GET /api/v1/users/search?keyword=user&limit=5&offset=10
  ```

## 认证

所有需要认证的API都需要在请求头中包含有效的JWT令牌：

```
Authorization: Bearer {token}
```