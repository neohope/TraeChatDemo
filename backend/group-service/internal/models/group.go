package models

import (
	"time"

	"github.com/google/uuid"
)

// Group 群组模型
type Group struct {
	ID          uuid.UUID `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	AvatarURL   string    `json:"avatar_url" db:"avatar_url"`
	OwnerID     uuid.UUID `json:"owner_id" db:"owner_id"`
	MaxMembers  int       `json:"max_members" db:"max_members"`
	IsPrivate   bool      `json:"is_private" db:"is_private"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// GroupMember 群组成员模型
type GroupMember struct {
	ID       uuid.UUID          `json:"id" db:"id"`
	GroupID  uuid.UUID          `json:"group_id" db:"group_id"`
	UserID   uuid.UUID          `json:"user_id" db:"user_id"`
	Role     GroupMemberRole    `json:"role" db:"role"`
	Status   GroupMemberStatus  `json:"status" db:"status"`
	JoinedAt time.Time          `json:"joined_at" db:"joined_at"`
	Nickname string             `json:"nickname" db:"nickname"`
}

// GroupMemberRole 群组成员角色
type GroupMemberRole string

const (
	RoleOwner     GroupMemberRole = "owner"
	RoleAdmin     GroupMemberRole = "admin"
	RoleMember    GroupMemberRole = "member"
)

// GroupMemberStatus 群组成员状态
type GroupMemberStatus string

const (
	StatusActive  GroupMemberStatus = "active"
	StatusMuted   GroupMemberStatus = "muted"
	StatusBanned  GroupMemberStatus = "banned"
	StatusPending GroupMemberStatus = "pending"
)

// GroupInvitation 群组邀请模型
type GroupInvitation struct {
	ID        uuid.UUID           `json:"id" db:"id"`
	GroupID   uuid.UUID           `json:"group_id" db:"group_id"`
	InviterID uuid.UUID           `json:"inviter_id" db:"inviter_id"`
	InviteeID uuid.UUID           `json:"invitee_id" db:"invitee_id"`
	Status    InvitationStatus    `json:"status" db:"status"`
	Message   string              `json:"message" db:"message"`
	CreatedAt time.Time           `json:"created_at" db:"created_at"`
	ExpiresAt time.Time           `json:"expires_at" db:"expires_at"`
}

// InvitationStatus 邀请状态
type InvitationStatus string

const (
	InvitationPending  InvitationStatus = "pending"
	InvitationAccepted InvitationStatus = "accepted"
	InvitationRejected InvitationStatus = "rejected"
	InvitationExpired  InvitationStatus = "expired"
)

// CreateGroupRequest 创建群组请求
type CreateGroupRequest struct {
	Name        string `json:"name" validate:"required,min=1,max=50"`
	Description string `json:"description" validate:"max=200"`
	AvatarURL   string `json:"avatar_url" validate:"omitempty,url"`
	MaxMembers  int    `json:"max_members" validate:"min=2,max=500"`
	IsPrivate   bool   `json:"is_private"`
}

// UpdateGroupRequest 更新群组请求
type UpdateGroupRequest struct {
	Name        *string `json:"name,omitempty" validate:"omitempty,min=1,max=50"`
	Description *string `json:"description,omitempty" validate:"omitempty,max=200"`
	AvatarURL   *string `json:"avatar_url,omitempty" validate:"omitempty,url"`
	MaxMembers  *int    `json:"max_members,omitempty" validate:"omitempty,min=2,max=500"`
	IsPrivate   *bool   `json:"is_private,omitempty"`
}

// AddMemberRequest 添加成员请求
type AddMemberRequest struct {
	UserID   uuid.UUID       `json:"user_id" validate:"required"`
	Role     GroupMemberRole `json:"role" validate:"omitempty,oneof=admin member"`
	Nickname string          `json:"nickname" validate:"omitempty,max=30"`
}

// UpdateMemberRequest 更新成员请求
type UpdateMemberRequest struct {
	Role     *GroupMemberRole   `json:"role,omitempty" validate:"omitempty,oneof=admin member"`
	Status   *GroupMemberStatus `json:"status,omitempty" validate:"omitempty,oneof=active muted banned"`
	Nickname *string           `json:"nickname,omitempty" validate:"omitempty,max=30"`
}

// InviteRequest 邀请请求
type InviteRequest struct {
	UserID  uuid.UUID `json:"user_id" validate:"required"`
	Message string    `json:"message" validate:"omitempty,max=200"`
}

// GroupWithMemberCount 带成员数量的群组
type GroupWithMemberCount struct {
	ID          uuid.UUID `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	AvatarURL   string    `json:"avatar_url" db:"avatar_url"`
	OwnerID     uuid.UUID `json:"owner_id" db:"owner_id"`
	MaxMembers  int       `json:"max_members" db:"max_members"`
	IsPrivate   bool      `json:"is_private" db:"is_private"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
	MemberCount int       `json:"member_count" db:"member_count"`
}

// GroupMemberWithUser 带用户信息的群组成员
type GroupMemberWithUser struct {
	GroupMember `json:",inline"`
	Username    string `json:"username"`
	AvatarURL   string `json:"user_avatar_url"`
}