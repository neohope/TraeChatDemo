#!/bin/bash

# 启动所有前后端服务的脚本
# 使用固定端口配置

echo "=== TraeChatDemo 服务启动脚本 ==="
echo "端口配置:"
echo "  前端 (Flutter): 调试端口自动分配，应用在浏览器中正常运行"
echo "  后端 (API网关): http://localhost:8080 (固定)"
echo ""

# 检查必要的工具
echo "检查环境..."
if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo "错误: Flutter未安装"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "错误: Docker未运行，请先启动Docker"
    exit 1
fi

echo "环境检查通过"
echo ""

# 启动后端服务
echo "1. 启动后端服务..."
./start_backend.sh

if [ $? -ne 0 ]; then
    echo "后端服务启动失败"
    exit 1
fi

echo ""
echo "等待后端服务完全启动..."
sleep 10

# 启动前端服务
echo "2. 启动前端服务..."
echo "前端将在新终端窗口中启动..."
echo "前端地址: http://localhost:8090"
echo ""

# 在后台启动前端（这样脚本不会阻塞）
gnome-terminal -- bash -c "./start_frontend.sh; exec bash" 2>/dev/null || \
osascript -e 'tell app "Terminal" to do script "cd '$(pwd)' && ./start_frontend.sh"' 2>/dev/null || \
echo "请手动运行: ./start_frontend.sh"

echo "=== 服务启动完成 ==="
echo "前端: Flutter应用将在浏览器中自动打开"
echo "后端API: http://localhost:8080"
echo ""
echo "要停止所有服务，请运行: ./stop_services.sh"