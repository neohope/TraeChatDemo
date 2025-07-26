package http

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"github.com/neohope/chatapp/api-gateway/internal/delivery"
	"github.com/neohope/chatapp/api-gateway/internal/service"
)

type Handler struct {
	proxyService *service.ProxyService
	middleware   *delivery.Middleware
	logger       *zap.Logger
}

type HealthResponse struct {
	Status   string          `json:"status"`
	Services map[string]bool `json:"services"`
}

func NewHandler(proxyService *service.ProxyService, middleware *delivery.Middleware, logger *zap.Logger) *Handler {
	return &Handler{
		proxyService: proxyService,
		middleware:   middleware,
		logger:       logger,
	}
}

func (h *Handler) RegisterRoutes(router *mux.Router, corsConfig struct {
	AllowedOrigins []string
	AllowedMethods []string
	AllowedHeaders []string
}) {
	// 应用全局中间件
	router.Use(h.middleware.Logging())
	router.Use(h.middleware.CORS(corsConfig.AllowedOrigins, corsConfig.AllowedMethods, corsConfig.AllowedHeaders))
	router.Use(h.middleware.RateLimit())

	// 健康检查端点（无需认证）
	router.HandleFunc("/health", h.HealthCheck).Methods("GET")

	// API路由
	api := router.PathPrefix("/api/v1").Subrouter()

	// 用户服务路由（部分需要认证）
	userRoutes := api.PathPrefix("/users").Subrouter()
	// 登录和注册不需要认证
	userRoutes.HandleFunc("/register", h.proxyToUserService).Methods("POST")
	userRoutes.HandleFunc("/login", h.proxyToUserService).Methods("POST")
	// 其他用户相关操作需要认证
	userAuthRoutes := userRoutes.PathPrefix("/").Subrouter()
	userAuthRoutes.Use(h.middleware.JWTAuth())
	userAuthRoutes.PathPrefix("/").HandlerFunc(h.proxyToUserService)

	// 群组服务路由（需要认证）
	groupRoutes := api.PathPrefix("/groups").Subrouter()
	groupRoutes.Use(h.middleware.JWTAuth())
	groupRoutes.PathPrefix("/").HandlerFunc(h.proxyToGroupService)

	// 消息服务路由（需要认证）
	messageRoutes := api.PathPrefix("/messages").Subrouter()
	messageRoutes.Use(h.middleware.JWTAuth())
	messageRoutes.PathPrefix("/").HandlerFunc(h.proxyToMessageService)

	// 会话服务路由（需要认证）- 也代理到消息服务
	api.PathPrefix("/conversations").Handler(h.middleware.JWTAuth()(http.HandlerFunc(h.proxyToMessageService)))

	// 媒体服务路由（需要认证）
	mediaRoutes := api.PathPrefix("/media").Subrouter()
	mediaRoutes.Use(h.middleware.JWTAuth())
	mediaRoutes.PathPrefix("/").HandlerFunc(h.proxyToMediaService)

	// 通知服务路由（需要认证）
	notificationRoutes := api.PathPrefix("/notifications").Subrouter()
	notificationRoutes.Use(h.middleware.JWTAuth())
	notificationRoutes.PathPrefix("/").HandlerFunc(h.proxyToNotificationService)

	// WebSocket路由（需要认证）
	api.HandleFunc("/ws", h.middleware.JWTAuth()(http.HandlerFunc(h.proxyToMessageServiceWS)).ServeHTTP).Methods("GET")
}

func (h *Handler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	servicesHealth := h.proxyService.HealthCheck()

	allHealthy := true
	for _, healthy := range servicesHealth {
		if !healthy {
			allHealthy = false
			break
		}
	}

	status := "healthy"
	if !allHealthy {
		status = "degraded"
	}

	response := HealthResponse{
		Status:   status,
		Services: servicesHealth,
	}

	w.Header().Set("Content-Type", "application/json")
	if !allHealthy {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		h.logger.Error("Failed to encode health response", zap.Error(err))
	}
}

func (h *Handler) proxyToUserService(w http.ResponseWriter, r *http.Request) {
	h.logger.Info("Proxying to user service", zap.String("method", r.Method), zap.String("path", r.URL.Path))
	h.proxyService.ProxyRequest(w, r, "users")
}

func (h *Handler) proxyToGroupService(w http.ResponseWriter, r *http.Request) {
	h.proxyService.ProxyRequest(w, r, "groups")
}

func (h *Handler) proxyToMessageService(w http.ResponseWriter, r *http.Request) {
	h.logger.Info("Proxying to message service", zap.String("method", r.Method), zap.String("path", r.URL.Path))
	h.proxyService.ProxyRequest(w, r, "messages")
}

func (h *Handler) proxyToMediaService(w http.ResponseWriter, r *http.Request) {
	h.proxyService.ProxyRequest(w, r, "media")
}

func (h *Handler) proxyToNotificationService(w http.ResponseWriter, r *http.Request) {
	h.proxyService.ProxyRequest(w, r, "notifications")
}

func (h *Handler) proxyToMessageServiceWS(w http.ResponseWriter, r *http.Request) {
	// WebSocket代理需要特殊处理
	// 这里简化处理，直接转发到消息服务的WebSocket端点
	messageServiceURL := "ws://localhost:8083/ws"

	// 获取用户信息
	userID := r.Context().Value("user_id")
	if userID != nil {
		// 添加用户ID到查询参数
		if r.URL.RawQuery != "" {
			r.URL.RawQuery += "&user_id=" + userID.(string)
		} else {
			r.URL.RawQuery = "user_id=" + userID.(string)
		}
	}

	// 重定向到消息服务的WebSocket
	http.Redirect(w, r, messageServiceURL+"?"+r.URL.RawQuery, http.StatusTemporaryRedirect)
}

// 辅助函数：从路径中提取服务名
func extractServiceFromPath(path string) string {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) >= 3 && parts[0] == "api" && parts[1] == "v1" {
		return parts[2]
	}
	return ""
}
