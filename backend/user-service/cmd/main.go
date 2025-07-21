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

	"github.com/yourusername/chatapp/user-service/config"
	"github.com/yourusername/chatapp/user-service/internal/delivery/http"
	"github.com/yourusername/chatapp/user-service/internal/repository"
	"github.com/yourusername/chatapp/user-service/internal/service"
	"github.com/yourusername/chatapp/user-service/pkg/auth"
	"github.com/yourusername/chatapp/user-service/pkg/logger"
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

	// 初始化数据库连接
	db, err := repository.NewPostgresDB(cfg.DB)
	if err != nil {
		logger.Fatal("Failed to initialize database", zap.Error(err))
	}
	defer db.Close()

	// 初始化仓库
	userRepo := repository.NewUserRepository(db)

	// 初始化JWT管理器
	jwtManager := auth.NewJWTManager(cfg.JWT.SecretKey, cfg.JWT.ExpirationHours)

	// 初始化服务
	userService := service.NewUserService(userRepo, jwtManager, logger)

	// 初始化HTTP处理器
	userHandler := httpdelivery.NewUserHandler(userService, jwtManager, logger)

	// 初始化路由
	router := mux.NewRouter()
	userHandler.RegisterRoutes(router)

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.HTTPPort),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	// 启动HTTP服务器
	go func() {
		logger.Info("Starting HTTP server", zap.Int("port", cfg.HTTPPort))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start HTTP server", zap.Error(err))
		}
	}()

	// 优雅关闭
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server exited properly")
}