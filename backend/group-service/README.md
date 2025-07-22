# Group Service

群组管理服务，提供群组创建、成员管理、邀请系统等功能。

## 功能特性

### 群组管理
- 创建群组（公开/私有）
- 更新群组信息
- 删除群组
- 搜索公开群组
- 获取用户加入的群组列表

### 成员管理
- 添加群组成员
- 移除群组成员
- 更新成员角色和状态
- 获取群组成员列表
- 离开群组

### 邀请系统
- 邀请用户加入群组
- 接受/拒绝邀请
- 获取待处理邀请
- 自动清理过期邀请

### 权限管理
- 群主（Owner）：完全控制权限
- 管理员（Admin）：管理成员和群组设置
- 普通成员（Member）：基本参与权限

## API 接口

### 群组管理

#### 创建群组
```http
POST /api/v1/groups
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "技术交流群",
  "description": "讨论技术问题和分享经验",
  "avatar_url": "https://example.com/avatar.jpg",
  "max_members": 100,
  "is_private": false
}
```

#### 获取群组信息
```http
GET /api/v1/groups/{groupId}
Authorization: Bearer <token>
```

#### 更新群组信息
```http
PUT /api/v1/groups/{groupId}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "新群组名称",
  "description": "新的群组描述"
}
```

#### 删除群组
```http
DELETE /api/v1/groups/{groupId}
Authorization: Bearer <token>
```

#### 搜索群组
```http
GET /api/v1/groups/search?q=技术&limit=20&offset=0
```

#### 获取用户群组
```http
GET /api/v1/users/{userId}/groups
Authorization: Bearer <token>
```

### 成员管理

#### 添加成员
```http
POST /api/v1/groups/{groupId}/members
Authorization: Bearer <token>
Content-Type: application/json

{
  "user_id": "550e8400-e29b-41d4-a716-446655440001",
  "role": "member",
  "nickname": "昵称"
}
```

#### 获取群组成员
```http
GET /api/v1/groups/{groupId}/members
Authorization: Bearer <token>
```

#### 更新成员信息
```http
PUT /api/v1/groups/{groupId}/members/{userId}
Authorization: Bearer <token>
Content-Type: application/json

{
  "role": "admin",
  "status": "active",
  "nickname": "新昵称"
}
```

#### 移除成员
```http
DELETE /api/v1/groups/{groupId}/members/{userId}
Authorization: Bearer <token>
```

#### 离开群组
```http
POST /api/v1/groups/{groupId}/leave
Authorization: Bearer <token>
```

### 邀请管理

#### 邀请用户
```http
POST /api/v1/groups/{groupId}/invitations
Authorization: Bearer <token>
Content-Type: application/json

{
  "user_id": "550e8400-e29b-41d4-a716-446655440001",
  "message": "欢迎加入我们的群组！"
}
```

#### 接受邀请
```http
POST /api/v1/invitations/{invitationId}/accept
Authorization: Bearer <token>
```

#### 拒绝邀请
```http
POST /api/v1/invitations/{invitationId}/reject
Authorization: Bearer <token>
```

#### 获取待处理邀请
```http
GET /api/v1/users/{userId}/invitations
Authorization: Bearer <token>
```

### 健康检查
```http
GET /api/v1/health
```

## 数据模型

### 群组 (Group)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "技术交流群",
  "description": "讨论技术问题和分享经验",
  "avatar_url": "https://example.com/avatar.jpg",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "max_members": 100,
  "is_private": false,
  "created_at": "2025-07-01T00:00:00Z",
   "updated_at": "2025-07-01T00:00:00Z"
}
```

### 群组成员 (GroupMember)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "group_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "owner",
  "status": "active",
  "joined_at": "2025-07-01T00:00:00Z",
  "nickname": "群主",
  "username": "admin",
  "user_avatar_url": "https://example.com/user-avatar.jpg"
}
```

### 群组邀请 (GroupInvitation)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "group_id": "550e8400-e29b-41d4-a716-446655440001",
  "inviter_id": "550e8400-e29b-41d4-a716-446655440000",
  "invitee_id": "550e8400-e29b-41d4-a716-446655440004",
  "status": "pending",
  "message": "欢迎加入我们的群组！",
  "created_at": "2025-07-01T00:00:00Z",
  "expires_at": "2025-07-08T00:00:00Z"
}
```

## 环境变量

```bash
# 服务配置
HTTP_PORT=8083
LOG_LEVEL=info

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

# 外部服务
USER_SERVICE_URL=http://localhost:8081
```

## 运行服务

### 开发环境
```bash
# 安装依赖
go mod tidy

# 运行服务
go run cmd/main.go
```

### 生产环境
```bash
# 构建
go build -o group-service cmd/main.go

# 运行
./group-service
```

### Docker
```bash
# 构建镜像
docker build -t group-service .

# 运行容器
docker run -p 8083:8083 \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=your_password \
  group-service
```

## 数据库

服务支持PostgreSQL数据库，如果数据库连接失败，会自动降级到内存存储模式。

### 数据库表结构
- `groups`: 群组信息
- `group_members`: 群组成员
- `group_invitations`: 群组邀请

### 自动迁移
服务启动时会自动运行数据库迁移脚本，创建必要的表和索引。

## 权限说明

### 群主 (Owner)
- 删除群组
- 转让群主权限
- 管理所有成员
- 修改群组设置

### 管理员 (Admin)
- 添加/移除普通成员
- 修改群组设置
- 管理邀请

### 普通成员 (Member)
- 查看群组信息
- 发送邀请
- 离开群组

## 错误码

- `400`: 请求参数错误
- `401`: 未授权访问
- `403`: 权限不足
- `404`: 资源不存在
- `409`: 资源冲突（如重复邀请）
- `500`: 服务器内部错误

## 日志

服务使用结构化日志，包含以下信息：
- 请求路径和方法
- 响应状态码
- 处理时间
- 错误信息
- 用户操作记录

## 监控

### 健康检查
```http
GET /api/v1/health
```

### 数据库连接统计
服务内部维护数据库连接池统计信息，可用于监控数据库性能。

## 安全考虑

1. **JWT验证**: 所有API都需要有效的JWT令牌
2. **权限控制**: 基于角色的访问控制
3. **输入验证**: 严格的请求参数验证
4. **SQL注入防护**: 使用参数化查询
5. **CORS配置**: 适当的跨域资源共享设置

## 性能优化

1. **数据库索引**: 为常用查询字段创建索引
2. **连接池**: 配置合适的数据库连接池
3. **缓存**: 可考虑添加Redis缓存热点数据
4. **分页**: 大数据量查询支持分页
5. **清理任务**: 定期清理过期数据