package httpdelivery

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"github.com/neohope/chatapp/user-service/internal/domain"
	"github.com/neohope/chatapp/user-service/pkg/auth"
)

// UserHandler 处理用户相关的HTTP请求
type UserHandler struct {
	userService domain.UserService
	jwtManager  *auth.JWTManager
	logger      *zap.Logger
}

// NewUserHandler 创建一个新的用户处理器
func NewUserHandler(userService domain.UserService, jwtManager *auth.JWTManager, logger *zap.Logger) *UserHandler {
	return &UserHandler{
		userService: userService,
		jwtManager:  jwtManager,
		logger:      logger,
	}
}

// RegisterRoutes 注册路由
func (h *UserHandler) RegisterRoutes(router *mux.Router) {
	// 公共路由
	router.HandleFunc("/api/v1/users/register", h.Register).Methods("POST")
	router.HandleFunc("/api/v1/users/login", h.Login).Methods("POST")

	// 受保护的路由
	authRouter := router.PathPrefix("/api/v1").Subrouter()
	authRouter.Use(h.AuthMiddleware)

	// 特定路由必须在通用路由之前注册以避免路由冲突
	authRouter.HandleFunc("/users/me", h.GetCurrentUser).Methods("GET")
	authRouter.HandleFunc("/users/search", h.SearchUsers).Methods("GET")
	authRouter.HandleFunc("/users/recommended", h.GetRecommendedUsers).Methods("GET")
	authRouter.HandleFunc("/users", h.ListUsers).Methods("GET")
	authRouter.HandleFunc("/users/change-password", h.ChangePassword).Methods("POST")
	// 联系人相关路由
	authRouter.HandleFunc("/users/contacts", h.GetContacts).Methods("GET")
	authRouter.HandleFunc("/users/contacts", h.AddContact).Methods("POST")
	authRouter.HandleFunc("/users/contacts/{contactId}", h.RemoveContact).Methods("DELETE")
	authRouter.HandleFunc("/users/contacts/{contactId}/favorite", h.ToggleFavoriteContact).Methods("POST")
	// 通用路由必须在最后注册
	authRouter.HandleFunc("/users/{id}", h.GetUser).Methods("GET")
	authRouter.HandleFunc("/users/{id}", h.UpdateUser).Methods("PUT")
	authRouter.HandleFunc("/users/{id}", h.DeleteUser).Methods("DELETE")


}

