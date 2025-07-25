# Media Service

媒体服务是聊天应用的核心组件之一，负责处理文件上传、存储、处理和分发。支持图片、视频、音频和文档等多种媒体类型。

## 功能特性

### 核心功能
- **多媒体文件上传**：支持图片、视频、音频、文档等多种格式
- **多存储后端**：支持本地存储、AWS S3、MinIO等存储方案
- **文件处理**：自动生成缩略图、图片压缩、格式转换
- **安全控制**：文件类型验证、大小限制、病毒扫描
- **配额管理**：用户存储配额控制和监控
- **CDN集成**：支持CDN加速文件分发

### 高级特性
- **预签名URL**：支持客户端直接上传到云存储
- **文件去重**：基于哈希值的文件去重机制
- **临时文件**：支持临时文件自动清理
- **批量操作**：支持批量上传、下载、删除
- **元数据提取**：自动提取文件元数据信息
- **异步处理**：后台异步处理大文件

## 架构设计

### 分层架构
```
┌─────────────────┐
│   HTTP Handler  │  ← REST API接口层
├─────────────────┤
│   Service Layer │  ← 业务逻辑层
├─────────────────┤
│ Repository Layer│  ← 数据访问层
├─────────────────┤
│  Storage Layer  │  ← 存储抽象层
└─────────────────┘
```

### 存储架构
- **本地存储**：适用于开发环境和小规模部署
- **AWS S3**：生产环境推荐的云存储方案
- **MinIO**：私有云存储解决方案
- **CDN**：内容分发网络加速

## API 接口

### 文件上传
```http
POST /api/v1/upload
Content-Type: multipart/form-data

{
  "file": "<binary_data>",
  "user_id": "user123",
  "media_type": "image"
}
```

### 获取文件信息
```http
GET /api/v1/media/{media_id}

Response:
{
  "id": "media123",
  "filename": "image.jpg",
  "mime_type": "image/jpeg",
  "file_size": 1024000,
  "public_url": "https://cdn.example.com/media123.jpg",
  "thumbnail_url": "https://cdn.example.com/thumb_media123.jpg"
}
```

### 文件列表
```http
GET /api/v1/media?user_id=user123&limit=20&offset=0

Response:
{
  "medias": [...],
  "total": 100,
  "limit": 20,
  "offset": 0
}
```

### 删除文件
```http
DELETE /api/v1/media/{media_id}
```

### 生成缩略图
```http
POST /api/v1/media/{media_id}/thumbnail
{
  "width": 200,
  "height": 200,
  "quality": 80
}
```

### 获取预签名URL
```http
POST /api/v1/upload/presigned
{
  "filename": "image.jpg",
  "mime_type": "image/jpeg",
  "file_size": 1024000
}

Response:
{
  "media_id": "media123",
  "upload_url": "https://s3.amazonaws.com/bucket/...",
  "expires_at": 1640995200
}
```

## 环境变量

### 服务配置
```bash
# 服务端口
SERVER_PORT=8083

# 日志级别
LOG_LEVEL=info

# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=media_db

# JWT配置
JWT_SECRET_KEY=your-secret-key
```

### 存储配置
```bash
# 存储提供者 (local, s3, minio)
STORAGE_PROVIDER=local
STORAGE_LOCAL_PATH=./uploads
STORAGE_BASE_URL=http://localhost:8083

# AWS S3配置
AWS_REGION=us-west-2
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_BUCKET_NAME=your-bucket

# MinIO配置
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET_NAME=media
```

### 文件配置
```bash
# 文件大小限制 (字节)
MAX_FILE_SIZE=104857600        # 100MB
MAX_IMAGE_SIZE=10485760        # 10MB
MAX_VIDEO_SIZE=1073741824      # 1GB

# 允许的文件类型
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,gif,webp
ALLOWED_VIDEO_TYPES=mp4,avi,mov,wmv
ALLOWED_AUDIO_TYPES=mp3,wav,aac,ogg
ALLOWED_FILE_TYPES=pdf,doc,docx,txt

# 图片处理配置
THUMBNAIL_WIDTH=200
THUMBNAIL_HEIGHT=200
IMAGE_QUALITY=80
```

