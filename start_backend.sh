#!/bin/bash

# 固定后端服务端口的启动脚本
# 所有服务端口已在docker-compose.yml中固定

echo "启动后端服务 (固定端口配置)..."

cd "$(dirname "$0")/backend"

# 检查Docker是否运行
if ! docker info &> /dev/null; then
    echo "错误: Docker未运行，请先启动Docker"
    exit 1
fi

# 检查docker-compose是否可用
if ! command -v docker-compose &> /dev/null; then
    echo "错误: docker-compose未安装"
    exit 1
fi

# 显示服务端口配置
echo "后端服务端口配置:"
echo "  - API网关:     http://localhost:8080"
echo "  - 用户服务:     http://localhost:8081"
echo "  - 消息服务:     http://localhost:8082"
echo "  - 群组服务:     http://localhost:8083"
echo "  - 媒体服务:     http://localhost:8084"
echo "  - 通知服务:     http://localhost:8085"
echo "  - PostgreSQL:  localhost:5432"
echo "  - Redis:       localhost:6379"
echo ""

# 启动所有后端服务
echo "启动Docker容器..."
docker-compose up -d

# 检查服务状态
echo ""
echo "检查服务状态..."
docker-compose ps

echo ""
echo "后端服务启动完成！"
echo "API网关地址: http://localhost:8080"