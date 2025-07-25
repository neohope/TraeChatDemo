package repository

import (
	"context"
	"database/sql"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/neohope/chatapp/group-service/internal/models"
)

// GroupRepository 群组仓库接口
type GroupRepository interface {
	// 群组管理
	CreateGroup(ctx context.Context, group *models.Group) error
	GetGroupByID(ctx context.Context, groupID uuid.UUID) (*models.Group, error)
	UpdateGroup(ctx context.Context, groupID uuid.UUID, updates map[string]interface{}) error
	DeleteGroup(ctx context.Context, groupID uuid.UUID) error
	GetGroupsByOwner(ctx context.Context, ownerID uuid.UUID) ([]*models.Group, error)
	SearchGroups(ctx context.Context, query string, limit, offset int) ([]*models.GroupWithMemberCount, error)

	// 成员管理
	AddMember(ctx context.Context, member *models.GroupMember) error
	RemoveMember(ctx context.Context, groupID, userID uuid.UUID) error
	UpdateMember(ctx context.Context, groupID, userID uuid.UUID, updates map[string]interface{}) error
	GetMember(ctx context.Context, groupID, userID uuid.UUID) (*models.GroupMember, error)
	GetGroupMembers(ctx context.Context, groupID uuid.UUID) ([]*models.GroupMemberWithUser, error)
	GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*models.GroupWithMemberCount, error)
	IsMember(ctx context.Context, groupID, userID uuid.UUID) (bool, error)
	GetMemberCount(ctx context.Context, groupID uuid.UUID) (int, error)

	// 邀请管理
	CreateInvitation(ctx context.Context, invitation *models.GroupInvitation) error
	GetInvitation(ctx context.Context, invitationID uuid.UUID) (*models.GroupInvitation, error)
	UpdateInvitationStatus(ctx context.Context, invitationID uuid.UUID, status models.InvitationStatus) error
	GetPendingInvitations(ctx context.Context, userID uuid.UUID) ([]*models.GroupInvitation, error)
	GetGroupInvitations(ctx context.Context, groupID uuid.UUID) ([]*models.GroupInvitation, error)
}

// PostgreSQLGroupRepository PostgreSQL群组仓库实现
type PostgreSQLGroupRepository struct {
	db *sqlx.DB
}

// NewPostgreSQLGroupRepository 创建PostgreSQL群组仓库
func NewPostgreSQLGroupRepository(db *sqlx.DB) *PostgreSQLGroupRepository {
	return &PostgreSQLGroupRepository{db: db}
}

// CreateGroup 创建群组
func (r *PostgreSQLGroupRepository) CreateGroup(ctx context.Context, group *models.Group) error {
	query := `
		INSERT INTO groups (id, name, description, avatar_url, owner_id, max_members, is_private, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		group.ID, group.Name, group.Description, group.AvatarURL,
		group.OwnerID, group.MaxMembers, group.IsPrivate,
		group.CreatedAt, group.UpdatedAt)
	return err
}

// GetGroupByID 根据ID获取群组
func (r *PostgreSQLGroupRepository) GetGroupByID(ctx context.Context, groupID uuid.UUID) (*models.Group, error) {
	var group models.Group
	query := `SELECT * FROM groups WHERE id = $1`
	err := r.db.GetContext(ctx, &group, query, groupID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &group, err
}

// UpdateGroup 更新群组
func (r *PostgreSQLGroupRepository) UpdateGroup(ctx context.Context, groupID uuid.UUID, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}

	setClause := ""
	args := []interface{}{}
	argIndex := 1

	for field, value := range updates {
		if setClause != "" {
			setClause += ", "
		}
		setClause += fmt.Sprintf("%s = $%d", field, argIndex)
		args = append(args, value)
		argIndex++
	}

	// 添加updated_at字段
	setClause += fmt.Sprintf(", updated_at = $%d", argIndex)
	args = append(args, time.Now())
	argIndex++

	// 添加WHERE条件
	args = append(args, groupID)

	query := fmt.Sprintf("UPDATE groups SET %s WHERE id = $%d", setClause, argIndex)
	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}

// DeleteGroup 删除群组
func (r *PostgreSQLGroupRepository) DeleteGroup(ctx context.Context, groupID uuid.UUID) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// 删除群组邀请
	_, err = tx.ExecContext(ctx, "DELETE FROM group_invitations WHERE group_id = $1", groupID)
	if err != nil {
		return err
	}

	// 删除群组成员
	_, err = tx.ExecContext(ctx, "DELETE FROM group_members WHERE group_id = $1", groupID)
	if err != nil {
		return err
	}

	// 删除群组
	_, err = tx.ExecContext(ctx, "DELETE FROM groups WHERE id = $1", groupID)
	if err != nil {
		return err
	}

	return tx.Commit()
}

// GetGroupsByOwner 获取用户拥有的群组
func (r *PostgreSQLGroupRepository) GetGroupsByOwner(ctx context.Context, ownerID uuid.UUID) ([]*models.Group, error) {
	var groups []*models.Group
	query := `SELECT * FROM groups WHERE owner_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &groups, query, ownerID)
	return groups, err
}