## 快速开始

### 1. 环境准备
```bash
# 安装Go 1.19+
go version

# 安装PostgreSQL
# 创建数据库
psql -c "CREATE DATABASE media_db;"
```

### 2. 配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
vim .env
```

### 3. 运行服务
```bash
# 安装依赖
go mod download

# 运行数据库迁移
go run cmd/main.go -migrate

# 启动服务
go run cmd/main.go
```

### 4. Docker部署
```bash
# 构建镜像
docker build -t media-service .

# 运行容器
docker run -p 8083:8083 \
  -e DB_HOST=postgres \
  -e STORAGE_PROVIDER=local \
  media-service
```

## 数据库设计

### 媒体文件表 (medias)
```sql
CREATE TABLE medias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'uploading',
    storage_path TEXT NOT NULL,
    public_url TEXT,
    thumbnail_url TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);
```

### 处理任务表 (processing_jobs)
```sql
CREATE TABLE processing_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id UUID REFERENCES medias(id),
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    params JSONB,
    result JSONB,
    error TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);
```

### 用户配额表 (user_storage_quotas)
```sql
CREATE TABLE user_storage_quotas (
    user_id VARCHAR(255) PRIMARY KEY,
    total_quota BIGINT DEFAULT 1073741824, -- 1GB
    used_quota BIGINT DEFAULT 0,
    file_count INTEGER DEFAULT 0,
    max_file_size BIGINT DEFAULT 104857600, -- 100MB
    max_file_count INTEGER DEFAULT 1000,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## 监控与运维

### 健康检查
```bash
curl http://localhost:8083/health
```

### 指标监控
- 文件上传成功率
- 平均上传时间
- 存储使用量
- 处理队列长度
- 错误率统计

### 日志格式
```json
{
  "timestamp": "2023-12-01T10:00:00Z",
  "level": "info",
  "message": "File uploaded successfully",
  "user_id": "user123",
  "media_id": "media456",
  "file_size": 1024000,
  "duration_ms": 1500
}
```

## 性能优化

### 上传优化
- 使用预签名URL减少服务器负载
- 支持分片上传大文件
- 客户端压缩减少传输时间
- 并发上传提高吞吐量

### 存储优化
- 文件去重节省存储空间
- 冷热数据分层存储
- CDN缓存加速访问
- 定期清理过期文件

### 处理优化
- 异步处理避免阻塞
- 队列机制平滑负载
- 缓存处理结果
- 批量操作提高效率

## 安全考虑

### 文件安全
- 文件类型白名单验证
- 文件内容扫描检测
- 文件大小限制
- 恶意文件隔离

### 访问控制
- JWT令牌验证
- 用户权限检查
- 文件访问日志
- 防盗链保护

### 数据保护
- 传输加密(HTTPS)
- 存储加密
- 敏感信息脱敏
- 定期备份

## 扩展功能

### 图片处理
- 自动生成多尺寸缩略图
- 图片格式转换
- 图片压缩优化
- 水印添加

### 视频处理
- 视频转码
- 视频截图
- 视频压缩
- 格式转换

### 音频处理
- 音频转码
- 音频压缩
- 格式转换
- 音频剪辑

## 故障排除

### 常见问题
1. **上传失败**：检查文件大小、类型限制
2. **存储空间不足**：检查配额设置和磁盘空间
3. **处理超时**：检查处理队列和资源使用
4. **访问被拒绝**：检查权限配置和JWT令牌

### 调试命令
```bash
# 查看服务状态
curl http://localhost:8083/health

# 查看存储信息
curl http://localhost:8083/api/v1/storage/info

# 查看用户配额
curl http://localhost:8083/api/v1/quota/{user_id}
```