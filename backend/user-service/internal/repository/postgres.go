package repository

import (
	"fmt"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq" // PostgreSQL驱动

	"github.com/neohope/chatapp/user-service/config"
)

// NewPostgresDB 创建一个新的PostgreSQL数据库连接
func NewPostgresDB(cfg config.DatabaseConfig) (*sqlx.DB, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.Username, cfg.Password, cfg.DBName, cfg.SSLMode)

	db, err := sqlx.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	// 设置连接池参数
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	// 验证连接
	if err := db.Ping(); err != nil {
		return nil, err
	}

	// 初始化数据库表
	if err := initDB(db); err != nil {
		return nil, err
	}

	return db, nil
}

// initDB 初始化数据库表
func initDB(db *sqlx.DB) error {
	// 创建用户表
	userQuery := `
	CREATE TABLE IF NOT EXISTS users (
		id UUID PRIMARY KEY,
		username VARCHAR(50) UNIQUE NOT NULL,
		email VARCHAR(100) UNIQUE NOT NULL,
		password VARCHAR(100) NOT NULL,
		full_name VARCHAR(100) NOT NULL,
		avatar_url TEXT,
		status VARCHAR(20) NOT NULL DEFAULT 'active',
		created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
		updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
	);
	`

	_, err := db.Exec(userQuery)
	if err != nil {
		return err
	}

	// 创建好友请求表
	friendRequestQuery := `
	CREATE TABLE IF NOT EXISTS friend_requests (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		message TEXT,
		status VARCHAR(20) NOT NULL DEFAULT 'pending',
		created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
		updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
		UNIQUE(from_user_id, to_user_id)
	);
	`

	_, err = db.Exec(friendRequestQuery)
	if err != nil {
		return err
	}

	// 创建好友关系表
	friendshipQuery := `
	CREATE TABLE IF NOT EXISTS friendships (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
		UNIQUE(user1_id, user2_id),
		CHECK(user1_id < user2_id)
	);
	`

	_, err = db.Exec(friendshipQuery)
	if err != nil {
		return err
	}

	// 创建索引以提高查询性能
	indexQueries := []string{
		`CREATE INDEX IF NOT EXISTS idx_friend_requests_from_user ON friend_requests(from_user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_friend_requests_to_user ON friend_requests(to_user_id);`,
		`CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);`,
		`CREATE INDEX IF NOT EXISTS idx_friendships_user1 ON friendships(user1_id);`,
		`CREATE INDEX IF NOT EXISTS idx_friendships_user2 ON friendships(user2_id);`,
	}

	for _, indexQuery := range indexQueries {
		_, err = db.Exec(indexQuery)
		if err != nil {
			return err
		}
	}

	return nil
}
