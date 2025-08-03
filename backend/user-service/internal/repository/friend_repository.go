package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/neohope/chatapp/user-service/internal/domain"
)

// FriendRepository 实现domain.FriendRepository接口
type FriendRepository struct {
	db *sqlx.DB
}

// NewFriendRepository 创建一个新的好友仓库
func NewFriendRepository(db *sqlx.DB) domain.FriendRepository {
	return &FriendRepository{db: db}
}

// CreateFriendRequest 创建好友请求
func (r *FriendRepository) CreateFriendRequest(ctx context.Context, request *domain.FriendRequest) error {
	// 生成UUID
	if request.ID == "" {
		request.ID = uuid.New().String()
	}

	// 设置时间戳
	now := time.Now()
	request.CreatedAt = now
	request.UpdatedAt = now

	// 插入好友请求记录
	query := `
	INSERT INTO friend_requests (id, from_user_id, to_user_id, message, status, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err := r.db.ExecContext(
		ctx,
		query,
		request.ID,
		request.FromUserID,
		request.ToUserID,
		request.Message,
		request.Status,
		request.CreatedAt,
		request.UpdatedAt,
	)

	return err
}

// GetFriendRequestByID 根据ID获取好友请求
func (r *FriendRepository) GetFriendRequestByID(ctx context.Context, id string) (*domain.FriendRequest, error) {
	var request domain.FriendRequest

	query := `
	SELECT id, from_user_id, to_user_id, message, status, created_at, updated_at
	FROM friend_requests
	WHERE id = $1
	`

	err := r.db.GetContext(ctx, &request, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &request, nil
}

// GetPendingFriendRequests 获取待处理的好友请求
func (r *FriendRepository) GetPendingFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequest, error) {
	var requests []*domain.FriendRequest

	query := `
	SELECT 
		fr.id, fr.from_user_id, fr.to_user_id, fr.message, fr.status, fr.created_at, fr.updated_at,
		u.id as "from_user.id", u.username as "from_user.username", u.email as "from_user.email",
		u.full_name as "from_user.full_name", u.avatar_url as "from_user.avatar_url", u.status as "from_user.status",
		u.created_at as "from_user.created_at", u.updated_at as "from_user.updated_at"
	FROM friend_requests fr
	JOIN users u ON fr.from_user_id = u.id
	WHERE fr.to_user_id = $1 AND fr.status = 'pending'
	ORDER BY fr.created_at DESC
	`

	rows, err := r.db.QueryxContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var request domain.FriendRequest
		var fromUser domain.User
		
		err := rows.Scan(
			&request.ID, &request.FromUserID, &request.ToUserID, &request.Message, &request.Status, &request.CreatedAt, &request.UpdatedAt,
			&fromUser.ID, &fromUser.Username, &fromUser.Email, &fromUser.FullName, &fromUser.AvatarURL, &fromUser.Status, &fromUser.CreatedAt, &fromUser.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		
		request.FromUser = &fromUser
		requests = append(requests, &request)
	}

	return requests, nil
}

// GetSentFriendRequests 获取已发送的好友请求
func (r *FriendRepository) GetSentFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequest, error) {
	var requests []*domain.FriendRequest

	query := `
	SELECT 
		fr.id, fr.from_user_id, fr.to_user_id, fr.message, fr.status, fr.created_at, fr.updated_at,
		u.id as "to_user.id", u.username as "to_user.username", u.email as "to_user.email",
		u.full_name as "to_user.full_name", u.avatar_url as "to_user.avatar_url", u.status as "to_user.status",
		u.created_at as "to_user.created_at", u.updated_at as "to_user.updated_at"
	FROM friend_requests fr
	JOIN users u ON fr.to_user_id = u.id
	WHERE fr.from_user_id = $1
	ORDER BY fr.created_at DESC
	`

	rows, err := r.db.QueryxContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var request domain.FriendRequest
		var toUser domain.User
		
		err := rows.Scan(
			&request.ID, &request.FromUserID, &request.ToUserID, &request.Message, &request.Status, &request.CreatedAt, &request.UpdatedAt,
			&toUser.ID, &toUser.Username, &toUser.Email, &toUser.FullName, &toUser.AvatarURL, &toUser.Status, &toUser.CreatedAt, &toUser.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		
		request.ToUser = &toUser
		requests = append(requests, &request)
	}

	return requests, nil
}

// UpdateFriendRequestStatus 更新好友请求状态
func (r *FriendRepository) UpdateFriendRequestStatus(ctx context.Context, requestID string, status domain.FriendRequestStatus) error {
	query := `
	UPDATE friend_requests
	SET status = $1, updated_at = $2
	WHERE id = $3
	`

	_, err := r.db.ExecContext(ctx, query, status, time.Now(), requestID)
	return err
}

// CheckExistingFriendRequest 检查是否已存在好友请求
func (r *FriendRepository) CheckExistingFriendRequest(ctx context.Context, fromUserID, toUserID string) (*domain.FriendRequest, error) {
	var request domain.FriendRequest

	query := `
	SELECT id, from_user_id, to_user_id, message, status, created_at, updated_at
	FROM friend_requests
	WHERE (from_user_id = $1 AND to_user_id = $2) OR (from_user_id = $2 AND to_user_id = $1)
	AND status = 'pending'
	`

	err := r.db.GetContext(ctx, &request, query, fromUserID, toUserID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &request, nil
}

// CreateFriendship 创建好友关系
func (r *FriendRepository) CreateFriendship(ctx context.Context, friendship *domain.Friendship) error {
	// 生成UUID
	if friendship.ID == "" {
		friendship.ID = uuid.New().String()
	}

	// 确保user1_id < user2_id（数据库约束）
	user1ID, user2ID := friendship.User1ID, friendship.User2ID
	if user1ID > user2ID {
		user1ID, user2ID = user2ID, user1ID
	}

	// 设置时间戳
	friendship.CreatedAt = time.Now()

	// 插入好友关系记录
	query := `
	INSERT INTO friendships (id, user1_id, user2_id, created_at)
	VALUES ($1, $2, $3, $4)
	`

	_, err := r.db.ExecContext(
		ctx,
		query,
		friendship.ID,
		user1ID,
		user2ID,
		friendship.CreatedAt,
	)

	return err
}

// GetFriendships 获取用户的好友关系
func (r *FriendRepository) GetFriendships(ctx context.Context, userID string) ([]*domain.Friendship, error) {
	var friendships []*domain.Friendship

	query := `
	SELECT 
		f.id, f.user1_id, f.user2_id, f.created_at,
		u1.id as "user1.id", u1.username as "user1.username", u1.email as "user1.email",
		u1.full_name as "user1.full_name", u1.avatar_url as "user1.avatar_url", u1.status as "user1.status",
		u1.created_at as "user1.created_at", u1.updated_at as "user1.updated_at",
		u2.id as "user2.id", u2.username as "user2.username", u2.email as "user2.email",
		u2.full_name as "user2.full_name", u2.avatar_url as "user2.avatar_url", u2.status as "user2.status",
		u2.created_at as "user2.created_at", u2.updated_at as "user2.updated_at"
	FROM friendships f
	JOIN users u1 ON f.user1_id = u1.id
	JOIN users u2 ON f.user2_id = u2.id
	WHERE f.user1_id = $1 OR f.user2_id = $1
	ORDER BY f.created_at DESC
	`

	rows, err := r.db.QueryxContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var friendship domain.Friendship
		var user1, user2 domain.User
		
		err := rows.Scan(
			&friendship.ID, &friendship.User1ID, &friendship.User2ID, &friendship.CreatedAt,
			&user1.ID, &user1.Username, &user1.Email, &user1.FullName, &user1.AvatarURL, &user1.Status, &user1.CreatedAt, &user1.UpdatedAt,
			&user2.ID, &user2.Username, &user2.Email, &user2.FullName, &user2.AvatarURL, &user2.Status, &user2.CreatedAt, &user2.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		
		friendship.User1 = &user1
		friendship.User2 = &user2
		friendships = append(friendships, &friendship)
	}

	return friendships, nil
}

// CheckFriendship 检查两个用户是否为好友
func (r *FriendRepository) CheckFriendship(ctx context.Context, user1ID, user2ID string) (*domain.Friendship, error) {
	var friendship domain.Friendship

	// 确保user1_id < user2_id
	if user1ID > user2ID {
		user1ID, user2ID = user2ID, user1ID
	}

	query := `
	SELECT id, user1_id, user2_id, created_at
	FROM friendships
	WHERE user1_id = $1 AND user2_id = $2
	`

	err := r.db.GetContext(ctx, &friendship, query, user1ID, user2ID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &friendship, nil
}

// DeleteFriendship 删除好友关系
func (r *FriendRepository) DeleteFriendship(ctx context.Context, user1ID, user2ID string) error {
	// 确保user1_id < user2_id
	if user1ID > user2ID {
		user1ID, user2ID = user2ID, user1ID
	}

	query := `
	DELETE FROM friendships
	WHERE user1_id = $1 AND user2_id = $2
	`

	_, err := r.db.ExecContext(ctx, query, user1ID, user2ID)
	return err
}