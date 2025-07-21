package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq" // PostgreSQL驱动
	"go.uber.org/zap"
)

// NewPostgresDB 创建一个新的PostgreSQL数据库连接
func NewPostgresDB(connStr string, logger *zap.Logger) (*sqlx.DB, error) {
	db, err := sqlx.Connect("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// 设置连接池参数
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// 测试连接
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// 初始化数据库表
	if err := initDB(db, logger); err != nil {
		return nil, fmt.Errorf("failed to initialize database: %w", err)
	}

	logger.Info("Successfully connected to PostgreSQL database")
	return db, nil
}

// initDB 初始化数据库表
func initDB(db *sqlx.DB, logger *zap.Logger) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// 创建消息表
	messagesTable := `
	CREATE TABLE IF NOT EXISTS messages (
		id UUID PRIMARY KEY,
		conversation_id UUID NOT NULL,
		sender_id UUID NOT NULL,
		type VARCHAR(20) NOT NULL,
		content TEXT NOT NULL,
		metadata JSONB,
		status VARCHAR(20) NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE NOT NULL,
		updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
		is_group_chat BOOLEAN NOT NULL DEFAULT FALSE
	);
	CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
	CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
	CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
	`

	// 创建会话表
	conversationsTable := `
	CREATE TABLE IF NOT EXISTS conversations (
		id UUID PRIMARY KEY,
		type VARCHAR(20) NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE NOT NULL,
		updated_at TIMESTAMP WITH TIME ZONE NOT NULL
	);
	`

	// 创建会话参与者表
	participantsTable := `
	CREATE TABLE IF NOT EXISTS conversation_participants (
		conversation_id UUID NOT NULL,
		user_id UUID NOT NULL,
		joined_at TIMESTAMP WITH TIME ZONE NOT NULL,
		PRIMARY KEY (conversation_id, user_id),
		FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
	);
	CREATE INDEX IF NOT EXISTS idx_participants_user_id ON conversation_participants(user_id);
	`

	// 执行SQL语句
	queries := []string{messagesTable, conversationsTable, participantsTable}
	for _, query := range queries {
		_, err := db.ExecContext(ctx, query)
		if err != nil {
			return fmt.Errorf("failed to execute query: %w\nQuery: %s", err, query)
		}
	}

	logger.Info("Database tables initialized successfully")
	return nil
}