// SearchGroups 搜索群组
func (r *PostgreSQLGroupRepository) SearchGroups(ctx context.Context, query string, limit, offset int) ([]*models.GroupWithMemberCount, error) {
	var groups []*models.GroupWithMemberCount
	sql := `
		SELECT g.*, COALESCE(mc.member_count, 0) as member_count
		FROM groups g
		LEFT JOIN (
			SELECT group_id, COUNT(*) as member_count
			FROM group_members
			WHERE status = 'active'
			GROUP BY group_id
		) mc ON g.id = mc.group_id
		WHERE g.is_private = false AND g.name ILIKE $1
		ORDER BY g.created_at DESC
		LIMIT $2 OFFSET $3
	`
	err := r.db.SelectContext(ctx, &groups, sql, "%"+query+"%", limit, offset)
	return groups, err
}

// AddMember 添加群组成员
func (r *PostgreSQLGroupRepository) AddMember(ctx context.Context, member *models.GroupMember) error {
	query := `
		INSERT INTO group_members (id, group_id, user_id, role, status, joined_at, nickname)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query,
		member.ID, member.GroupID, member.UserID, member.Role,
		member.Status, member.JoinedAt, member.Nickname)
	return err
}

// RemoveMember 移除群组成员
func (r *PostgreSQLGroupRepository) RemoveMember(ctx context.Context, groupID, userID uuid.UUID) error {
	query := `DELETE FROM group_members WHERE group_id = $1 AND user_id = $2`
	_, err := r.db.ExecContext(ctx, query, groupID, userID)
	return err
}

// UpdateMember 更新群组成员
func (r *PostgreSQLGroupRepository) UpdateMember(ctx context.Context, groupID, userID uuid.UUID, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}

	setClause := ""
	args := []interface{}{}
	argIndex := 1

	for field, value := range updates {
		if setClause != "" {
			setClause += ", "
		}
		setClause += fmt.Sprintf("%s = $%d", field, argIndex)
		args = append(args, value)
		argIndex++
	}

	// 添加WHERE条件
	args = append(args, groupID, userID)

	query := fmt.Sprintf("UPDATE group_members SET %s WHERE group_id = $%d AND user_id = $%d", setClause, argIndex, argIndex+1)
	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}

// GetMember 获取群组成员
func (r *PostgreSQLGroupRepository) GetMember(ctx context.Context, groupID, userID uuid.UUID) (*models.GroupMember, error) {
	var member models.GroupMember
	query := `SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2`
	err := r.db.GetContext(ctx, &member, query, groupID, userID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &member, err
}

// GetGroupMembers 获取群组所有成员
func (r *PostgreSQLGroupRepository) GetGroupMembers(ctx context.Context, groupID uuid.UUID) ([]*models.GroupMemberWithUser, error) {
	var members []*models.GroupMemberWithUser
	query := `
		SELECT gm.*, u.username, u.avatar_url as user_avatar_url
		FROM group_members gm
		JOIN users u ON gm.user_id = u.id
		WHERE gm.group_id = $1 AND gm.status = 'active'
		ORDER BY gm.role, gm.joined_at
	`
	err := r.db.SelectContext(ctx, &members, query, groupID)
	return members, err
}

// GetUserGroups 获取用户加入的群组
func (r *PostgreSQLGroupRepository) GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*models.GroupWithMemberCount, error) {
	var groups []*models.GroupWithMemberCount
	query := `
		SELECT g.*, COALESCE(mc.member_count, 0) as member_count
		FROM groups g
		JOIN group_members gm ON g.id = gm.group_id
		LEFT JOIN (
			SELECT group_id, COUNT(*) as member_count
			FROM group_members
			WHERE status = 'active'
			GROUP BY group_id
		) mc ON g.id = mc.group_id
		WHERE gm.user_id = $1 AND gm.status = 'active'
		ORDER BY gm.joined_at DESC
	`
	err := r.db.SelectContext(ctx, &groups, query, userID)
	return groups, err
}

// IsMember 检查用户是否为群组成员
func (r *PostgreSQLGroupRepository) IsMember(ctx context.Context, groupID, userID uuid.UUID) (bool, error) {
	var count int
	query := `SELECT COUNT(*) FROM group_members WHERE group_id = $1 AND user_id = $2 AND status = 'active'`
	err := r.db.GetContext(ctx, &count, query, groupID, userID)
	return count > 0, err
}

// GetMemberCount 获取群组成员数量
func (r *PostgreSQLGroupRepository) GetMemberCount(ctx context.Context, groupID uuid.UUID) (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM group_members WHERE group_id = $1 AND status = 'active'`
	err := r.db.GetContext(ctx, &count, query, groupID)
	return count, err
}

