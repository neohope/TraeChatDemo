package service

import (
	"context"
	"errors"
	"fmt"

	"go.uber.org/zap"

	"github.com/neohope/chatapp/user-service/internal/domain"
)

// FriendService 实现domain.FriendService接口
type FriendService struct {
	friendRepo domain.FriendRepository
	userRepo   domain.UserRepository
	logger     *zap.Logger
}

// NewFriendService 创建一个新的好友服务
func NewFriendService(friendRepo domain.FriendRepository, userRepo domain.UserRepository, logger *zap.Logger) domain.FriendService {
	return &FriendService{
		friendRepo: friendRepo,
		userRepo:   userRepo,
		logger:     logger,
	}
}

// SendFriendRequest 发送好友请求
func (s *FriendService) SendFriendRequest(ctx context.Context, fromUserID, toUserID, message string) error {
	// 验证用户不能给自己发送好友请求
	if fromUserID == toUserID {
		return errors.New("cannot send friend request to yourself")
	}

	// 验证目标用户是否存在
	toUser, err := s.userRepo.GetByID(ctx, toUserID)
	if err != nil {
		return fmt.Errorf("failed to get target user: %w", err)
	}
	if toUser == nil {
		return errors.New("target user not found")
	}

	// 检查是否已经是好友
	friendship, err := s.friendRepo.CheckFriendship(ctx, fromUserID, toUserID)
	if err != nil {
		return fmt.Errorf("failed to check friendship: %w", err)
	}
	if friendship != nil {
		return errors.New("users are already friends")
	}

	// 检查是否已存在待处理的好友请求
	existingRequest, err := s.friendRepo.CheckExistingFriendRequest(ctx, fromUserID, toUserID)
	if err != nil {
		return fmt.Errorf("failed to check existing friend request: %w", err)
	}
	if existingRequest != nil {
		return errors.New("friend request already exists")
	}

	// 创建好友请求
	request := &domain.FriendRequest{
		FromUserID: fromUserID,
		ToUserID:   toUserID,
		Message:    message,
		Status:     domain.FriendRequestStatusPending,
	}

	err = s.friendRepo.CreateFriendRequest(ctx, request)
	if err != nil {
		return fmt.Errorf("failed to create friend request: %w", err)
	}

	s.logger.Info("Friend request sent", 
		zap.String("from_user_id", fromUserID), 
		zap.String("to_user_id", toUserID),
		zap.String("request_id", request.ID))

	return nil
}

// AcceptFriendRequest 接受好友请求
func (s *FriendService) AcceptFriendRequest(ctx context.Context, requestID, userID string) error {
	// 获取好友请求
	request, err := s.friendRepo.GetFriendRequestByID(ctx, requestID)
	if err != nil {
		return fmt.Errorf("failed to get friend request: %w", err)
	}
	if request == nil {
		return errors.New("friend request not found")
	}

	// 验证用户是否有权限接受此请求
	if request.ToUserID != userID {
		return errors.New("unauthorized to accept this friend request")
	}

	// 验证请求状态
	if request.Status != domain.FriendRequestStatusPending {
		return errors.New("friend request is not pending")
	}

	// 更新请求状态为已接受
	err = s.friendRepo.UpdateFriendRequestStatus(ctx, requestID, domain.FriendRequestStatusAccepted)
	if err != nil {
		return fmt.Errorf("failed to update friend request status: %w", err)
	}

	// 创建好友关系
	friendship := &domain.Friendship{
		User1ID: request.FromUserID,
		User2ID: request.ToUserID,
	}

	err = s.friendRepo.CreateFriendship(ctx, friendship)
	if err != nil {
		return fmt.Errorf("failed to create friendship: %w", err)
	}

	s.logger.Info("Friend request accepted", 
		zap.String("request_id", requestID),
		zap.String("user_id", userID),
		zap.String("friendship_id", friendship.ID))

	return nil
}

// RejectFriendRequest 拒绝好友请求
func (s *FriendService) RejectFriendRequest(ctx context.Context, requestID, userID string) error {
	// 获取好友请求
	request, err := s.friendRepo.GetFriendRequestByID(ctx, requestID)
	if err != nil {
		return fmt.Errorf("failed to get friend request: %w", err)
	}
	if request == nil {
		return errors.New("friend request not found")
	}

	// 验证用户是否有权限拒绝此请求
	if request.ToUserID != userID {
		return errors.New("unauthorized to reject this friend request")
	}

	// 验证请求状态
	if request.Status != domain.FriendRequestStatusPending {
		return errors.New("friend request is not pending")
	}

	// 更新请求状态为已拒绝
	err = s.friendRepo.UpdateFriendRequestStatus(ctx, requestID, domain.FriendRequestStatusRejected)
	if err != nil {
		return fmt.Errorf("failed to update friend request status: %w", err)
	}

	s.logger.Info("Friend request rejected", 
		zap.String("request_id", requestID),
		zap.String("user_id", userID))

	return nil
}

// GetPendingFriendRequests 获取待处理的好友请求
func (s *FriendService) GetPendingFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequest, error) {
	requests, err := s.friendRepo.GetPendingFriendRequests(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending friend requests: %w", err)
	}

	return requests, nil
}

// GetSentFriendRequests 获取已发送的好友请求
func (s *FriendService) GetSentFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequest, error) {
	requests, err := s.friendRepo.GetSentFriendRequests(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get sent friend requests: %w", err)
	}

	return requests, nil
}

// GetFriends 获取好友列表
func (s *FriendService) GetFriends(ctx context.Context, userID string) ([]*domain.User, error) {
	friendships, err := s.friendRepo.GetFriendships(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get friendships: %w", err)
	}

	var friends []*domain.User
	for _, friendship := range friendships {
		// 确定哪个用户是好友（不是当前用户）
		if friendship.User1ID == userID {
			friends = append(friends, friendship.User2)
		} else {
			friends = append(friends, friendship.User1)
		}
	}

	return friends, nil
}

// RemoveFriend 移除好友
func (s *FriendService) RemoveFriend(ctx context.Context, userID, friendID string) error {
	// 检查好友关系是否存在
	friendship, err := s.friendRepo.CheckFriendship(ctx, userID, friendID)
	if err != nil {
		return fmt.Errorf("failed to check friendship: %w", err)
	}
	if friendship == nil {
		return errors.New("friendship not found")
	}

	// 删除好友关系
	err = s.friendRepo.DeleteFriendship(ctx, userID, friendID)
	if err != nil {
		return fmt.Errorf("failed to delete friendship: %w", err)
	}

	s.logger.Info("Friendship removed", 
		zap.String("user_id", userID),
		zap.String("friend_id", friendID))

	return nil
}

// CheckFriendship 检查两个用户是否为好友
func (s *FriendService) CheckFriendship(ctx context.Context, user1ID, user2ID string) (bool, error) {
	friendship, err := s.friendRepo.CheckFriendship(ctx, user1ID, user2ID)
	if err != nil {
		return false, fmt.Errorf("failed to check friendship: %w", err)
	}

	return friendship != nil, nil
}