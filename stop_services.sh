#!/bin/bash

# 停止所有前后端服务的脚本

echo "停止所有服务..."

# 停止后端Docker服务
echo "停止后端Docker服务..."
cd "$(dirname "$0")/backend"
if [ -f "docker-compose.yml" ]; then
    docker-compose down
    echo "后端服务已停止"
else
    echo "未找到docker-compose.yml文件"
fi

# 停止可能运行的Flutter进程
echo "停止Flutter进程..."
pkill -f "flutter.*run" 2>/dev/null || true
pkill -f "dart.*frontend" 2>/dev/null || true

echo "所有服务已停止"