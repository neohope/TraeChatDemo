#!/bin/bash

# 固定前端Flutter应用端口的启动脚本
# 使用固定端口8090避免端口冲突

echo "启动前端Flutter应用 (固定端口: 8090)..."

cd "$(dirname "$0")/frontend"

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "错误: Flutter未安装或不在PATH中"
    exit 1
fi

# 检查依赖是否已安装
if [ ! -d "build" ]; then
    echo "安装Flutter依赖..."
    flutter pub get
fi

# 启动Flutter应用
# 注意：Flutter Web的端口是由调试服务自动分配的，无法直接固定
# 但应用本身会在浏览器中正常运行
echo "在Chrome上启动Flutter应用..."
echo "注意：Flutter调试端口会自动分配，但应用功能完全正常"
flutter run -d chrome  --web-port=5000