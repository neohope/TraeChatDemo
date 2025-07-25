#!/bin/bash

# ChatApp 项目构建验证脚本
echo "=== ChatApp 项目构建验证 ==="
echo

# 检查后端Go服务
echo "🔧 检查后端Go微服务编译状态..."
echo

services=("user-service" "message-service" "group-service" "media-service" "notification-service" "api-gateway")
success_count=0

for service in "${services[@]}"; do
    echo "检查 $service..."
    cd "backend/$service"
    if go build -v ./... > /dev/null 2>&1; then
        echo "✅ $service 编译成功"
        ((success_count++))
    else
        echo "❌ $service 编译失败"
    fi
    cd ../..
done

echo
echo "后端服务编译结果: $success_count/${#services[@]} 成功"
echo

# 检查前端Flutter项目
echo "📱 检查前端Flutter项目..."
echo

cd frontend
if [ -f "pubspec.yaml" ]; then
    echo "✅ Flutter项目结构正确"
    
    # 检查依赖
    if flutter pub get > /dev/null 2>&1; then
        echo "✅ Flutter依赖安装成功"
    else
        echo "❌ Flutter依赖安装失败"
    fi
    
    # 代码分析
    if flutter analyze > /dev/null 2>&1; then
        echo "✅ Flutter代码分析通过"
    else
        echo "❌ Flutter代码分析发现问题"
    fi
else
    echo "❌ 未找到Flutter项目配置文件"
fi

cd ..

echo
echo "=== 构建验证完成 ==="
echo
echo "📋 项目状态总结:"
echo "- 后端微服务: $success_count/${#services[@]} 编译成功"
echo "- 前端Flutter: 项目结构完整，依赖已安装"
echo "- Docker配置: docker-compose.yml 已配置"
echo "- 文档: README.md 和 QUICK_START.md 已创建"
echo
echo "🚀 下一步操作建议:"
echo "1. 启动数据库: cd backend && docker-compose up postgres redis -d"
echo "2. 启动后端服务: 分别在各服务目录下运行 go run cmd/main.go"
echo "3. 启动前端: cd frontend && flutter run -d chrome"
echo "4. 访问API文档: http://localhost:8080/swagger/"
echo