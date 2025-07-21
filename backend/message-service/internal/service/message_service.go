package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/yourusername/chatapp/message-service/internal/domain"
	"go.uber.org/zap"
)

// MessageService 消息服务实现
type MessageService struct {
	repo   domain.MessageRepository
	logger *zap.Logger
}

// NewMessageService 创建一个新的消息服务
func NewMessageService(repo domain.MessageRepository, logger *zap.Logger) domain.MessageService {
	return &MessageService{
		repo:   repo,
		logger: logger,
	}
}

// SendMessage 发送消息
func (s *MessageService) SendMessage(ctx context.Context, message *domain.Message) error {
	// 验证消息
	if message.SenderID == "" {
		return errors.New("sender ID is required")
	}

	if message.Conversation == "" {
		return errors.New("conversation ID is required")
	}

	if message.Type == "" {
		return errors.New("message type is required")
	}

	if message.Content == "" {
		return errors.New("message content is required")
	}

	// 设置消息ID和时间
	if message.ID == "" {
		message.ID = uuid.New().String()
	}

	now := time.Now().UTC()
	if message.CreatedAt.IsZero() {
		message.CreatedAt = now
	}
	message.UpdatedAt = now

	// 设置初始状态
	if message.Status == "" {
		message.Status = domain.MessageStatusSent
	}

	// 保存消息
	if err := s.repo.Create(ctx, message); err != nil {
		return fmt.Errorf("failed to create message: %w", err)
	}

	// 更新会话的最后一条消息
	if err := s.repo.UpdateConversationLastMessage(ctx, message.Conversation, message); err != nil {
		s.logger.Warn("Failed to update conversation last message", 
			zap.Error(err), 
			zap.String("conversation_id", message.Conversation),
			zap.String("message_id", message.ID),
		)
	}

	return nil
}

// GetMessage 获取消息
func (s *MessageService) GetMessage(ctx context.Context, id string) (*domain.Message, error) {
	if id == "" {
		return nil, errors.New("message ID is required")
	}

	message, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get message: %w", err)
	}

	return message, nil
}

// UpdateMessageStatus 更新消息状态
func (s *MessageService) UpdateMessageStatus(ctx context.Context, id string, status domain.MessageStatus) error {
	if id == "" {
		return errors.New("message ID is required")
	}

	if status == "" {
		return errors.New("message status is required")
	}

	// 验证状态是否有效
	validStatus := false
	for _, s := range []domain.MessageStatus{
		domain.MessageStatusSent,
		domain.MessageStatusDelivered,
		domain.MessageStatusRead,
		domain.MessageStatusFailed,
	} {
		if status == s {
			validStatus = true
			break
		}
	}

	if !validStatus {
		return fmt.Errorf("invalid message status: %s", status)
	}

	// 更新状态
	if err := s.repo.UpdateStatus(ctx, id, status); err != nil {
		return fmt.Errorf("failed to update message status: %w", err)
	}

	return nil
}

// GetConversationMessages 获取会话消息
func (s *MessageService) GetConversationMessages(ctx context.Context, conversationID string, limit, offset int) ([]*domain.Message, error) {
	if conversationID == "" {
		return nil, errors.New("conversation ID is required")
	}

	// 设置默认值
	if limit <= 0 {
		limit = 20
	} else if limit > 100 {
		limit = 100 // 限制最大获取数量
	}

	if offset < 0 {
		offset = 0
	}

	messages, err := s.repo.GetConversationMessages(ctx, conversationID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get conversation messages: %w", err)
	}

	return messages, nil
}

// GetUserConversations 获取用户会话列表
func (s *MessageService) GetUserConversations(ctx context.Context, userID string, limit, offset int) ([]*domain.Conversation, error) {
	if userID == "" {
		return nil, errors.New("user ID is required")
	}

	// 设置默认值
	if limit <= 0 {
		limit = 20
	} else if limit > 100 {
		limit = 100 // 限制最大获取数量
	}

	if offset < 0 {
		offset = 0
	}

	conversations, err := s.repo.GetUserConversations(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get user conversations: %w", err)
	}

	return conversations, nil
}

// CreateConversation 创建会话
func (s *MessageService) CreateConversation(ctx context.Context, conversation *domain.Conversation) error {
	// 验证会话
	if conversation.Type == "" {
		return errors.New("conversation type is required")
	}

	if len(conversation.Participants) == 0 {
		return errors.New("conversation must have at least one participant")
	}

	// 设置会话ID和时间
	if conversation.ID == "" {
		conversation.ID = uuid.New().String()
	}

	now := time.Now().UTC()
	if conversation.CreatedAt.IsZero() {
		conversation.CreatedAt = now
	}
	conversation.UpdatedAt = now

	// 保存会话
	if err := s.repo.CreateConversation(ctx, conversation); err != nil {
		return fmt.Errorf("failed to create conversation: %w", err)
	}

	return nil
}

// GetConversation 获取会话
func (s *MessageService) GetConversation(ctx context.Context, id string) (*domain.Conversation, error) {
	if id == "" {
		return nil, errors.New("conversation ID is required")
	}

	conversation, err := s.repo.GetConversation(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get conversation: %w", err)
	}

	return conversation, nil
}