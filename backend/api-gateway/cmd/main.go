package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"github.com/neohope/chatapp/api-gateway/config"
	"github.com/neohope/chatapp/api-gateway/internal/delivery"
	httpdelivery "github.com/neohope/chatapp/api-gateway/internal/delivery/http"
	"github.com/neohope/chatapp/api-gateway/internal/service"
	"github.com/neohope/chatapp/api-gateway/pkg/auth"
	"github.com/neohope/chatapp/api-gateway/pkg/logger"
)

func main() {
	// 初始化配置
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 初始化日志
	logger, err := logger.NewLogger(cfg.LogLevel)
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer logger.Sync()

	logger.Info("Starting API Gateway",
		zap.Int("port", cfg.HTTPPort),
		zap.String("log_level", cfg.LogLevel),
	)

	// 初始化JWT管理器
	jwtManager := auth.NewJWTManager(cfg.JWT.SecretKey)

	// 初始化中间件
	middleware := delivery.NewMiddleware(jwtManager, logger, cfg.RateLimit.Enabled, cfg.RateLimit.RPS)

	// 初始化代理服务
	proxyService := service.NewProxyService(&cfg.Services, logger)

	// 初始化HTTP处理器
	handler := httpdelivery.NewHandler(proxyService, middleware, logger)

	// 初始化路由
	router := mux.NewRouter()
	handler.RegisterRoutes(router, struct {
		AllowedOrigins []string
		AllowedMethods []string
		AllowedHeaders []string
	}{
		AllowedOrigins: cfg.CORS.AllowedOrigins,
		AllowedMethods: cfg.CORS.AllowedMethods,
		AllowedHeaders: cfg.CORS.AllowedHeaders,
	})

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.HTTPPort),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 启动HTTP服务器
	go func() {
		logger.Info("Starting HTTP server", zap.Int("port", cfg.HTTPPort))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start HTTP server", zap.Error(err))
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server exited properly")
}
