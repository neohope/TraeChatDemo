package test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	httpdelivery "github.com/neohope/chatapp/user-service/internal/delivery/http"
	"github.com/neohope/chatapp/user-service/internal/domain"
	"github.com/neohope/chatapp/user-service/pkg/auth"
)

// MockUserService 模拟用户服务
type MockUserService struct{}

func (m *MockUserService) Register(ctx context.Context, user *domain.User, password string) error {
	return nil
}

func (m *MockUserService) Login(ctx context.Context, identifier, password string) (string, error) {
	return "mock-token", nil
}

func (m *MockUserService) GetUserByID(ctx context.Context, id string) (*domain.User, error) {
	return &domain.User{
		ID:       id,
		Username: "testuser",
		Email:    "test@example.com",
		Status:   domain.UserStatusActive,
	}, nil
}

func (m *MockUserService) GetUserByEmail(ctx context.Context, email string) (*domain.User, error) {
	return &domain.User{
		ID:       "test-id",
		Username: "testuser",
		Email:    email,
		Status:   domain.UserStatusActive,
	}, nil
}

func (m *MockUserService) GetUserByUsername(ctx context.Context, username string) (*domain.User, error) {
	return &domain.User{
		ID:       "test-id",
		Username: username,
		Email:    "test@example.com",
		Status:   domain.UserStatusActive,
	}, nil
}

func (m *MockUserService) UpdateUser(ctx context.Context, user *domain.User) error {
	return nil
}

func (m *MockUserService) DeleteUser(ctx context.Context, id string) error {
	return nil
}

func (m *MockUserService) ListUsers(ctx context.Context, limit, offset int) ([]*domain.User, error) {
	return []*domain.User{}, nil
}

func (m *MockUserService) SearchUsers(ctx context.Context, query string, limit, offset int) ([]*domain.User, error) {
	return []*domain.User{}, nil
}

func (m *MockUserService) ChangePassword(ctx context.Context, userID, oldPassword, newPassword string) error {
	return nil
}

// MockFriendService 模拟好友服务
type MockFriendService struct{}

func (m *MockFriendService) SendFriendRequest(ctx context.Context, fromUserID, toUserID, message string) error {
	return nil
}

func (m *MockFriendService) AcceptFriendRequest(ctx context.Context, requestID, userID string) error {
	return nil
}

func (m *MockFriendService) RejectFriendRequest(ctx context.Context, requestID, userID string) error {
	return nil
}

func (m *MockFriendService) GetPendingFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequest, error) {
	return []*domain.FriendRequest{}, nil
}

func (m *MockFriendService) GetSentFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequest, error) {
	return []*domain.FriendRequest{}, nil
}

func (m *MockFriendService) GetFriends(ctx context.Context, userID string) ([]*domain.User, error) {
	return []*domain.User{}, nil
}

func (m *MockFriendService) RemoveFriend(ctx context.Context, userID, friendID string) error {
	return nil
}

func (m *MockFriendService) CheckFriendship(ctx context.Context, user1ID, user2ID string) (bool, error) {
	return false, nil
}

