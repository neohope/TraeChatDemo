package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/neohope/chatapp/group-service/internal/models"
	"github.com/neohope/chatapp/group-service/internal/repository"
	"go.uber.org/zap"
)

// GroupService 群组服务接口
type GroupService interface {
	// 群组管理
	CreateGroup(ctx context.Context, userID uuid.UUID, req *models.CreateGroupRequest) (*models.Group, error)
	GetGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) (*models.Group, error)
	UpdateGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID, req *models.UpdateGroupRequest) (*models.Group, error)
	DeleteGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error
	GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*models.GroupWithMemberCount, error)
	SearchGroups(ctx context.Context, query string, limit, offset int) ([]*models.GroupWithMemberCount, error)

	// 成员管理
	AddMember(ctx context.Context, userID uuid.UUID, groupID uuid.UUID, req *models.AddMemberRequest) error
	RemoveMember(ctx context.Context, userID uuid.UUID, groupID, targetUserID uuid.UUID) error
	UpdateMember(ctx context.Context, userID uuid.UUID, groupID, targetUserID uuid.UUID, req *models.UpdateMemberRequest) error
	GetGroupMembers(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) ([]*models.GroupMemberWithUser, error)
	LeaveGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error

	// 邀请管理
	InviteUser(ctx context.Context, userID uuid.UUID, groupID uuid.UUID, req *models.InviteRequest) (*models.GroupInvitation, error)
	AcceptInvitation(ctx context.Context, userID uuid.UUID, invitationID uuid.UUID) error
	RejectInvitation(ctx context.Context, userID uuid.UUID, invitationID uuid.UUID) error
	GetPendingInvitations(ctx context.Context, userID uuid.UUID) ([]*models.GroupInvitation, error)
}

// groupService 群组服务实现
type groupService struct {
	repo   repository.GroupRepository
	logger *zap.Logger
}

// NewGroupService 创建群组服务
func NewGroupService(repo repository.GroupRepository, logger *zap.Logger) GroupService {
	return &groupService{
		repo:   repo,
		logger: logger,
	}
}

// CreateGroup 创建群组
func (s *groupService) CreateGroup(ctx context.Context, userID uuid.UUID, req *models.CreateGroupRequest) (*models.Group, error) {
	// 验证输入
	if err := s.validateCreateGroupRequest(req); err != nil {
		return nil, err
	}

	// 创建群组
	group := &models.Group{
		ID:          uuid.New(),
		Name:        strings.TrimSpace(req.Name),
		Description: strings.TrimSpace(req.Description),
		AvatarURL:   req.AvatarURL,
		OwnerID:     userID,
		MaxMembers:  req.MaxMembers,
		IsPrivate:   req.IsPrivate,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if group.MaxMembers == 0 {
		group.MaxMembers = 100 // 默认最大成员数
	}

	// 保存群组
	if err := s.repo.CreateGroup(ctx, group); err != nil {
		s.logger.Error("Failed to create group", zap.Error(err), zap.String("user_id", userID.String()))
		return nil, fmt.Errorf("failed to create group: %w", err)
	}

	// 添加创建者为群主
	member := &models.GroupMember{
		ID:       uuid.New(),
		GroupID:  group.ID,
		UserID:   userID,
		Role:     models.RoleOwner,
		Status:   models.StatusActive,
		JoinedAt: time.Now(),
	}

	if err := s.repo.AddMember(ctx, member); err != nil {
		s.logger.Error("Failed to add owner as member", zap.Error(err), zap.String("group_id", group.ID.String()))
		// 尝试删除已创建的群组
		s.repo.DeleteGroup(ctx, group.ID)
		return nil, fmt.Errorf("failed to add owner as member: %w", err)
	}

	s.logger.Info("Group created successfully", zap.String("group_id", group.ID.String()), zap.String("owner_id", userID.String()))
	return group, nil
}

// GetGroup 获取群组信息
func (s *groupService) GetGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) (*models.Group, error) {
	group, err := s.repo.GetGroupByID(ctx, groupID)
	if err != nil {
		return nil, fmt.Errorf("failed to get group: %w", err)
	}
	if group == nil {
		return nil, fmt.Errorf("group not found")
	}

	// 检查权限：私有群组需要是成员才能查看
	if group.IsPrivate {
		isMember, err := s.repo.IsMember(ctx, groupID, userID)
		if err != nil {
			return nil, fmt.Errorf("failed to check membership: %w", err)
		}
		if !isMember {
			return nil, fmt.Errorf("access denied: not a member of private group")
		}
	}

	return group, nil
}

