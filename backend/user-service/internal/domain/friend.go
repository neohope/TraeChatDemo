package domain

import (
	"context"
	"time"
)

// FriendRequestStatus 好友请求状态枚举
type FriendRequestStatus string

const (
	FriendRequestStatusPending  FriendRequestStatus = "pending"
	FriendRequestStatusAccepted FriendRequestStatus = "accepted"
	FriendRequestStatusRejected FriendRequestStatus = "rejected"
)

// FriendRequest 好友请求实体
type FriendRequest struct {
	ID         string              `json:"id" db:"id"`
	FromUserID string              `json:"from_user_id" db:"from_user_id"`
	ToUserID   string              `json:"to_user_id" db:"to_user_id"`
	Message    string              `json:"message" db:"message"`
	Status     FriendRequestStatus `json:"status" db:"status"`
	CreatedAt  time.Time           `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time           `json:"updated_at" db:"updated_at"`
	// 关联的用户信息
	FromUser *User `json:"from_user,omitempty"`
	ToUser   *User `json:"to_user,omitempty"`
}

// Friendship 好友关系实体
type Friendship struct {
	ID        string    `json:"id" db:"id"`
	User1ID   string    `json:"user1_id" db:"user1_id"`
	User2ID   string    `json:"user2_id" db:"user2_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	// 关联的用户信息
	User1 *User `json:"user1,omitempty"`
	User2 *User `json:"user2,omitempty"`
}

// FriendRepository 好友仓库接口
type FriendRepository interface {
	// 好友请求相关
	CreateFriendRequest(ctx context.Context, request *FriendRequest) error
	GetFriendRequestByID(ctx context.Context, id string) (*FriendRequest, error)
	GetPendingFriendRequests(ctx context.Context, userID string) ([]*FriendRequest, error)
	GetSentFriendRequests(ctx context.Context, userID string) ([]*FriendRequest, error)
	UpdateFriendRequestStatus(ctx context.Context, requestID string, status FriendRequestStatus) error
	CheckExistingFriendRequest(ctx context.Context, fromUserID, toUserID string) (*FriendRequest, error)
	
	// 好友关系相关
	CreateFriendship(ctx context.Context, friendship *Friendship) error
	GetFriendships(ctx context.Context, userID string) ([]*Friendship, error)
	CheckFriendship(ctx context.Context, user1ID, user2ID string) (*Friendship, error)
	DeleteFriendship(ctx context.Context, user1ID, user2ID string) error
}

// FriendService 好友服务接口
type FriendService interface {
	// 好友请求相关
	SendFriendRequest(ctx context.Context, fromUserID, toUserID, message string) error
	AcceptFriendRequest(ctx context.Context, requestID, userID string) error
	RejectFriendRequest(ctx context.Context, requestID, userID string) error
	GetPendingFriendRequests(ctx context.Context, userID string) ([]*FriendRequest, error)
	GetSentFriendRequests(ctx context.Context, userID string) ([]*FriendRequest, error)
	
	// 好友关系相关
	GetFriends(ctx context.Context, userID string) ([]*User, error)
	RemoveFriend(ctx context.Context, userID, friendID string) error
	CheckFriendship(ctx context.Context, user1ID, user2ID string) (bool, error)
}

// SendFriendRequestRequest 发送好友请求
type SendFriendRequestRequest struct {
	UserID  string `json:"userId" validate:"required"`
	Message string `json:"message"`
}

// AcceptFriendRequestRequest 接受好友请求
type AcceptFriendRequestRequest struct {
	RequestID string `json:"requestId" validate:"required"`
}

// RejectFriendRequestRequest 拒绝好友请求
type RejectFriendRequestRequest struct {
	RequestID string `json:"requestId" validate:"required"`
}