// CreateInvitation 创建邀请
func (r *PostgreSQLGroupRepository) CreateInvitation(ctx context.Context, invitation *models.GroupInvitation) error {
	query := `
		INSERT INTO group_invitations (id, group_id, inviter_id, invitee_id, status, message, created_at, expires_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query,
		invitation.ID, invitation.GroupID, invitation.InviterID, invitation.InviteeID,
		invitation.Status, invitation.Message, invitation.CreatedAt, invitation.ExpiresAt)
	return err
}

// GetInvitation 获取邀请
func (r *PostgreSQLGroupRepository) GetInvitation(ctx context.Context, invitationID uuid.UUID) (*models.GroupInvitation, error) {
	var invitation models.GroupInvitation
	query := `SELECT * FROM group_invitations WHERE id = $1`
	err := r.db.GetContext(ctx, &invitation, query, invitationID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &invitation, err
}

// UpdateInvitationStatus 更新邀请状态
func (r *PostgreSQLGroupRepository) UpdateInvitationStatus(ctx context.Context, invitationID uuid.UUID, status models.InvitationStatus) error {
	query := `UPDATE group_invitations SET status = $1 WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, status, invitationID)
	return err
}

// GetPendingInvitations 获取用户的待处理邀请
func (r *PostgreSQLGroupRepository) GetPendingInvitations(ctx context.Context, userID uuid.UUID) ([]*models.GroupInvitation, error) {
	var invitations []*models.GroupInvitation
	query := `
		SELECT * FROM group_invitations
		WHERE invitee_id = $1 AND status = 'pending' AND expires_at > NOW()
		ORDER BY created_at DESC
	`
	err := r.db.SelectContext(ctx, &invitations, query, userID)
	return invitations, err
}

