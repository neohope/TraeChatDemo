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
	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	"media-service/config"
	"media-service/internal/handlers"
	"media-service/internal/repository"
	"media-service/internal/service"
	"media-service/internal/storage"
	"media-service/pkg/auth"
)

func main() {
	// 加载环境变量
	if err := godotenv.Load(); err != nil {
		fmt.Printf("Warning: .env file not found: %v\n", err)
	}

	// 初始化配置
	cfg := config.Load()

	// 初始化日志
	logger := initLogger(cfg.Log.Level)
	defer logger.Sync()

	logger.Info("Starting media service",
		zap.String("version", "1.0.0"),
		zap.String("port", fmt.Sprintf("%d", cfg.Server.Port)),
		zap.String("storage_provider", cfg.Storage.Provider),
	)

	// 初始化数据库
	var db *sqlx.DB
	var err error
	if cfg.Database.Host != "" {
		db, err = initDatabase(cfg, logger)
		if err != nil {
			logger.Error("Failed to connect to database, using memory storage", zap.Error(err))
		}
	} else {
		logger.Info("No database configuration found, using memory storage")
	}

	// 初始化仓库
	var mediaRepo repository.MediaRepository
	if db != nil {
		mediaRepo = repository.NewPostgreSQLMediaRepository(db, logger)
		logger.Info("Using PostgreSQL repository")
	} else {
		mediaRepo = repository.NewMemoryMediaRepository(logger)
		logger.Info("Using memory repository")
	}

	// 初始化存储提供者
	storageProvider, err := storage.NewStorageProvider(cfg, logger)
	if err != nil {
		logger.Fatal("Failed to initialize storage provider", zap.Error(err))
	}
	logger.Info("Storage provider initialized", zap.String("provider", cfg.Storage.Provider))

	// 初始化JWT管理器
	auth.InitJWT(cfg.JWT.SecretKey, time.Duration(cfg.JWT.ExpirationHours)*time.Hour, logger)

	// 初始化服务
	mediaService := service.NewMediaService(mediaRepo, storageProvider, cfg, logger)

	// 初始化处理器
	mediaHandler := handlers.NewMediaHandler(mediaService, logger)

	// 初始化路由
	router := mux.NewRouter()

	// 添加中间件
	// CORS中间件已移除，由API网关统一处理
	router.Use(auth.LoggingMiddleware(logger))

	// 注册路由
	mediaHandler.RegisterRoutes(router)

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Server.Port),
		Handler:      router,
		ReadTimeout:  time.Duration(cfg.Server.ReadTimeout) * time.Second,
		WriteTimeout: time.Duration(cfg.Server.WriteTimeout) * time.Second,
		IdleTimeout:  time.Duration(cfg.Server.IdleTimeout) * time.Second,
	}

	// 启动服务器
	go func() {
		logger.Info("Media service started", zap.String("address", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// 启动清理任务
	go startCleanupTasks(mediaService, logger)

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down media service...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("Server forced to shutdown", zap.Error(err))
	} else {
		logger.Info("Media service stopped gracefully")
	}

	// 关闭数据库连接
	if db != nil {
		db.Close()
	}
}

// initLogger 初始化日志
func initLogger(level string) *zap.Logger {
	var zapLevel zapcore.Level
	switch level {
	case "debug":
		zapLevel = zapcore.DebugLevel
	case "info":
		zapLevel = zapcore.InfoLevel
	case "warn":
		zapLevel = zapcore.WarnLevel
	case "error":
		zapLevel = zapcore.ErrorLevel
	default:
		zapLevel = zapcore.InfoLevel
	}

	config := zap.Config{
		Level:       zap.NewAtomicLevelAt(zapLevel),
		Development: false,
		Sampling: &zap.SamplingConfig{
			Initial:    100,
			Thereafter: 100,
		},
		Encoding: "json",
		EncoderConfig: zapcore.EncoderConfig{
			TimeKey:        "timestamp",
			LevelKey:       "level",
			NameKey:        "logger",
			CallerKey:      "caller",
			FunctionKey:    zapcore.OmitKey,
			MessageKey:     "message",
			StacktraceKey:  "stacktrace",
			LineEnding:     zapcore.DefaultLineEnding,
			EncodeLevel:    zapcore.LowercaseLevelEncoder,
			EncodeTime:     zapcore.ISO8601TimeEncoder,
			EncodeDuration: zapcore.SecondsDurationEncoder,
			EncodeCaller:   zapcore.ShortCallerEncoder,
		},
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
	}

	logger, err := config.Build()
	if err != nil {
		panic(fmt.Sprintf("Failed to initialize logger: %v", err))
	}

	return logger
}

// initDatabase 初始化数据库连接
func initDatabase(cfg *config.Config, logger *zap.Logger) (*sqlx.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.DBName,
		cfg.Database.SSLMode,
	)

	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// 设置连接池参数
	db.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	db.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	db.SetConnMaxLifetime(time.Duration(cfg.Database.ConnMaxLifetime) * time.Minute)

	// 测试连接
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// 运行数据库迁移
	if err := runMigrations(db, logger); err != nil {
		logger.Warn("Failed to run database migrations", zap.Error(err))
	}

	logger.Info("Database connected successfully")
	return db, nil
}

