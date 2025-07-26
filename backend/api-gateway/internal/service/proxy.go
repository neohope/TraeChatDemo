package service

import (
	"bytes"
	"io"
	"net/http"
	"net/url"
	"time"

	"go.uber.org/zap"

	"github.com/neohope/chatapp/api-gateway/config"
)

type ProxyService struct {
	services map[string]string
	client   *http.Client
	logger   *zap.Logger
}

func NewProxyService(cfg *config.ServicesConfig, logger *zap.Logger) *ProxyService {
	services := map[string]string{
		"users":         cfg.UserService,
		"groups":        cfg.GroupService,
		"messages":      cfg.MessageService,
		"media":         cfg.MediaService,
		"notifications": cfg.NotificationService,
	}

	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	return &ProxyService{
		services: services,
		client:   client,
		logger:   logger,
	}
}

func (p *ProxyService) ProxyRequest(w http.ResponseWriter, r *http.Request, serviceName string) {
	// 获取目标服务URL
	targetURL, exists := p.services[serviceName]
	if !exists {
		p.logger.Error("Service not found", zap.String("service", serviceName))
		http.Error(w, "Service not found", http.StatusNotFound)
		return
	}

	// 构建完整的目标URL
	target, err := url.Parse(targetURL)
	if err != nil {
		p.logger.Error("Invalid target URL", zap.String("url", targetURL), zap.Error(err))
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// 保持完整的API路径
	target.Path = r.URL.Path
	target.RawQuery = r.URL.RawQuery

	// 读取请求体
	var body []byte
	if r.Body != nil {
		body, err = io.ReadAll(r.Body)
		if err != nil {
			p.logger.Error("Failed to read request body", zap.Error(err))
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}
		r.Body.Close()
	}

	// 创建新的请求
	req, err := http.NewRequest(r.Method, target.String(), bytes.NewReader(body))
	if err != nil {
		p.logger.Error("Failed to create request", zap.Error(err))
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// 复制请求头
	for key, values := range r.Header {
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}

	// 添加用户信息到请求头（如果存在）
	if userID := r.Context().Value("user_id"); userID != nil {
		req.Header.Set("X-User-ID", userID.(string))
	}
	if email := r.Context().Value("email"); email != nil {
		req.Header.Set("X-User-Email", email.(string))
	}

	// 发送请求
	resp, err := p.client.Do(req)
	if err != nil {
		p.logger.Error("Failed to proxy request",
			zap.String("service", serviceName),
			zap.String("url", target.String()),
			zap.Error(err),
		)
		http.Error(w, "Service unavailable", http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()

	// 复制响应头
	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	// 设置状态码
	w.WriteHeader(resp.StatusCode)

	// 复制响应体
	if _, err := io.Copy(w, resp.Body); err != nil {
		p.logger.Error("Failed to copy response body", zap.Error(err))
	}

	p.logger.Debug("Request proxied successfully",
		zap.String("service", serviceName),
		zap.String("method", r.Method),
		zap.String("path", r.URL.Path),
		zap.Int("status", resp.StatusCode),
	)
}

func (p *ProxyService) HealthCheck() map[string]bool {
	result := make(map[string]bool)

	// 定义每个服务的健康检查路径
	healthPaths := map[string]string{
		"users":         "/api/v1/users/register", // 用户服务没有健康检查端点，使用注册端点测试
		"groups":        "/api/v1/health",
		"messages":      "/health",
		"media":         "/api/v1/media/health",
		"notifications": "/health",
	}

	for serviceName, serviceURL := range p.services {
		healthPath, exists := healthPaths[serviceName]
		if !exists {
			healthPath = "/health" // 默认路径
		}
		
		var resp *http.Response
		var err error
		
		if serviceName == "users" {
			// 对于用户服务，使用HEAD请求测试连接性
			resp, err = p.client.Head(serviceURL + healthPath)
		} else {
			resp, err = p.client.Get(serviceURL + healthPath)
		}
		
		if err != nil {
			result[serviceName] = false
			continue
		}
		resp.Body.Close()
		result[serviceName] = resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusMethodNotAllowed
	}

	return result
}
