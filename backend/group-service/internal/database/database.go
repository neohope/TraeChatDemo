package database

import (
	"context"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/yourusername/chatapp/group-service/config"
	"go.uber.org/zap"
)

// Database 数据库管理器
type Database struct {
	db     *sqlx.DB
	logger *zap.Logger
}

// NewDatabase 创建数据库管理器
func NewDatabase(cfg *config.Config, logger *zap.Logger) (*Database, error) {
	db, err := sqlx.Connect("postgres", cfg.GetPostgresConnString())
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// 配置连接池
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// 测试连接
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	database := &Database{
		db:     db,
		logger: logger,
	}

	logger.Info("Database connection established successfully")
	return database, nil
}

// GetDB 获取数据库连接
func (d *Database) GetDB() *sqlx.DB {
	return d.db
}

// Close 关闭数据库连接
func (d *Database) Close() error {
	if d.db != nil {
		return d.db.Close()
	}
	return nil
}

// RunMigrations 运行数据库迁移
func (d *Database) RunMigrations() error {
	d.logger.Info("Running database migrations...")

	// 读取迁移文件
	migrationPath := filepath.Join("internal", "database", "migrations.sql")
	migrationSQL, err := ioutil.ReadFile(migrationPath)
	if err != nil {
		d.logger.Error("Failed to read migration file", zap.Error(err))
		return fmt.Errorf("failed to read migration file: %w", err)
	}

	// 执行迁移
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if _, err := d.db.ExecContext(ctx, string(migrationSQL)); err != nil {
		d.logger.Error("Failed to run migrations", zap.Error(err))
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	d.logger.Info("Database migrations completed successfully")
	return nil
}

// HealthCheck 数据库健康检查
func (d *Database) HealthCheck(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var result int
	if err := d.db.GetContext(ctx, &result, "SELECT 1"); err != nil {
		return fmt.Errorf("database health check failed: %w", err)
	}

	return nil
}

// GetStats 获取数据库连接统计信息
func (d *Database) GetStats() map[string]interface{} {
	stats := d.db.Stats()
	return map[string]interface{}{
		"max_open_connections":     stats.MaxOpenConnections,
		"open_connections":         stats.OpenConnections,
		"in_use":                   stats.InUse,
		"idle":                     stats.Idle,
		"wait_count":               stats.WaitCount,
		"wait_duration":            stats.WaitDuration.String(),
		"max_idle_closed":          stats.MaxIdleClosed,
		"max_idle_time_closed":     stats.MaxIdleTimeClosed,
		"max_lifetime_closed":      stats.MaxLifetimeClosed,
	}
}

// BeginTx 开始事务
func (d *Database) BeginTx(ctx context.Context) (*sqlx.Tx, error) {
	return d.db.BeginTxx(ctx, nil)
}

// WithTransaction 在事务中执行函数
func (d *Database) WithTransaction(ctx context.Context, fn func(*sqlx.Tx) error) error {
	tx, err := d.BeginTx(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		}
	}()

	if err := fn(tx); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit()
}

// CleanupExpiredInvitations 清理过期邀请
func (d *Database) CleanupExpiredInvitations(ctx context.Context) (int, error) {
	var affectedRows int
	query := `SELECT cleanup_expired_invitations()`

	if err := d.db.GetContext(ctx, &affectedRows, query); err != nil {
		d.logger.Error("Failed to cleanup expired invitations", zap.Error(err))
		return 0, fmt.Errorf("failed to cleanup expired invitations: %w", err)
	}

	if affectedRows > 0 {
		d.logger.Info("Cleaned up expired invitations", zap.Int("count", affectedRows))
	}

	return affectedRows, nil
}

// GetGroupStats 获取群组统计信息
func (d *Database) GetGroupStats(ctx context.Context, groupID string) (map[string]interface{}, error) {
	query := `SELECT * FROM get_group_stats($1)`
	rows, err := d.db.QueryContext(ctx, query, groupID)
	if err != nil {
		return nil, fmt.Errorf("failed to get group stats: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, fmt.Errorf("group not found")
	}

	var totalMembers, activeMembers, adminCount int
	var ownerID string
	if err := rows.Scan(&totalMembers, &activeMembers, &adminCount, &ownerID); err != nil {
		return nil, fmt.Errorf("failed to scan group stats: %w", err)
	}

	return map[string]interface{}{
		"total_members":  totalMembers,
		"active_members": activeMembers,
		"admin_count":    adminCount,
		"owner_id":       ownerID,
	}, nil
}

// ValidateSchema 验证数据库模式
func (d *Database) ValidateSchema(ctx context.Context) error {
	requiredTables := []string{"groups", "group_members", "group_invitations"}

	for _, table := range requiredTables {
		var exists bool
		query := `
			SELECT EXISTS (
				SELECT FROM information_schema.tables 
				WHERE table_schema = 'public' 
				AND table_name = $1
			)
		`
		if err := d.db.GetContext(ctx, &exists, query, table); err != nil {
			return fmt.Errorf("failed to check table %s: %w", table, err)
		}
		if !exists {
			return fmt.Errorf("required table %s does not exist", table)
		}
	}

	d.logger.Info("Database schema validation passed")
	return nil
}