package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/yourusername/chatapp/message-service/config"
	httpdelivery "github.com/yourusername/chatapp/message-service/internal/delivery/http"
	"github.com/yourusername/chatapp/message-service/internal/repository"
	"github.com/yourusername/chatapp/message-service/internal/service"
	"github.com/yourusername/chatapp/message-service/pkg/auth"
	"github.com/yourusername/chatapp/message-service/pkg/logger"
	"go.uber.org/zap"
)

func main() {
	// 加载配置
	cfg, err := config.LoadConfig()
	if err != nil {
		fmt.Printf("Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// 初始化日志
	log, err := logger.NewLogger(cfg.Service.LogLevel)
	if err != nil {
		fmt.Printf("Failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync(log)

	log.Info("Starting message service",
		zap.Int("http_port", cfg.Service.HTTPPort),
		zap.Int("grpc_port", cfg.Service.GRPCPort),
		zap.String("log_level", cfg.Service.LogLevel),
	)

	// 连接数据库
	db, err := repository.NewPostgresDB(cfg.GetPostgresConnString(), log)
	if err != nil {
		log.Fatal("Failed to connect to database", zap.Error(err))
	}

	// 初始化JWT管理器
	jwtManager := auth.NewJWTManager(cfg.JWT.SecretKey, cfg.JWT.ExpirationHours)

	// 初始化仓库
	messageRepo := repository.NewMessageRepository(db, log)

	// 初始化服务
	messageService := service.NewMessageService(messageRepo, log)

	// 初始化HTTP处理器
	messageHandler := httpdelivery.NewMessageHandler(messageService, jwtManager, log)

	// 创建路由
	router := mux.NewRouter()
	messageHandler.RegisterRoutes(router)

	// 创建HTTP服务器
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Service.HTTPPort),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 启动HTTP服务器
	go func() {
		log.Info("Starting HTTP server", zap.String("address", server.Addr))
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("Failed to start HTTP server", zap.Error(err))
		}
	}()

	// 优雅关闭
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	sig := <-sigChan
	log.Info("Received signal", zap.String("signal", sig.String()))

	// 创建关闭上下文
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 关闭HTTP服务器
	if err := server.Shutdown(ctx); err != nil {
		log.Error("Server shutdown failed", zap.Error(err))
	}

	log.Info("Server gracefully stopped")
}