// runMigrations 运行数据库迁移
func runMigrations(db *sqlx.DB, logger *zap.Logger) error {
	migrations := []string{
		// 媒体文件表
		`CREATE TABLE IF NOT EXISTS media_files (
			id VARCHAR(36) PRIMARY KEY,
			user_id VARCHAR(36) NOT NULL,
			filename VARCHAR(255) NOT NULL,
			original_name VARCHAR(255) NOT NULL,
			mime_type VARCHAR(100) NOT NULL,
			file_size BIGINT NOT NULL,
			media_type VARCHAR(20) NOT NULL,
			status VARCHAR(20) NOT NULL DEFAULT 'uploaded',
			storage_path TEXT NOT NULL,
			public_url TEXT,
			thumbnail_url TEXT,
			metadata JSONB,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			expires_at TIMESTAMP WITH TIME ZONE
		)`,
		
		// 处理任务表
		`CREATE TABLE IF NOT EXISTS processing_jobs (
			id VARCHAR(36) PRIMARY KEY,
			media_id VARCHAR(36) NOT NULL REFERENCES media_files(id) ON DELETE CASCADE,
			job_type VARCHAR(50) NOT NULL,
			status VARCHAR(20) NOT NULL DEFAULT 'pending',
			params JSONB,
			result JSONB,
			error TEXT,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			started_at TIMESTAMP WITH TIME ZONE,
			completed_at TIMESTAMP WITH TIME ZONE
		)`,
		
		// 用户存储配额表
		`CREATE TABLE IF NOT EXISTS user_storage_quotas (
			user_id VARCHAR(36) PRIMARY KEY,
			total_quota BIGINT NOT NULL DEFAULT 1073741824, -- 1GB
			used_quota BIGINT NOT NULL DEFAULT 0,
			file_count INTEGER NOT NULL DEFAULT 0,
			max_file_size BIGINT NOT NULL DEFAULT 104857600, -- 100MB
			max_file_count INTEGER NOT NULL DEFAULT 1000,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		)`,
		
		// 创建索引
		`CREATE INDEX IF NOT EXISTS idx_media_files_user_id ON media_files(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_media_files_status ON media_files(status)`,
		`CREATE INDEX IF NOT EXISTS idx_media_files_media_type ON media_files(media_type)`,
		`CREATE INDEX IF NOT EXISTS idx_media_files_created_at ON media_files(created_at)`,
		`CREATE INDEX IF NOT EXISTS idx_media_files_expires_at ON media_files(expires_at)`,
		`CREATE INDEX IF NOT EXISTS idx_processing_jobs_status ON processing_jobs(status)`,
		`CREATE INDEX IF NOT EXISTS idx_processing_jobs_media_id ON processing_jobs(media_id)`,
	}

	for i, migration := range migrations {
		if _, err := db.Exec(migration); err != nil {
			return fmt.Errorf("failed to run migration %d: %w", i+1, err)
		}
	}

	logger.Info("Database migrations completed successfully")
	return nil
}

// startCleanupTasks 启动清理任务
func startCleanupTasks(mediaService service.MediaService, logger *zap.Logger) {
	ticker := time.NewTicker(1 * time.Hour) // 每小时运行一次
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			logger.Info("Running cleanup tasks")
			
			// 清理过期文件
			if err := mediaService.CleanupExpiredFiles(); err != nil {
				logger.Error("Failed to cleanup expired files", zap.Error(err))
			} else {
				logger.Info("Expired files cleanup completed")
			}
		}
	}
}