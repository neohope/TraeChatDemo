#!/bin/bash

# 好友请求端到端测试脚本
# 此脚本验证好友请求功能的完整流程

echo "🚀 开始好友请求端到端测试..."

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数器
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# 测试函数
test_api() {
    local test_name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"
    local token="$6"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    echo -e "\n📋 测试 $TEST_COUNT: $test_name"
    
    # 构建curl命令
    local curl_cmd="curl -s -w '%{http_code}' -X $method '$url'"
    
    if [ ! -z "$token" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $token'"
    fi
    
    if [ ! -z "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    # 执行请求
    local response=$(eval $curl_cmd)
    local status_code=${response: -3}
    local body=${response%???}
    
    echo "   请求: $method $url"
    if [ ! -z "$data" ]; then
        echo "   数据: $data"
    fi
    echo "   响应状态: $status_code"
    echo "   响应内容: $body"
    
    # 验证状态码
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "   ${GREEN}✅ 通过${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "   ${RED}❌ 失败 - 期望状态码 $expected_status，实际 $status_code${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# 检查服务是否运行
echo "🔍 检查服务状态..."
if ! curl -s http://localhost:8080/health > /dev/null; then
    echo -e "${RED}❌ API网关未运行，请先启动后端服务${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 后端服务正在运行${NC}"

# 1. 用户登录获取令牌
echo -e "\n🔐 步骤1: 用户登录"
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8080/api/v1/users/login" \
    -H "Content-Type: application/json" \
    -d '{"identifier":"testuser","password":"password123"}')

echo "登录响应: $LOGIN_RESPONSE"

# 提取JWT令牌
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ 登录失败，无法获取令牌${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 登录成功，获取到令牌${NC}"
echo "令牌: ${TOKEN:0:50}..."

# 2. 测试发送好友请求
test_api "发送好友请求" "POST" "http://localhost:8080/api/v1/friends/request" \
    '{"userId":"target-user-123","message":"你好，我想加你为好友"}' "200" "$TOKEN"

# 3. 测试发送好友请求失败（缺少用户ID）
test_api "发送好友请求失败-缺少用户ID" "POST" "http://localhost:8080/api/v1/friends/request" \
    '{"message":"你好"}' "400" "$TOKEN"

# 4. 测试发送好友请求失败（给自己发送）
test_api "发送好友请求失败-给自己发送" "POST" "http://localhost:8080/api/v1/friends/request" \
    '{"userId":"eb09f745-0674-41ed-bfd8-88d24cabe266","message":"测试"}' "400" "$TOKEN"

# 5. 测试获取待处理好友请求
test_api "获取待处理好友请求" "GET" "http://localhost:8080/api/v1/friends/pending" "" "200" "$TOKEN"

# 6. 测试获取已发送好友请求
test_api "获取已发送好友请求" "GET" "http://localhost:8080/api/v1/friends/sent" "" "200" "$TOKEN"

# 7. 测试接受好友请求
test_api "接受好友请求" "POST" "http://localhost:8080/api/v1/friends/accept" \
    '{"requestId":"test-request-123"}' "200" "$TOKEN"

# 8. 测试拒绝好友请求
test_api "拒绝好友请求" "POST" "http://localhost:8080/api/v1/friends/reject" \
    '{"requestId":"test-request-456"}' "200" "$TOKEN"

# 9. 测试未授权访问
test_api "未授权访问" "GET" "http://localhost:8080/api/v1/friends/pending" "" "401" ""

# 10. 测试获取好友列表
test_api "获取好友列表" "GET" "http://localhost:8080/api/v1/friends" "" "200" "$TOKEN"

# 输出测试结果
echo -e "\n📊 测试结果汇总:"
echo -e "   总测试数: $TEST_COUNT"
echo -e "   ${GREEN}通过: $PASS_COUNT${NC}"
echo -e "   ${RED}失败: $FAIL_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！好友请求功能正常工作。${NC}"
    exit 0
else
    echo -e "\n${RED}❌ 有 $FAIL_COUNT 个测试失败，请检查问题。${NC}"
    exit 1
fi