// UpdateGroup 更新群组信息
func (s *groupService) UpdateGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID, req *models.UpdateGroupRequest) (*models.Group, error) {
	// 检查权限
	if err := s.checkAdminPermission(ctx, userID, groupID); err != nil {
		return nil, err
	}

	// 验证输入
	if err := s.validateUpdateGroupRequest(req); err != nil {
		return nil, err
	}

	// 构建更新字段
	updates := make(map[string]interface{})
	if req.Name != nil {
		updates["name"] = strings.TrimSpace(*req.Name)
	}
	if req.Description != nil {
		updates["description"] = strings.TrimSpace(*req.Description)
	}
	if req.AvatarURL != nil {
		updates["avatar_url"] = *req.AvatarURL
	}
	if req.MaxMembers != nil {
		updates["max_members"] = *req.MaxMembers
	}
	if req.IsPrivate != nil {
		updates["is_private"] = *req.IsPrivate
	}

	if len(updates) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	// 更新群组
	if err := s.repo.UpdateGroup(ctx, groupID, updates); err != nil {
		s.logger.Error("Failed to update group", zap.Error(err), zap.String("group_id", groupID.String()))
		return nil, fmt.Errorf("failed to update group: %w", err)
	}

	// 返回更新后的群组信息
	return s.repo.GetGroupByID(ctx, groupID)
}

// DeleteGroup 删除群组
func (s *groupService) DeleteGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error {
	// 检查是否为群主
	if err := s.checkOwnerPermission(ctx, userID, groupID); err != nil {
		return err
	}

	if err := s.repo.DeleteGroup(ctx, groupID); err != nil {
		s.logger.Error("Failed to delete group", zap.Error(err), zap.String("group_id", groupID.String()))
		return fmt.Errorf("failed to delete group: %w", err)
	}

	s.logger.Info("Group deleted successfully", zap.String("group_id", groupID.String()), zap.String("owner_id", userID.String()))
	return nil
}

// GetUserGroups 获取用户加入的群组
func (s *groupService) GetUserGroups(ctx context.Context, userID uuid.UUID) ([]*models.GroupWithMemberCount, error) {
	groups, err := s.repo.GetUserGroups(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user groups: %w", err)
	}
	return groups, nil
}

// SearchGroups 搜索公开群组
func (s *groupService) SearchGroups(ctx context.Context, query string, limit, offset int) ([]*models.GroupWithMemberCount, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	if offset < 0 {
		offset = 0
	}

	groups, err := s.repo.SearchGroups(ctx, strings.TrimSpace(query), limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to search groups: %w", err)
	}
	return groups, nil
}

// AddMember 添加群组成员
func (s *groupService) AddMember(ctx context.Context, userID uuid.UUID, groupID uuid.UUID, req *models.AddMemberRequest) error {
	// 检查权限
	if err := s.checkAdminPermission(ctx, userID, groupID); err != nil {
		return err
	}

	// 检查群组是否存在
	group, err := s.repo.GetGroupByID(ctx, groupID)
	if err != nil {
		return fmt.Errorf("failed to get group: %w", err)
	}
	if group == nil {
		return fmt.Errorf("group not found")
	}

	// 检查用户是否已经是成员
	isMember, err := s.repo.IsMember(ctx, groupID, req.UserID)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if isMember {
		return fmt.Errorf("user is already a member")
	}

	// 检查群组成员数量限制
	memberCount, err := s.repo.GetMemberCount(ctx, groupID)
	if err != nil {
		return fmt.Errorf("failed to get member count: %w", err)
	}
	if memberCount >= group.MaxMembers {
		return fmt.Errorf("group has reached maximum member limit")
	}

	// 添加成员
	role := models.RoleMember
	if req.Role != "" {
		role = req.Role
	}

	member := &models.GroupMember{
		ID:       uuid.New(),
		GroupID:  groupID,
		UserID:   req.UserID,
		Role:     role,
		Status:   models.StatusActive,
		JoinedAt: time.Now(),
		Nickname: req.Nickname,
	}

	if err := s.repo.AddMember(ctx, member); err != nil {
		s.logger.Error("Failed to add member", zap.Error(err), zap.String("group_id", groupID.String()))
		return fmt.Errorf("failed to add member: %w", err)
	}

	s.logger.Info("Member added successfully", zap.String("group_id", groupID.String()), zap.String("user_id", req.UserID.String()))
	return nil
}