// Register 处理用户注册
func (h *UserHandler) Register(w http.ResponseWriter, r *http.Request) {
	// 解析请求
	var req domain.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// 验证请求
	if err := validateRegisterRequest(req); err != nil {
		h.respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	// 创建用户
	user := &domain.User{
		Username: req.Username,
		Email:    req.Email,
		FullName: req.FullName,
	}

	// 注册用户
	if err := h.userService.Register(r.Context(), user, req.Password); err != nil {
		h.logger.Error("Failed to register user", zap.Error(err))
		h.respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	// 清除敏感信息
	user.Password = ""

	// 返回成功响应
	h.respondJSON(w, http.StatusCreated, user)
}

// Login 处理用户登录
func (h *UserHandler) Login(w http.ResponseWriter, r *http.Request) {
	// 解析请求
	var req domain.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// 验证请求
	if req.Identifier == "" || req.Password == "" {
		h.respondError(w, http.StatusBadRequest, "Username/email and password are required")
		return
	}

	// 登录
	token, err := h.userService.Login(r.Context(), req.Identifier, req.Password)
	if err != nil {
		h.logger.Info("Login failed", zap.String("identifier", req.Identifier), zap.Error(err))
		h.respondError(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// 获取用户信息
	claims, err := h.jwtManager.ValidateToken(token)
	if err != nil {
		h.logger.Error("Failed to validate token", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Authentication error")
		return
	}

	user, err := h.userService.GetUserByID(r.Context(), claims.UserID)
	if err != nil {
		h.logger.Error("Failed to get user after login", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to retrieve user information")
		return
	}

	// 返回成功响应
	h.respondJSON(w, http.StatusOK, domain.LoginResponse{
		Token: token,
		User:  user,
	})
}

// GetCurrentUser 获取当前登录用户信息
func (h *UserHandler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	// 从上下文中获取用户ID
	userID := r.Context().Value("user_id").(string)

	// 获取用户信息
	user, err := h.userService.GetUserByID(r.Context(), userID)
	if err != nil {
		h.logger.Error("Failed to get current user", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to retrieve user information")
		return
	}

	// 返回用户信息
	h.respondJSON(w, http.StatusOK, user)
}

// GetUser 获取指定用户信息
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	// 获取路径参数
	vars := mux.Vars(r)
	userID := vars["id"]

	// 获取用户信息
	user, err := h.userService.GetUserByID(r.Context(), userID)
	if err != nil {
		h.logger.Info("User not found", zap.String("id", userID), zap.Error(err))
		h.respondError(w, http.StatusNotFound, "User not found")
		return
	}

	// 返回用户信息
	h.respondJSON(w, http.StatusOK, user)
}

// UpdateUser 更新用户信息
func (h *UserHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	// 获取路径参数
	vars := mux.Vars(r)
	userID := vars["id"]

	// 从上下文中获取当前用户ID
	currentUserID := r.Context().Value("user_id").(string)

	// 验证权限（只能更新自己的信息）
	if userID != currentUserID {
		h.respondError(w, http.StatusForbidden, "You can only update your own profile")
		return
	}

	// 解析请求
	var req domain.UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// 获取现有用户信息
	user, err := h.userService.GetUserByID(r.Context(), userID)
	if err != nil {
		h.logger.Info("User not found for update", zap.String("id", userID), zap.Error(err))
		h.respondError(w, http.StatusNotFound, "User not found")
		return
	}

	// 更新用户信息
	if req.FullName != "" {
		user.FullName = req.FullName
	}
	if req.AvatarURL != "" {
		user.AvatarURL = req.AvatarURL
	}

	// 保存更新
	if err := h.userService.UpdateUser(r.Context(), user); err != nil {
		h.logger.Error("Failed to update user", zap.String("id", userID), zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to update user")
		return
	}

	// 返回更新后的用户信息
	h.respondJSON(w, http.StatusOK, user)
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	// 获取路径参数
	vars := mux.Vars(r)
	userID := vars["id"]

	// 从上下文中获取当前用户ID
	currentUserID := r.Context().Value("user_id").(string)

	// 验证权限（只能删除自己的账户）
	if userID != currentUserID {
		h.respondError(w, http.StatusForbidden, "You can only delete your own account")
		return
	}

	// 删除用户
	if err := h.userService.DeleteUser(r.Context(), userID); err != nil {
		h.logger.Error("Failed to delete user", zap.String("id", userID), zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to delete user")
		return
	}

	// 返回成功响应
	h.respondJSON(w, http.StatusOK, map[string]string{"message": "User deleted successfully"})
}

// ListUsers 获取用户列表
func (h *UserHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	// 获取查询参数
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))

	// 设置默认值
	if limit <= 0 {
		limit = 10
	}
	if offset < 0 {
		offset = 0
	}

	// 获取用户列表
	users, err := h.userService.ListUsers(r.Context(), limit, offset)
	if err != nil {
		h.logger.Error("Failed to list users", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to retrieve users")
		return
	}

	// 返回用户列表
	h.respondJSON(w, http.StatusOK, users)
}

// ChangePassword 修改密码
func (h *UserHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	// 从上下文中获取用户ID
	userID := r.Context().Value("user_id").(string)

	// 解析请求
	var req domain.ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// 验证请求
	if req.OldPassword == "" || req.NewPassword == "" {
		h.respondError(w, http.StatusBadRequest, "Old and new passwords are required")
		return
	}

	// 修改密码
	if err := h.userService.ChangePassword(r.Context(), userID, req.OldPassword, req.NewPassword); err != nil {
		h.logger.Info("Password change failed", zap.String("id", userID), zap.Error(err))
		h.respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	// 返回成功响应
	h.respondJSON(w, http.StatusOK, map[string]string{"message": "Password changed successfully"})
}

// AuthMiddleware 认证中间件
func (h *UserHandler) AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 从Authorization头获取令牌
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			h.respondError(w, http.StatusUnauthorized, "Authorization header is required")
			return
		}

		// 提取令牌
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			h.respondError(w, http.StatusUnauthorized, "Authorization header format must be Bearer {token}")
			return
		}

		tokenString := parts[1]

		// 验证令牌
		claims, err := h.jwtManager.ValidateToken(tokenString)
		if err != nil {
			h.logger.Info("Invalid token", zap.Error(err))
			h.respondError(w, http.StatusUnauthorized, "Invalid or expired token")
			return
		}

		// 检查用户状态
		if claims.Status != domain.UserStatusActive {
			h.respondError(w, http.StatusForbidden, "Account is not active")
			return
		}

		// 将用户信息添加到请求上下文
		ctx := context.WithValue(r.Context(), "user_id", claims.UserID)
		ctx = context.WithValue(ctx, "username", claims.Username)
		ctx = context.WithValue(ctx, "email", claims.Email)

		// 继续处理请求
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// respondJSON 发送JSON响应
func (h *UserHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if data != nil {
		if err := json.NewEncoder(w).Encode(data); err != nil {
			h.logger.Error("Failed to encode response", zap.Error(err))
		}
	}
}

// respondError 发送错误响应
func (h *UserHandler) respondError(w http.ResponseWriter, status int, message string) {
	h.respondJSON(w, status, map[string]string{"error": message})
}

// GetContacts 获取联系人列表
func (h *UserHandler) GetContacts(w http.ResponseWriter, r *http.Request) {
	// 暂时返回空列表，因为联系人功能还未完全实现
	h.respondJSON(w, http.StatusOK, []interface{}{})
}

// AddContact 添加联系人
func (h *UserHandler) AddContact(w http.ResponseWriter, r *http.Request) {
	// 暂时返回成功响应
	h.respondJSON(w, http.StatusOK, map[string]string{"message": "Contact added successfully"})
}

// RemoveContact 删除联系人
func (h *UserHandler) RemoveContact(w http.ResponseWriter, r *http.Request) {
	// 暂时返回成功响应
	h.respondJSON(w, http.StatusOK, map[string]string{"message": "Contact removed successfully"})
}

// ToggleFavoriteContact 切换联系人收藏状态
func (h *UserHandler) ToggleFavoriteContact(w http.ResponseWriter, r *http.Request) {
	// 暂时返回成功响应
	h.respondJSON(w, http.StatusOK, map[string]string{"message": "Contact favorite status toggled"})
}

// SearchUsers 搜索用户
func (h *UserHandler) SearchUsers(w http.ResponseWriter, r *http.Request) {
	// 获取查询参数
	query := r.URL.Query().Get("q")
	keyword := r.URL.Query().Get("keyword")
	
	// 支持两种查询参数格式
	searchTerm := query
	if searchTerm == "" {
		searchTerm = keyword
	}
	
	if searchTerm == "" {
		h.respondError(w, http.StatusBadRequest, "Search term is required")
		return
	}
	
	// 暂时返回空搜索结果
	h.respondJSON(w, http.StatusOK, []interface{}{})
}

// GetRecommendedUsers 获取推荐用户
func (h *UserHandler) GetRecommendedUsers(w http.ResponseWriter, r *http.Request) {
	// 获取查询参数
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	
	// 设置默认值
	if limit <= 0 {
		limit = 10
	}
	if offset < 0 {
		offset = 0
	}
	
	// 暂时返回空推荐用户列表
	// 在实际实现中，这里应该包含推荐算法逻辑
	recommendedUsers := []interface{}{}
	
	// 返回推荐用户列表
	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    recommendedUsers,
		"message": "推荐用户获取成功",
	})
}

// validateRegisterRequest 验证注册请求
func validateRegisterRequest(req domain.RegisterRequest) error {
	if strings.TrimSpace(req.Username) == "" || len(req.Username) < 3 {
		return errors.New("username must be at least 3 characters long")
	}

	if strings.TrimSpace(req.Email) == "" || !strings.Contains(req.Email, "@") {
		return errors.New("valid email is required")
	}

	if strings.TrimSpace(req.Password) == "" || len(req.Password) < 8 {
		return errors.New("password must be at least 8 characters long")
	}

	if strings.TrimSpace(req.FullName) == "" {
		return errors.New("full name is required")
	}

	return nil
}
