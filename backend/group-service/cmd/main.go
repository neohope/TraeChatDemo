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
	"github.com/yourusername/chatapp/group-service/config"
	"github.com/yourusername/chatapp/group-service/internal/database"
	"github.com/yourusername/chatapp/group-service/internal/handler"
	"github.com/yourusername/chatapp/group-service/internal/repository"
	"github.com/yourusername/chatapp/group-service/internal/service"
	"github.com/yourusername/chatapp/group-service/pkg/jwt"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func main() {
	// 初始化日志
	logger, err := initLogger()
	if err != nil {
		fmt.Printf("Failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync()

	logger.Info("Starting Group Service...")

	// 加载配置
	cfg, err := config.LoadConfig()
	if err != nil {
		logger.Fatal("Failed to load config", zap.Error(err))
	}

	logger.Info("Configuration loaded", 
		zap.Int("http_port", cfg.HTTPPort),
		zap.String("log_level", cfg.LogLevel),
		zap.String("db_host", cfg.Database.Host),
	)

	// 初始化数据库
	db, err := initDatabase(cfg, logger)
	if err != nil {
		logger.Fatal("Failed to initialize database", zap.Error(err))
	}
	defer db.Close()

	// 初始化JWT管理器
	jwtManager := jwt.NewJWTManager(cfg.JWT.SecretKey, cfg.JWT.ExpirationHours)

	// 初始化仓库
	var groupRepo repository.GroupRepository
	if db.GetDB() != nil {
		groupRepo = repository.NewPostgreSQLGroupRepository(db.GetDB())
		logger.Info("Using PostgreSQL repository")
	} else {
		groupRepo = repository.NewMemoryGroupRepository()
		logger.Info("Using memory repository")
	}

	// 初始化服务
	groupService := service.NewGroupService(groupRepo, logger)

	// 初始化处理器
	groupHandler := handler.NewGroupHandler(groupService, jwtManager, logger)

	// 初始化路由
	router := mux.NewRouter()
	setupRoutes(router, groupHandler)

	// 启动HTTP服务器
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.HTTPPort),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 启动清理任务
	if db.GetDB() != nil {
		startCleanupTasks(db, logger)
	}

	// 优雅关闭
	go func() {
		logger.Info("Group Service started", zap.Int("port", cfg.HTTPPort))
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down Group Service...")

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Server forced to shutdown", zap.Error(err))
	} else {
		logger.Info("Group Service stopped gracefully")
	}
}

// initLogger 初始化日志
func initLogger() (*zap.Logger, error) {
	config := zap.NewProductionConfig()
	config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
	config.OutputPaths = []string{"stdout"}
	config.ErrorOutputPaths = []string{"stderr"}
	config.EncoderConfig.TimeKey = "timestamp"
	config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder

	return config.Build()
}

// initDatabase 初始化数据库
func initDatabase(cfg *config.Config, logger *zap.Logger) (*database.Database, error) {
	db, err := database.NewDatabase(cfg, logger)
	if err != nil {
		logger.Warn("Failed to connect to PostgreSQL, using memory storage", zap.Error(err))
		return &database.Database{}, nil // 返回空的数据库实例，使用内存存储
	}

	// 验证数据库模式
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := db.ValidateSchema(ctx); err != nil {
		logger.Info("Database schema validation failed, running migrations", zap.Error(err))
		if err := db.RunMigrations(); err != nil {
			logger.Error("Failed to run migrations", zap.Error(err))
			return nil, err
		}
	}

	// 清理过期邀请
	if count, err := db.CleanupExpiredInvitations(ctx); err != nil {
		logger.Warn("Failed to cleanup expired invitations", zap.Error(err))
	} else if count > 0 {
		logger.Info("Cleaned up expired invitations on startup", zap.Int("count", count))
	}

	return db, nil
}

// setupRoutes 设置路由
func setupRoutes(router *mux.Router, groupHandler *handler.GroupHandler) {
	// API版本前缀
	api := router.PathPrefix("/api/v1").Subrouter()

	// 添加CORS中间件
	api.Use(corsMiddleware)

	// 添加日志中间件
	api.Use(loggingMiddleware)

	// 注册群组处理器路由
	groupHandler.RegisterRoutes(api)

	// 根路径重定向到健康检查
	router.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/api/v1/health", http.StatusMovedPermanently)
	})
}

// corsMiddleware CORS中间件
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// loggingMiddleware 日志中间件
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// 创建响应写入器包装器以捕获状态码
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		duration := time.Since(start)

		// 只记录非健康检查的请求
		if r.URL.Path != "/api/v1/health" {
			fmt.Printf("%s %s %d %v\n", r.Method, r.URL.Path, wrapped.statusCode, duration)
		}
	})
}

// responseWriter 响应写入器包装器
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// startCleanupTasks 启动清理任务
func startCleanupTasks(db *database.Database, logger *zap.Logger) {
	// 每小时清理一次过期邀请
	ticker := time.NewTicker(1 * time.Hour)
	go func() {
		for range ticker.C {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			if count, err := db.CleanupExpiredInvitations(ctx); err != nil {
				logger.Error("Failed to cleanup expired invitations", zap.Error(err))
			} else if count > 0 {
				logger.Info("Cleaned up expired invitations", zap.Int("count", count))
			}
			cancel()
		}
	}()

	logger.Info("Cleanup tasks started")
}