// GetGroupInvitations 获取群组的所有邀请
func (r *PostgreSQLGroupRepository) GetGroupInvitations(ctx context.Context, groupID uuid.UUID) ([]*models.GroupInvitation, error) {
	var invitations []*models.GroupInvitation
	query := `SELECT * FROM group_invitations WHERE group_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &invitations, query, groupID)
	return invitations, err
}

// MemoryGroupRepository 内存群组仓库实现（用于测试）
type MemoryGroupRepository struct {
	groups      map[uuid.UUID]*models.Group
	members     map[uuid.UUID]map[uuid.UUID]*models.GroupMember // groupID -> userID -> member
	invitations map[uuid.UUID]*models.GroupInvitation
	mu          sync.RWMutex
}

// NewMemoryGroupRepository 创建内存群组仓库
func NewMemoryGroupRepository() *MemoryGroupRepository {
	return &MemoryGroupRepository{
		groups:      make(map[uuid.UUID]*models.Group),
		members:     make(map[uuid.UUID]map[uuid.UUID]*models.GroupMember),
		invitations: make(map[uuid.UUID]*models.GroupInvitation),
	}
}

// CreateGroup 创建群组
func (r *MemoryGroupRepository) CreateGroup(ctx context.Context, group *models.Group) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.groups[group.ID] = group
	r.members[group.ID] = make(map[uuid.UUID]*models.GroupMember)
	return nil
}

// GetGroupByID 根据ID获取群组
func (r *MemoryGroupRepository) GetGroupByID(ctx context.Context, groupID uuid.UUID) (*models.Group, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	group, exists := r.groups[groupID]
	if !exists {
		return nil, nil
	}
	return group, nil
}

// 其他方法的内存实现...
// 为了简化，这里只实现核心方法，其他方法可以类似实现

// UpdateGroup 更新群组
func (r *MemoryGroupRepository) UpdateGroup(ctx context.Context, groupID uuid.UUID, updates map[string]interface{}) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	group, exists := r.groups[groupID]
	if !exists {
		return fmt.Errorf("group not found")
	}

	// 简化的更新逻辑
	if name, ok := updates["name"]; ok {
		group.Name = name.(string)
	}
	if description, ok := updates["description"]; ok {
		group.Description = description.(string)
	}
	group.UpdatedAt = time.Now()
	return nil
}

// DeleteGroup 删除群组
func (r *MemoryGroupRepository) DeleteGroup(ctx context.Context, groupID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.groups, groupID)
	delete(r.members, groupID)
	return nil
}

// AddMember 添加群组成员
func (r *MemoryGroupRepository) AddMember(ctx context.Context, member *models.GroupMember) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.members[member.GroupID] == nil {
		r.members[member.GroupID] = make(map[uuid.UUID]*models.GroupMember)
	}
	r.members[member.GroupID][member.UserID] = member
	return nil
}

// IsMember 检查用户是否为群组成员
func (r *MemoryGroupRepository) IsMember(ctx context.Context, groupID, userID uuid.UUID) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	groupMembers, exists := r.members[groupID]
	if !exists {
		return false, nil
	}
	member, exists := groupMembers[userID]
	return exists && member.Status == models.StatusActive, nil
}

// 其他方法的简化实现...
func (r *MemoryGroupRepository) GetGroupsByOwner(ctx context.Context, ownerID uuid.UUID) ([]*models.Group, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var groups []*models.Group
	for _, group := range r.groups {
		if group.OwnerID == ownerID {
			groups = append(groups, group)
		}
	}
	return groups, nil
}

func (r *MemoryGroupRepository) SearchGroups(ctx context.Context, query string, limit, offset int) ([]*models.GroupWithMemberCount, error) {
	return []*models.GroupWithMemberCount{}, nil
}

func (r *MemoryGroupRepository) RemoveMember(ctx context.Context, groupID, userID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if groupMembers, exists := r.members[groupID]; exists {
		delete(groupMembers, userID)
	}
	return nil
}

func (r *MemoryGroupRepository) UpdateMember(ctx context.Context, groupID, userID uuid.UUID, updates map[string]interface{}) error {
	return nil
}

func (r *MemoryGroupRepository) GetMember(ctx context.Context, groupID, userID uuid.UUID) (*models.GroupMember, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if groupMembers, exists := r.members[groupID]; exists {
		if member, exists := groupMembers[userID]; exists {
			return member, nil
		}
	}
	return nil, nil
}

func (r *MemoryGroupRepository) GetGroupMembers(ctx context.Context, groupID uuid.UUID) ([]*models.GroupMemberWithUser, error) {
	return []*models.GroupMemberWithUser{}, nil
}

func (r *MemoryGroupRepository) GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*models.GroupWithMemberCount, error) {
	return []*models.GroupWithMemberCount{}, nil
}

func (r *MemoryGroupRepository) GetMemberCount(ctx context.Context, groupID uuid.UUID) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if groupMembers, exists := r.members[groupID]; exists {
		count := 0
		for _, member := range groupMembers {
			if member.Status == models.StatusActive {
				count++
			}
		}
		return count, nil
	}
	return 0, nil
}

func (r *MemoryGroupRepository) CreateInvitation(ctx context.Context, invitation *models.GroupInvitation) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.invitations[invitation.ID] = invitation
	return nil
}

func (r *MemoryGroupRepository) GetInvitation(ctx context.Context, invitationID uuid.UUID) (*models.GroupInvitation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	invitation, exists := r.invitations[invitationID]
	if !exists {
		return nil, nil
	}
	return invitation, nil
}

func (r *MemoryGroupRepository) UpdateInvitationStatus(ctx context.Context, invitationID uuid.UUID, status models.InvitationStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if invitation, exists := r.invitations[invitationID]; exists {
		invitation.Status = status
	}
	return nil
}

func (r *MemoryGroupRepository) GetPendingInvitations(ctx context.Context, userID uuid.UUID) ([]*models.GroupInvitation, error) {
	return []*models.GroupInvitation{}, nil
}

func (r *MemoryGroupRepository) GetGroupInvitations(ctx context.Context, groupID uuid.UUID) ([]*models.GroupInvitation, error) {
	return []*models.GroupInvitation{}, nil
}
