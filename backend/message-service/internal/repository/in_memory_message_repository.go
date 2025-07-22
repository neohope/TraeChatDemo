package repository

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/yourusername/chatapp/message-service/internal/domain"
	"go.uber.org/zap"
)

var (
	ErrMessageNotFound = errors.New("message not found")
	ErrConversationNotFound = errors.New("conversation not found")
)

// InMemoryMessageRepository 内存消息仓库实现
type InMemoryMessageRepository struct {
	messages      map[string]*domain.Message
	conversations map[string]*domain.Conversation
	mutex         sync.RWMutex
	logger        *zap.Logger
}

// NewInMemoryMessageRepository 创建新的内存消息仓库
func NewInMemoryMessageRepository(logger *zap.Logger) domain.MessageRepository {
	return &InMemoryMessageRepository{
		messages:      make(map[string]*domain.Message),
		conversations: make(map[string]*domain.Conversation),
		logger:        logger,
	}
}

// Create 创建消息
func (r *InMemoryMessageRepository) Create(ctx context.Context, message *domain.Message) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	// 生成ID如果没有
	if message.ID == "" {
		message.ID = uuid.New().String()
	}

	// 设置时间戳
	now := time.Now()
	if message.CreatedAt.IsZero() {
		message.CreatedAt = now
	}
	message.UpdatedAt = now

	// 存储消息
	r.messages[message.ID] = message

	r.logger.Debug("Message created in memory", 
		zap.String("message_id", message.ID),
		zap.String("sender_id", message.SenderID),
		zap.String("type", string(message.Type)),
	)

	return nil
}

// GetByID 根据ID获取消息
func (r *InMemoryMessageRepository) GetByID(ctx context.Context, id string) (*domain.Message, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	message, exists := r.messages[id]
	if !exists {
		return nil, ErrMessageNotFound
	}

	return message, nil
}

// UpdateStatus 更新消息状态
func (r *InMemoryMessageRepository) UpdateStatus(ctx context.Context, id string, status domain.MessageStatus) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	message, exists := r.messages[id]
	if !exists {
		return ErrMessageNotFound
	}

	message.Status = status
	message.UpdatedAt = time.Now()

	r.logger.Debug("Message status updated in memory", 
		zap.String("message_id", id),
		zap.String("status", string(status)),
	)

	return nil
}

// GetConversationMessages 获取会话消息
func (r *InMemoryMessageRepository) GetConversationMessages(ctx context.Context, conversationID string, limit, offset int) ([]*domain.Message, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var messages []*domain.Message
	for _, msg := range r.messages {
		if msg.Conversation == conversationID {
			messages = append(messages, msg)
		}
	}

	// 简单的分页处理
	start := offset
	if start > len(messages) {
		return []*domain.Message{}, nil
	}

	end := start + limit
	if end > len(messages) {
		end = len(messages)
	}

	return messages[start:end], nil
}

// GetUserConversations 获取用户会话列表
func (r *InMemoryMessageRepository) GetUserConversations(ctx context.Context, userID string, limit, offset int) ([]*domain.Conversation, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var conversations []*domain.Conversation
	for _, conv := range r.conversations {
		// 检查用户是否在会话参与者中
		for _, participant := range conv.Participants {
			if participant == userID {
				conversations = append(conversations, conv)
				break
			}
		}
	}

	// 简单的分页处理
	start := offset
	if start > len(conversations) {
		return []*domain.Conversation{}, nil
	}

	end := start + limit
	if end > len(conversations) {
		end = len(conversations)
	}

	return conversations[start:end], nil
}

// CreateConversation 创建会话
func (r *InMemoryMessageRepository) CreateConversation(ctx context.Context, conversation *domain.Conversation) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if conversation.ID == "" {
		conversation.ID = uuid.New().String()
	}

	now := time.Now()
	if conversation.CreatedAt.IsZero() {
		conversation.CreatedAt = now
	}
	conversation.UpdatedAt = now

	r.conversations[conversation.ID] = conversation

	r.logger.Debug("Conversation created in memory", 
		zap.String("conversation_id", conversation.ID),
		zap.String("type", conversation.Type),
	)

	return nil
}

// GetConversation 获取会话
func (r *InMemoryMessageRepository) GetConversation(ctx context.Context, id string) (*domain.Conversation, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	conversation, exists := r.conversations[id]
	if !exists {
		return nil, ErrConversationNotFound
	}

	return conversation, nil
}

// UpdateConversationLastMessage 更新会话最后一条消息
func (r *InMemoryMessageRepository) UpdateConversationLastMessage(ctx context.Context, conversationID string, message *domain.Message) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	conversation, exists := r.conversations[conversationID]
	if !exists {
		return ErrConversationNotFound
	}

	conversation.LastMessage = message
	conversation.UpdatedAt = time.Now()

	r.logger.Debug("Conversation last message updated in memory", 
		zap.String("conversation_id", conversationID),
		zap.String("message_id", message.ID),
	)

	return nil
}