// RemoveMember 移除群组成员
func (s *groupService) RemoveMember(ctx context.Context, userID uuid.UUID, groupID, targetUserID uuid.UUID) error {
	// 不能移除自己，应该使用LeaveGroup
	if userID == targetUserID {
		return fmt.Errorf("use leave group to remove yourself")
	}

	// 检查权限
	if err := s.checkAdminPermission(ctx, userID, groupID); err != nil {
		return err
	}

	// 检查目标用户是否为群主
	targetMember, err := s.repo.GetMember(ctx, groupID, targetUserID)
	if err != nil {
		return fmt.Errorf("failed to get target member: %w", err)
	}
	if targetMember == nil {
		return fmt.Errorf("target user is not a member")
	}
	if targetMember.Role == models.RoleOwner {
		return fmt.Errorf("cannot remove group owner")
	}

	// 移除成员
	if err := s.repo.RemoveMember(ctx, groupID, targetUserID); err != nil {
		s.logger.Error("Failed to remove member", zap.Error(err), zap.String("group_id", groupID.String()))
		return fmt.Errorf("failed to remove member: %w", err)
	}

	s.logger.Info("Member removed successfully", zap.String("group_id", groupID.String()), zap.String("target_user_id", targetUserID.String()))
	return nil
}

// UpdateMember 更新群组成员信息
func (s *groupService) UpdateMember(ctx context.Context, userID uuid.UUID, groupID, targetUserID uuid.UUID, req *models.UpdateMemberRequest) error {
	// 检查权限
	if err := s.checkAdminPermission(ctx, userID, groupID); err != nil {
		return err
	}

	// 检查目标用户是否为成员
	targetMember, err := s.repo.GetMember(ctx, groupID, targetUserID)
	if err != nil {
		return fmt.Errorf("failed to get target member: %w", err)
	}
	if targetMember == nil {
		return fmt.Errorf("target user is not a member")
	}

	// 不能修改群主
	if targetMember.Role == models.RoleOwner {
		return fmt.Errorf("cannot modify group owner")
	}

	// 构建更新字段
	updates := make(map[string]interface{})
	if req.Role != nil {
		updates["role"] = *req.Role
	}
	if req.Status != nil {
		updates["status"] = *req.Status
	}
	if req.Nickname != nil {
		updates["nickname"] = *req.Nickname
	}

	if len(updates) == 0 {
		return fmt.Errorf("no fields to update")
	}

	// 更新成员信息
	if err := s.repo.UpdateMember(ctx, groupID, targetUserID, updates); err != nil {
		s.logger.Error("Failed to update member", zap.Error(err), zap.String("group_id", groupID.String()))
		return fmt.Errorf("failed to update member: %w", err)
	}

	s.logger.Info("Member updated successfully", zap.String("group_id", groupID.String()), zap.String("target_user_id", targetUserID.String()))
	return nil
}

// GetGroupMembers 获取群组成员列表
func (s *groupService) GetGroupMembers(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) ([]*models.GroupMemberWithUser, error) {
	// 检查是否为成员
	isMember, err := s.repo.IsMember(ctx, groupID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return nil, fmt.Errorf("access denied: not a member")
	}

	members, err := s.repo.GetGroupMembers(ctx, groupID)
	if err != nil {
		return nil, fmt.Errorf("failed to get group members: %w", err)
	}
	return members, nil
}