// 测试好友请求功能
func TestFriendRequestHandlers(t *testing.T) {
	// 设置测试环境
	mockUserService := new(MockUserService)
	mockFriendService := new(MockFriendService)
	jwtManager := auth.NewJWTManager("test-secret", 24)
	logger := zap.NewNop()

	handler := httpdelivery.NewUserHandler(mockUserService, mockFriendService, jwtManager, logger)

	// 创建测试用户
	testUser := &domain.User{
		ID:       "test-user-id",
		Username: "testuser",
		Email:    "test@example.com",
		Status:   domain.UserStatusActive,
	}

	// 生成测试JWT令牌
	token, err := jwtManager.GenerateToken(testUser)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	t.Run("发送好友请求成功", func(t *testing.T) {
		// 准备请求数据
		requestData := map[string]interface{}{
			"userId":  "target-user-id",
			"message": "你好，我想加你为好友",
		}
		jsonData, _ := json.Marshal(requestData)

		// 创建HTTP请求
		req := httptest.NewRequest("POST", "/api/v1/friends/request", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)

		// 创建响应记录器
		rr := httptest.NewRecorder()

		// 创建路由器并注册路由
		router := mux.NewRouter()
		handler.RegisterRoutes(router)

		// 执行请求
		router.ServeHTTP(rr, req)

		// 验证响应
		if rr.Code != http.StatusOK {
			t.Errorf("Expected status %d, got %d", http.StatusOK, rr.Code)
		}

		var response map[string]interface{}
		err := json.Unmarshal(rr.Body.Bytes(), &response)
		if err != nil {
			t.Errorf("Failed to unmarshal response: %v", err)
		}

		if success, ok := response["success"].(bool); !ok || !success {
			t.Errorf("Expected success=true, got %v", response["success"])
		}

		if message, ok := response["message"].(string); !ok || message != "好友请求发送成功" {
			t.Errorf("Expected message='好友请求发送成功', got %v", response["message"])
		}
	})

	t.Run("发送好友请求失败 - 缺少用户ID", func(t *testing.T) {
		// 准备无效请求数据
		requestData := map[string]interface{}{
			"message": "你好",
			// 缺少userId字段
		}
		jsonData, _ := json.Marshal(requestData)

		// 创建HTTP请求
		req := httptest.NewRequest("POST", "/api/v1/friends/request", bytes.NewBuffer(jsonData))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)

		// 创建响应记录器
		rr := httptest.NewRecorder()

		// 创建路由器并注册路由
		router := mux.NewRouter()
		handler.RegisterRoutes(router)

		// 执行请求
		router.ServeHTTP(rr, req)

		// 验证响应
		if rr.Code != http.StatusBadRequest {
			t.Errorf("Expected status %d, got %d", http.StatusBadRequest, rr.Code)
		}

		var response map[string]interface{}
		err := json.Unmarshal(rr.Body.Bytes(), &response)
		if err != nil {
			t.Errorf("Failed to unmarshal response: %v", err)
		}

		if errorMsg, ok := response["error"].(string); !ok || errorMsg != "User ID is required" {
			t.Errorf("Expected error='User ID is required', got %v", response["error"])
		}
	})

	t.Run("获取待处理好友请求", func(t *testing.T) {
		// 创建HTTP请求
		req := httptest.NewRequest("GET", "/api/v1/friends/pending", nil)
		req.Header.Set("Authorization", "Bearer "+token)

		// 创建响应记录器
		rr := httptest.NewRecorder()

		// 创建路由器并注册路由
		router := mux.NewRouter()
		handler.RegisterRoutes(router)

		// 执行请求
		router.ServeHTTP(rr, req)

		// 验证响应
		if rr.Code != http.StatusOK {
			t.Errorf("Expected status %d, got %d", http.StatusOK, rr.Code)
		}

		// 验证响应是数组格式
		responseBody := strings.TrimSpace(rr.Body.String())
		if !strings.HasPrefix(responseBody, "[") || !strings.HasSuffix(responseBody, "]") {
			t.Errorf("Expected array response, got: %s", responseBody)
		}
	})

	t.Run("获取已发送好友请求", func(t *testing.T) {
		// 创建HTTP请求
		req := httptest.NewRequest("GET", "/api/v1/friends/sent", nil)
		req.Header.Set("Authorization", "Bearer "+token)

		// 创建响应记录器
		rr := httptest.NewRecorder()

		// 创建路由器并注册路由
		router := mux.NewRouter()
		handler.RegisterRoutes(router)

		// 执行请求
		router.ServeHTTP(rr, req)

		// 验证响应
		if rr.Code != http.StatusOK {
			t.Errorf("Expected status %d, got %d", http.StatusOK, rr.Code)
		}

		// 验证响应是数组格式
		responseBody := strings.TrimSpace(rr.Body.String())
		if !strings.HasPrefix(responseBody, "[") || !strings.HasSuffix(responseBody, "]") {
			t.Errorf("Expected array response, got: %s", responseBody)
		}
	})

	t.Run("未授权访问", func(t *testing.T) {
		// 创建没有Authorization头的请求
		req := httptest.NewRequest("GET", "/api/v1/friends/pending", nil)

		// 创建响应记录器
		rr := httptest.NewRecorder()

		// 创建路由器并注册路由
		router := mux.NewRouter()
		handler.RegisterRoutes(router)

		// 执行请求
		router.ServeHTTP(rr, req)

		// 验证响应
		if rr.Code != http.StatusUnauthorized {
			t.Errorf("Expected status %d, got %d", http.StatusUnauthorized, rr.Code)
		}

		var response map[string]interface{}
		err := json.Unmarshal(rr.Body.Bytes(), &response)
		if err != nil {
			t.Errorf("Failed to unmarshal response: %v", err)
		}

		if errorMsg, ok := response["error"].(string); !ok || errorMsg != "Authorization header is required" {
			t.Errorf("Expected error='Authorization header is required', got %v", response["error"])
		}
	})
}