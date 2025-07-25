package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/neohope/chatapp/message-service/internal/domain"
	"go.uber.org/zap"
)

// MessageRepository 消息仓库实现
type MessageRepository struct {
	db     *sqlx.DB
	logger *zap.Logger
}

// NewMessageRepository 创建一个新的消息仓库
func NewMessageRepository(db *sqlx.DB, logger *zap.Logger) domain.MessageRepository {
	return &MessageRepository{
		db:     db,
		logger: logger,
	}
}

// Create 创建一条新消息
func (r *MessageRepository) Create(ctx context.Context, message *domain.Message) error {
	if message.ID == "" {
		message.ID = uuid.New().String()
	}

	now := time.Now().UTC()
	if message.CreatedAt.IsZero() {
		message.CreatedAt = now
	}
	message.UpdatedAt = now

	metadataJSON, err := json.Marshal(message.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	query := `
	INSERT INTO messages (id, conversation_id, sender_id, type, content, metadata, status, created_at, updated_at, is_group_chat)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`

	_, err = r.db.ExecContext(
		ctx,
		query,
		message.ID,
		message.Conversation,
		message.SenderID,
		message.Type,
		message.Content,
		metadataJSON,
		message.Status,
		message.CreatedAt,
		message.UpdatedAt,
		message.IsGroupChat,
	)

	if err != nil {
		return fmt.Errorf("failed to create message: %w", err)
	}

	return nil
}

// GetByID 根据ID获取消息
func (r *MessageRepository) GetByID(ctx context.Context, id string) (*domain.Message, error) {
	query := `
	SELECT id, conversation_id, sender_id, type, content, metadata, status, created_at, updated_at, is_group_chat
	FROM messages
	WHERE id = $1
	`

	var message struct {
		ID           string               `db:"id"`
		Conversation string               `db:"conversation_id"`
		SenderID     string               `db:"sender_id"`
		Type         domain.MessageType   `db:"type"`
		Content      string               `db:"content"`
		Metadata     []byte               `db:"metadata"`
		Status       domain.MessageStatus `db:"status"`
		CreatedAt    time.Time            `db:"created_at"`
		UpdatedAt    time.Time            `db:"updated_at"`
		IsGroupChat  bool                 `db:"is_group_chat"`
	}

	err := r.db.GetContext(ctx, &message, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("message not found: %s", id)
		}
		return nil, fmt.Errorf("failed to get message: %w", err)
	}

	result := &domain.Message{
		ID:           message.ID,
		Conversation: message.Conversation,
		SenderID:     message.SenderID,
		Type:         message.Type,
		Content:      message.Content,
		Status:       message.Status,
		CreatedAt:    message.CreatedAt,
		UpdatedAt:    message.UpdatedAt,
		IsGroupChat:  message.IsGroupChat,
		Metadata:     make(map[string]any),
	}

	if len(message.Metadata) > 0 {
		if unmarshalErr := json.Unmarshal(message.Metadata, &result.Metadata); unmarshalErr != nil {
			r.logger.Warn("Failed to unmarshal message metadata", zap.Error(unmarshalErr), zap.String("message_id", id))
		}
	}

	return result, nil
}

// UpdateStatus 更新消息状态
func (r *MessageRepository) UpdateStatus(ctx context.Context, id string, status domain.MessageStatus) error {
	query := `
	UPDATE messages
	SET status = $1, updated_at = $2
	WHERE id = $3
	`

	_, err := r.db.ExecContext(ctx, query, status, time.Now().UTC(), id)
	if err != nil {
		return fmt.Errorf("failed to update message status: %w", err)
	}

	return nil
}

