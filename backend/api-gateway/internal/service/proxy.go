package service

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
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

	// 移除服务前缀，构建新的路径
	path := strings.TrimPrefix(r.URL.Path, fmt.Sprintf("/api/v1/%s", serviceName))
	if path == "" {
		path = "/"
	}
	target.Path = path
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

	for serviceName, serviceURL := range p.services {
		resp, err := p.client.Get(serviceURL + "/health")
		if err != nil {
			result[serviceName] = false
			continue
		}
		resp.Body.Close()
		result[serviceName] = resp.StatusCode == http.StatusOK
	}

	return result
}
