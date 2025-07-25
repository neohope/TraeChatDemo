package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"github.com/neohope/chatapp/notification-service/config"
	handlers "github.com/neohope/chatapp/notification-service/internal/delivery/http"
	"github.com/neohope/chatapp/notification-service/internal/repository"
	"github.com/neohope/chatapp/notification-service/internal/service"
	"github.com/neohope/chatapp/notification-service/pkg/logger"
)

func main() {
	// 加载配置
	cfg, err := config.LoadConfig()
	if err != nil {
		panic("Failed to load config: " + err.Error())
	}

	// 初始化日志
	log, err := logger.NewLogger(cfg.LogLevel)
	if err != nil {
		panic("Failed to initialize logger: " + err.Error())
	}
	defer log.Sync()

	log.Info("Starting notification service", zap.Int("port", cfg.HTTPPort))

	// 初始化存储库
	notificationRepo := repository.NewMemoryNotificationRepository()
	userDeviceRepo := repository.NewMemoryUserDeviceRepository()
	notificationPreferenceRepo := repository.NewMemoryNotificationPreferenceRepository()

	// 初始化推送服务
	pushService := service.NewPushService(
		userDeviceRepo,
		&cfg.PushNotification,
		log,
	)

	// 初始化通知服务
	notificationService := service.NewNotificationService(
		notificationRepo,
		userDeviceRepo,
		notificationPreferenceRepo,
		pushService,
		log,
	)

	// 初始化HTTP处理器
	handler := handlers.NewHandler(notificationService, log)

	// 设置路由
	router := mux.NewRouter()
	handler.RegisterRoutes(router)

	// 添加CORS中间件
	router.Use(corsMiddleware)

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:         ":" + strconv.Itoa(cfg.HTTPPort),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 启动服务器
	go func() {
		log.Info("Server starting", zap.String("address", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("Server failed to start", zap.Error(err))
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Server shutting down...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown", zap.Error(err))
	}

	log.Info("Server exited")
}

// CORS中间件
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-User-ID")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
