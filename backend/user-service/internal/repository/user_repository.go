package repository

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/neohope/chatapp/user-service/internal/domain"
)

// UserRepository 实现domain.UserRepository接口
type UserRepository struct {
	db *sqlx.DB
}

// NewUserRepository 创建一个新的用户仓库
func NewUserRepository(db *sqlx.DB) domain.UserRepository {
	return &UserRepository{db: db}
}

// Create 创建新用户
func (r *UserRepository) Create(ctx context.Context, user *domain.User) error {
	// 生成UUID
	if user.ID == "" {
		user.ID = uuid.New().String()
	}

	// 设置时间戳
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	// 插入用户记录
	query := `
	INSERT INTO users (id, username, email, password, full_name, avatar_url, status, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`

	_, err := r.db.ExecContext(
		ctx,
		query,
		user.ID,
		user.Username,
		user.Email,
		user.Password,
		user.FullName,
		user.AvatarURL,
		user.Status,
		user.CreatedAt,
		user.UpdatedAt,
	)

	return err
}

// GetByID 通过ID获取用户
func (r *UserRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
	var user domain.User

	query := `
	SELECT id, username, email, password, full_name, avatar_url, status, created_at, updated_at
	FROM users
	WHERE id = $1
	`

	err := r.db.GetContext(ctx, &user, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

// GetByEmail 通过邮箱获取用户
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	var user domain.User

	query := `
	SELECT id, username, email, password, full_name, avatar_url, status, created_at, updated_at
	FROM users
	WHERE email = $1
	`

	// 添加调试日志
	var count int
	countQuery := "SELECT COUNT(*) FROM users WHERE email = $1"
	r.db.GetContext(ctx, &count, countQuery, email)
	
	err := r.db.GetContext(ctx, &user, query, email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

// GetByUsername 通过用户名获取用户
func (r *UserRepository) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	var user domain.User

	query := `
	SELECT id, username, email, password, full_name, avatar_url, status, created_at, updated_at
	FROM users
	WHERE username = $1
	`

	err := r.db.GetContext(ctx, &user, query, username)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

// Update 更新用户信息
func (r *UserRepository) Update(ctx context.Context, user *domain.User) error {
	// 更新时间戳
	user.UpdatedAt = time.Now()

	query := `
	UPDATE users
	SET username = $1, email = $2, password = $3, full_name = $4, avatar_url = $5, status = $6, updated_at = $7
	WHERE id = $8
	`

	_, err := r.db.ExecContext(
		ctx,
		query,
		user.Username,
		user.Email,
		user.Password,
		user.FullName,
		user.AvatarURL,
		user.Status,
		user.UpdatedAt,
		user.ID,
	)

	return err
}

// Delete 删除用户
func (r *UserRepository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM users WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// List 获取用户列表
func (r *UserRepository) List(ctx context.Context, limit, offset int) ([]*domain.User, error) {
	var users []*domain.User

	query := `
	SELECT id, username, email, password, full_name, avatar_url, status, created_at, updated_at
	FROM users
	ORDER BY created_at DESC
	LIMIT $1 OFFSET $2
	`

	err := r.db.SelectContext(ctx, &users, query, limit, offset)
	if err != nil {
		return nil, err
	}

	return users, nil
}
