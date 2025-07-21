package domain

import (
	"context"
	"time"
)

// MessageType 消息类型枚举
type MessageType string

const (
	MessageTypeText     MessageType = "text"
	MessageTypeImage    MessageType = "image"
	MessageTypeVideo    MessageType = "video"
	MessageTypeAudio    MessageType = "audio"
	MessageTypeFile     MessageType = "file"
	MessageTypeLocation MessageType = "location"
	MessageTypeSystem   MessageType = "system"
)

// MessageStatus 消息状态枚举
type MessageStatus string

const (
	MessageStatusSent      MessageStatus = "sent"
	MessageStatusDelivered MessageStatus = "delivered"
	MessageStatusRead      MessageStatus = "read"
	MessageStatusFailed    MessageStatus = "failed"
)

// Message 消息实体
type Message struct {
	ID           string         `json:"id"`
	Conversation string         `json:"conversation_id"` // 可以是用户ID（私聊）或群组ID（群聊）
	SenderID     string         `json:"sender_id"`
	Type         MessageType    `json:"type"`
	Content      string         `json:"content"`
	Metadata     map[string]any `json:"metadata,omitempty"` // 附加信息，如图片尺寸、文件大小等
	Status       MessageStatus  `json:"status"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	IsGroupChat  bool           `json:"is_group_chat"`
}

// Conversation 会话实体
type Conversation struct {
	ID           string    `json:"id"`
	Type         string    `json:"type"` // "private" 或 "group"
	Participants []string  `json:"participants"`
	LastMessage  *Message  `json:"last_message,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// MessageRepository 消息仓库接口
type MessageRepository interface {
	Create(ctx context.Context, message *Message) error
	GetByID(ctx context.Context, id string) (*Message, error)
	UpdateStatus(ctx context.Context, id string, status MessageStatus) error
	GetConversationMessages(ctx context.Context, conversationID string, limit, offset int) ([]*Message, error)
	GetUserConversations(ctx context.Context, userID string, limit, offset int) ([]*Conversation, error)
	CreateConversation(ctx context.Context, conversation *Conversation) error
	GetConversation(ctx context.Context, id string) (*Conversation, error)
	UpdateConversationLastMessage(ctx context.Context, conversationID string, message *Message) error
}

// MessageService 消息服务接口
type MessageService interface {
	SendMessage(ctx context.Context, message *Message) error
	GetMessage(ctx context.Context, id string) (*Message, error)
	UpdateMessageStatus(ctx context.Context, id string, status MessageStatus) error
	GetConversationMessages(ctx context.Context, conversationID string, limit, offset int) ([]*Message, error)
	GetUserConversations(ctx context.Context, userID string, limit, offset int) ([]*Conversation, error)
	CreateConversation(ctx context.Context, conversation *Conversation) error
	GetConversation(ctx context.Context, id string) (*Conversation, error)
}

// SendMessageRequest 发送消息请求
type SendMessageRequest struct {
	ConversationID string         `json:"conversation_id"`
	Type           MessageType    `json:"type" validate:"required"`
	Content        string         `json:"content" validate:"required"`
	Metadata       map[string]any `json:"metadata,omitempty"`
	IsGroupChat    bool           `json:"is_group_chat"`
}

// CreateConversationRequest 创建会话请求
type CreateConversationRequest struct {
	Type         string   `json:"type" validate:"required,oneof=private group"`
	Participants []string `json:"participants" validate:"required,min=1"`
}