// GetConversationMessages 获取会话消息
func (r *MessageRepository) GetConversationMessages(ctx context.Context, conversationID string, limit, offset int) ([]*domain.Message, error) {
	query := `
	SELECT id, conversation_id, sender_id, type, content, metadata, status, created_at, updated_at, is_group_chat
	FROM messages
	WHERE conversation_id = $1
	ORDER BY created_at DESC
	LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryxContext(ctx, query, conversationID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get conversation messages: %w", err)
	}
	defer rows.Close()

	var messages []*domain.Message
	for rows.Next() {
		var msg struct {
			ID           string               `db:"id"`
			Conversation string               `db:"conversation_id"`
			SenderID     string               `db:"sender_id"`
			Type         domain.MessageType   `db:"type"`
			Content      string               `db:"content"`
			Metadata     []byte               `db:"metadata"`
			Status       domain.MessageStatus `db:"status"`
			CreatedAt    time.Time            `db:"created_at"`
			UpdatedAt    time.Time            `db:"updated_at"`
			IsGroupChat  bool                 `db:"is_group_chat"`
		}

		if scanErr := rows.StructScan(&msg); scanErr != nil {
			return nil, fmt.Errorf("failed to scan message: %w", scanErr)
		}

		message := &domain.Message{
			ID:           msg.ID,
			Conversation: msg.Conversation,
			SenderID:     msg.SenderID,
			Type:         msg.Type,
			Content:      msg.Content,
			Status:       msg.Status,
			CreatedAt:    msg.CreatedAt,
			UpdatedAt:    msg.UpdatedAt,
			IsGroupChat:  msg.IsGroupChat,
			Metadata:     make(map[string]any),
		}

		if len(msg.Metadata) > 0 {
			if unmarshalErr := json.Unmarshal(msg.Metadata, &message.Metadata); unmarshalErr != nil {
				r.logger.Warn("Failed to unmarshal message metadata", zap.Error(unmarshalErr), zap.String("message_id", msg.ID))
			}
		}

		messages = append(messages, message)
	}

	if rowsErr := rows.Err(); rowsErr != nil {
		return nil, fmt.Errorf("error iterating over messages: %w", rowsErr)
	}

	return messages, nil
}

// CreateConversation 创建会话
func (r *MessageRepository) CreateConversation(ctx context.Context, conversation *domain.Conversation) error {
	if conversation.ID == "" {
		conversation.ID = uuid.New().String()
	}

	now := time.Now().UTC()
	if conversation.CreatedAt.IsZero() {
		conversation.CreatedAt = now
	}
	conversation.UpdatedAt = now

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	// 创建会话
	query := `
	INSERT INTO conversations (id, type, created_at, updated_at)
	VALUES ($1, $2, $3, $4)
	`

	_, err = tx.ExecContext(
		ctx,
		query,
		conversation.ID,
		conversation.Type,
		conversation.CreatedAt,
		conversation.UpdatedAt,
	)

	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to create conversation: %w", err)
	}

	// 添加参与者
	for _, userID := range conversation.Participants {
		query := `
		INSERT INTO conversation_participants (conversation_id, user_id, joined_at)
		VALUES ($1, $2, $3)
		`

		_, err = tx.ExecContext(ctx, query, conversation.ID, userID, now)
		if err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to add participant: %w", err)
		}
	}

	if commitErr := tx.Commit(); commitErr != nil {
		return fmt.Errorf("failed to commit transaction: %w", commitErr)
	}

	return nil
}

// GetConversation 获取会话
func (r *MessageRepository) GetConversation(ctx context.Context, id string) (*domain.Conversation, error) {
	// 获取会话基本信息
	convQuery := `
	SELECT id, type, created_at, updated_at
	FROM conversations
	WHERE id = $1
	`

	var conv struct {
		ID        string    `db:"id"`
		Type      string    `db:"type"`
		CreatedAt time.Time `db:"created_at"`
		UpdatedAt time.Time `db:"updated_at"`
	}

	err := r.db.GetContext(ctx, &conv, convQuery, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("conversation not found: %s", id)
		}
		return nil, fmt.Errorf("failed to get conversation: %w", err)
	}

	// 获取参与者
	participantsQuery := `
	SELECT user_id
	FROM conversation_participants
	WHERE conversation_id = $1
	`

	var participants []string
	if selectErr := r.db.SelectContext(ctx, &participants, participantsQuery, id); selectErr != nil {
		return nil, fmt.Errorf("failed to get conversation participants: %w", selectErr)
	}

	// 获取最后一条消息
	lastMsgQuery := `
	SELECT id, conversation_id, sender_id, type, content, metadata, status, created_at, updated_at, is_group_chat
	FROM messages
	WHERE conversation_id = $1
	ORDER BY created_at DESC
	LIMIT 1
	`

	var lastMsg struct {
		ID           string               `db:"id"`
		Conversation string               `db:"conversation_id"`
		SenderID     string               `db:"sender_id"`
		Type         domain.MessageType   `db:"type"`
		Content      string               `db:"content"`
		Metadata     []byte               `db:"metadata"`
		Status       domain.MessageStatus `db:"status"`
		CreatedAt    time.Time            `db:"created_at"`
		UpdatedAt    time.Time            `db:"updated_at"`
		IsGroupChat  bool                 `db:"is_group_chat"`
	}

	var lastMessage *domain.Message
	err = r.db.GetContext(ctx, &lastMsg, lastMsgQuery, id)
	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to get last message: %w", err)
	}

	if err != sql.ErrNoRows {
		lastMessage = &domain.Message{
			ID:           lastMsg.ID,
			Conversation: lastMsg.Conversation,
			SenderID:     lastMsg.SenderID,
			Type:         lastMsg.Type,
			Content:      lastMsg.Content,
			Status:       lastMsg.Status,
			CreatedAt:    lastMsg.CreatedAt,
			UpdatedAt:    lastMsg.UpdatedAt,
			IsGroupChat:  lastMsg.IsGroupChat,
			Metadata:     make(map[string]any),
		}

		if len(lastMsg.Metadata) > 0 {
			if unmarshalErr := json.Unmarshal(lastMsg.Metadata, &lastMessage.Metadata); unmarshalErr != nil {
				r.logger.Warn("Failed to unmarshal message metadata", zap.Error(unmarshalErr), zap.String("message_id", lastMsg.ID))
			}
		}
	}

	return &domain.Conversation{
		ID:           conv.ID,
		Type:         conv.Type,
		Participants: participants,
		LastMessage:  lastMessage,
		CreatedAt:    conv.CreatedAt,
		UpdatedAt:    conv.UpdatedAt,
	}, nil
}

// GetUserConversations 获取用户的会话列表
func (r *MessageRepository) GetUserConversations(ctx context.Context, userID string, limit, offset int) ([]*domain.Conversation, error) {
	query := `
	SELECT c.id, c.type, c.created_at, c.updated_at
	FROM conversations c
	JOIN conversation_participants cp ON c.id = cp.conversation_id
	WHERE cp.user_id = $1
	ORDER BY c.updated_at DESC
	LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryxContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get user conversations: %w", err)
	}
	defer rows.Close()

	var conversations []*domain.Conversation
	for rows.Next() {
		var conv struct {
			ID        string    `db:"id"`
			Type      string    `db:"type"`
			CreatedAt time.Time `db:"created_at"`
			UpdatedAt time.Time `db:"updated_at"`
		}

		if scanErr := rows.StructScan(&conv); scanErr != nil {
			return nil, fmt.Errorf("failed to scan conversation: %w", scanErr)
		}

		// 获取会话详细信息
		conversation, err := r.GetConversation(ctx, conv.ID)
		if err != nil {
			r.logger.Warn("Failed to get conversation details", zap.Error(err), zap.String("conversation_id", conv.ID))
			continue
		}

		conversations = append(conversations, conversation)
	}

	if rowsErr := rows.Err(); rowsErr != nil {
		return nil, fmt.Errorf("error iterating over conversations: %w", rowsErr)
	}

	return conversations, nil
}

// UpdateConversationLastMessage 更新会话的最后一条消息
func (r *MessageRepository) UpdateConversationLastMessage(ctx context.Context, conversationID string, message *domain.Message) error {
	query := `
	UPDATE conversations
	SET updated_at = $1
	WHERE id = $2
	`

	_, err := r.db.ExecContext(ctx, query, time.Now().UTC(), conversationID)
	if err != nil {
		return fmt.Errorf("failed to update conversation last message: %w", err)
	}

	return nil
}