// LeaveGroup 离开群组
func (s *groupService) LeaveGroup(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error {
	// 检查是否为成员
	member, err := s.repo.GetMember(ctx, groupID, userID)
	if err != nil {
		return fmt.Errorf("failed to get member: %w", err)
	}
	if member == nil {
		return fmt.Errorf("not a member of this group")
	}

	// 群主不能直接离开，需要先转让群主权限或解散群组
	if member.Role == models.RoleOwner {
		return fmt.Errorf("group owner cannot leave, transfer ownership or delete group first")
	}

	// 移除成员
	if err := s.repo.RemoveMember(ctx, groupID, userID); err != nil {
		s.logger.Error("Failed to leave group", zap.Error(err), zap.String("group_id", groupID.String()))
		return fmt.Errorf("failed to leave group: %w", err)
	}

	s.logger.Info("User left group successfully", zap.String("group_id", groupID.String()), zap.String("user_id", userID.String()))
	return nil
}

// InviteUser 邀请用户加入群组
func (s *groupService) InviteUser(ctx context.Context, userID uuid.UUID, groupID uuid.UUID, req *models.InviteRequest) (*models.GroupInvitation, error) {
	// 检查权限
	if err := s.checkMemberPermission(ctx, userID, groupID); err != nil {
		return nil, err
	}

	// 检查目标用户是否已经是成员
	isMember, err := s.repo.IsMember(ctx, groupID, req.UserID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if isMember {
		return nil, fmt.Errorf("user is already a member")
	}

	// 创建邀请
	invitation := &models.GroupInvitation{
		ID:        uuid.New(),
		GroupID:   groupID,
		InviterID: userID,
		InviteeID: req.UserID,
		Status:    models.InvitationPending,
		Message:   req.Message,
		CreatedAt: time.Now(),
		ExpiresAt: time.Now().Add(7 * 24 * time.Hour), // 7天后过期
	}

	if err := s.repo.CreateInvitation(ctx, invitation); err != nil {
		s.logger.Error("Failed to create invitation", zap.Error(err), zap.String("group_id", groupID.String()))
		return nil, fmt.Errorf("failed to create invitation: %w", err)
	}

	s.logger.Info("Invitation created successfully", zap.String("invitation_id", invitation.ID.String()))
	return invitation, nil
}

// AcceptInvitation 接受邀请
func (s *groupService) AcceptInvitation(ctx context.Context, userID uuid.UUID, invitationID uuid.UUID) error {
	// 获取邀请信息
	invitation, err := s.repo.GetInvitation(ctx, invitationID)
	if err != nil {
		return fmt.Errorf("failed to get invitation: %w", err)
	}
	if invitation == nil {
		return fmt.Errorf("invitation not found")
	}

	// 验证邀请
	if invitation.InviteeID != userID {
		return fmt.Errorf("invitation not for this user")
	}
	if invitation.Status != models.InvitationPending {
		return fmt.Errorf("invitation is not pending")
	}
	if time.Now().After(invitation.ExpiresAt) {
		return fmt.Errorf("invitation has expired")
	}

	// 检查是否已经是成员
	isMember, err := s.repo.IsMember(ctx, invitation.GroupID, userID)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if isMember {
		return fmt.Errorf("already a member of this group")
	}

	// 检查群组成员数量限制
	group, err := s.repo.GetGroupByID(ctx, invitation.GroupID)
	if err != nil {
		return fmt.Errorf("failed to get group: %w", err)
	}
	if group == nil {
		return fmt.Errorf("group not found")
	}

	memberCount, err := s.repo.GetMemberCount(ctx, invitation.GroupID)
	if err != nil {
		return fmt.Errorf("failed to get member count: %w", err)
	}
	if memberCount >= group.MaxMembers {
		return fmt.Errorf("group has reached maximum member limit")
	}

	// 添加成员
	member := &models.GroupMember{
		ID:       uuid.New(),
		GroupID:  invitation.GroupID,
		UserID:   userID,
		Role:     models.RoleMember,
		Status:   models.StatusActive,
		JoinedAt: time.Now(),
	}

	if err := s.repo.AddMember(ctx, member); err != nil {
		s.logger.Error("Failed to add member", zap.Error(err), zap.String("group_id", invitation.GroupID.String()))
		return fmt.Errorf("failed to add member: %w", err)
	}

	// 更新邀请状态
	if err := s.repo.UpdateInvitationStatus(ctx, invitationID, models.InvitationAccepted); err != nil {
		s.logger.Error("Failed to update invitation status", zap.Error(err), zap.String("invitation_id", invitationID.String()))
		// 不返回错误，因为成员已经添加成功
	}

	s.logger.Info("Invitation accepted successfully", zap.String("invitation_id", invitationID.String()), zap.String("user_id", userID.String()))
	return nil
}

// RejectInvitation 拒绝邀请
func (s *groupService) RejectInvitation(ctx context.Context, userID uuid.UUID, invitationID uuid.UUID) error {
	// 获取邀请信息
	invitation, err := s.repo.GetInvitation(ctx, invitationID)
	if err != nil {
		return fmt.Errorf("failed to get invitation: %w", err)
	}
	if invitation == nil {
		return fmt.Errorf("invitation not found")
	}

	// 验证邀请
	if invitation.InviteeID != userID {
		return fmt.Errorf("invitation not for this user")
	}
	if invitation.Status != models.InvitationPending {
		return fmt.Errorf("invitation is not pending")
	}

	// 更新邀请状态
	if err := s.repo.UpdateInvitationStatus(ctx, invitationID, models.InvitationRejected); err != nil {
		s.logger.Error("Failed to update invitation status", zap.Error(err), zap.String("invitation_id", invitationID.String()))
		return fmt.Errorf("failed to reject invitation: %w", err)
	}

	s.logger.Info("Invitation rejected successfully", zap.String("invitation_id", invitationID.String()), zap.String("user_id", userID.String()))
	return nil
}

// GetPendingInvitations 获取待处理邀请
func (s *groupService) GetPendingInvitations(ctx context.Context, userID uuid.UUID) ([]*models.GroupInvitation, error) {
	invitations, err := s.repo.GetPendingInvitations(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending invitations: %w", err)
	}
	return invitations, nil
}

// 权限检查方法

// checkOwnerPermission 检查群主权限
func (s *groupService) checkOwnerPermission(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error {
	member, err := s.repo.GetMember(ctx, groupID, userID)
	if err != nil {
		return fmt.Errorf("failed to get member: %w", err)
	}
	if member == nil {
		return fmt.Errorf("not a member of this group")
	}
	if member.Role != models.RoleOwner {
		return fmt.Errorf("access denied: owner permission required")
	}
	return nil
}

// checkAdminPermission 检查管理员权限
func (s *groupService) checkAdminPermission(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error {
	member, err := s.repo.GetMember(ctx, groupID, userID)
	if err != nil {
		return fmt.Errorf("failed to get member: %w", err)
	}
	if member == nil {
		return fmt.Errorf("not a member of this group")
	}
	if member.Role != models.RoleOwner && member.Role != models.RoleAdmin {
		return fmt.Errorf("access denied: admin permission required")
	}
	return nil
}

// checkMemberPermission 检查成员权限
func (s *groupService) checkMemberPermission(ctx context.Context, userID uuid.UUID, groupID uuid.UUID) error {
	isMember, err := s.repo.IsMember(ctx, groupID, userID)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return fmt.Errorf("access denied: not a member")
	}
	return nil
}

// 验证方法

// validateCreateGroupRequest 验证创建群组请求
func (s *groupService) validateCreateGroupRequest(req *models.CreateGroupRequest) error {
	if strings.TrimSpace(req.Name) == "" {
		return fmt.Errorf("group name is required")
	}
	if len(req.Name) > 50 {
		return fmt.Errorf("group name too long")
	}
	if len(req.Description) > 200 {
		return fmt.Errorf("group description too long")
	}
	if req.MaxMembers < 2 || req.MaxMembers > 500 {
		return fmt.Errorf("max members must be between 2 and 500")
	}
	return nil
}

// validateUpdateGroupRequest 验证更新群组请求
func (s *groupService) validateUpdateGroupRequest(req *models.UpdateGroupRequest) error {
	if req.Name != nil {
		if strings.TrimSpace(*req.Name) == "" {
			return fmt.Errorf("group name cannot be empty")
		}
		if len(*req.Name) > 50 {
			return fmt.Errorf("group name too long")
		}
	}
	if req.Description != nil && len(*req.Description) > 200 {
		return fmt.Errorf("group description too long")
	}
	if req.MaxMembers != nil && (*req.MaxMembers < 2 || *req.MaxMembers > 500) {
		return fmt.Errorf("max members must be between 2 and 500")
	}
	return nil
}
