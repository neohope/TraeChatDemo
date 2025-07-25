#!/bin/bash

# ChatApp 项目构建脚本
echo "🚀 开始构建 ChatApp 项目..."

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 构建结果统计
SUCCESS_COUNT=0
FAIL_COUNT=0
SERVICES=("user-service" "message-service" "group-service" "media-service" "notification-service" "api-gateway")

echo "📦 构建后端微服务..."
echo "=============================="

# 构建后端服务
for service in "${SERVICES[@]}"; do
    echo -e "${YELLOW}构建 $service...${NC}"
    cd "backend/$service"
    
    # 检查 go.mod 文件是否存在
    if [ ! -f "go.mod" ]; then
        echo -e "${RED}❌ $service: go.mod 文件不存在${NC}"
        ((FAIL_COUNT++))
        cd ../..
        continue
    fi
    
    # 整理依赖
    go mod tidy > /dev/null 2>&1
    
    # 构建服务
    if go build -v ./... > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service: 构建成功${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}❌ $service: 构建失败${NC}"
        ((FAIL_COUNT++))
    fi
    
    cd ../..
done

echo ""
echo "📱 检查前端项目..."
echo "=============================="

# 检查前端项目
cd frontend

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ 前端: pubspec.yaml 文件不存在${NC}"
    ((FAIL_COUNT++))
else
    echo -e "${YELLOW}检查 Flutter 依赖...${NC}"
    
    # 检查 Flutter 是否安装
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ 前端: Flutter 未安装${NC}"
        ((FAIL_COUNT++))
    else
        # 获取依赖
        if flutter pub get > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 前端: 依赖安装成功${NC}"
            ((SUCCESS_COUNT++))
            
            # 尝试分析项目
            if flutter analyze > /dev/null 2>&1; then
                echo -e "${GREEN}✅ 前端: 代码分析通过${NC}"
            else
                echo -e "${YELLOW}⚠️  前端: 代码分析有警告${NC}"
            fi
        else
            echo -e "${RED}❌ 前端: 依赖安装失败${NC}"
            ((FAIL_COUNT++))
        fi
    fi
fi

cd ..

echo ""
echo "📊 构建结果统计"
echo "=============================="
echo -e "${GREEN}✅ 成功: $SUCCESS_COUNT${NC}"
echo -e "${RED}❌ 失败: $FAIL_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 所有组件构建成功！${NC}"
    echo ""
    echo "🚀 下一步操作建议:"
    echo "1. 安装 Docker Desktop 以使用容器化部署"
    echo "2. 运行 'cd backend && docker-compose up -d' 启动后端服务"
    echo "3. 运行 'cd frontend && flutter run -d chrome' 启动前端应用"
    exit 0
else
    echo -e "${RED}💥 构建过程中遇到了一些问题${NC}"
    echo ""
    echo "🔧 故障排除建议:"
    echo "1. 确保 Go 1.19+ 已正确安装"
    echo "2. 确保 Flutter 3.0+ 已正确安装"
    echo "3. 检查网络连接，确保能够下载依赖"
    echo "4. 查看具体错误信息并修复代码问题"
    exit 1
fi