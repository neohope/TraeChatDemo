package ws

import (
	"time"
)

// MessageType 消息类型
type MessageType string

// 消息类型常量
const (
	MessageTypeText  MessageType = "text"  // 文本消息
	MessageTypeImage MessageType = "image" // 图片消息
	MessageTypeVoice MessageType = "voice" // 语音消息
	MessageTypeVideo MessageType = "video" // 视频消息
	MessageTypeFile  MessageType = "file"  // 文件消息
)

// MessageStatus 消息状态
type MessageStatus string

// 消息状态常量
const (
	MessageStatusSending   MessageStatus = "sending"   // 发送中
	MessageStatusSent      MessageStatus = "sent"      // 已发送
	MessageStatusDelivered MessageStatus = "delivered" // 已送达
	MessageStatusRead      MessageStatus = "read"      // 已读
	MessageStatusFailed    MessageStatus = "failed"    // 发送失败
)

// WebSocketMessageType WebSocket消息类型
type WebSocketMessageType string

// WebSocket消息类型常量
const (
	WebSocketMessageTypeMessage      WebSocketMessageType = "message"      // 聊天消息
	WebSocketMessageTypeNotification WebSocketMessageType = "notification" // 通知消息
	WebSocketMessageTypeSystem       WebSocketMessageType = "system"       // 系统消息
	WebSocketMessageTypePing         WebSocketMessageType = "ping"         // 心跳消息
	WebSocketMessageTypePong         WebSocketMessageType = "pong"         // 心跳响应
)

// WebSocketMessage WebSocket消息
type WebSocketMessage struct {
	Type WebSocketMessageType `json:"type"` // 消息类型
	Data interface{}          `json:"data"` // 消息数据
}

// Message 聊天消息
type Message struct {
	ID           string       `json:"id"`                     // 消息ID
	SenderID     string       `json:"senderId"`               // 发送者ID
	ReceiverID   *string      `json:"receiverId,omitempty"`   // 接收者ID（单聊）
	GroupID      *string      `json:"groupId,omitempty"`      // 群组ID（群聊）
	Type         MessageType  `json:"type"`                   // 消息类型
	Content      string       `json:"content"`                // 消息内容
	MediaURL     *string      `json:"mediaUrl,omitempty"`     // 媒体URL
	ThumbnailURL *string      `json:"thumbnailUrl,omitempty"` // 缩略图URL
	Status       MessageStatus `json:"status"`                 // 消息状态
	CreatedAt    time.Time    `json:"createdAt"`              // 创建时间
	UpdatedAt    time.Time    `json:"updatedAt"`              // 更新时间
}

// NotificationMessage 通知消息
type NotificationMessage struct {
	ID        string    `json:"id"`        // 通知ID
	UserID    string    `json:"userId"`    // 用户ID
	Title     string    `json:"title"`     // 通知标题
	Content   string    `json:"content"`   // 通知内容
	Type      string    `json:"type"`      // 通知类型
	IsRead    bool      `json:"isRead"`    // 是否已读
	CreatedAt time.Time `json:"createdAt"` // 创建时间
}

// SystemMessage 系统消息
type SystemMessage struct {
	Type    string      `json:"type"`    // 系统消息类型
	Content string      `json:"content"` // 系统消息内容
	Data    interface{} `json:"data"`    // 系统消息数据
}

// PingMessage 心跳消息
type PingMessage struct {
	Timestamp int64 `json:"timestamp"` // 时间戳
}

// PongMessage 心跳响应
type PongMessage struct {
	Timestamp int64 `json:"timestamp"` // 时间戳
}