package ws

import (
	"bytes"
	"encoding/json"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

const (
	// 写入超时时间
	writeWait = 10 * time.Second

	// 读取超时时间
	pongWait = 60 * time.Second

	// 心跳间隔时间
	pingPeriod = (pongWait * 9) / 10

	// 最大消息大小
	maxMessageSize = 512 * 1024 // 512KB
)

var (
	// 换行符
	newline = []byte("\n")

	// 空格
	space = []byte(" ")
)

// Client 客户端连接
type Client struct {
	manager *ClientManager // 客户端管理器
	conn    *websocket.Conn // WebSocket连接
	userID  string          // 用户ID
	send    chan []byte     // 发送通道
	logger  *zap.Logger     // 日志记录器
}

// NewClient 创建客户端
func NewClient(manager *ClientManager, conn *websocket.Conn, userID string, logger *zap.Logger) *Client {
	return &Client{
		manager: manager,
		conn:    conn,
		userID:  userID,
		send:    make(chan []byte, 256),
		logger:  logger,
	}
}

// ReadPump 读取泵，从WebSocket连接读取消息
func (c *Client) ReadPump() {
	defer func() {
		c.manager.Unregister(c)
		c.conn.Close()
	}()

	// 设置连接参数
	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				c.logger.Error("Unexpected close error", zap.Error(err))
			}
			break
		}

		// 处理消息
		message = bytes.TrimSpace(bytes.Replace(message, newline, space, -1))
		c.handleMessage(message)
	}
}

// WritePump 写入泵，向WebSocket连接写入消息
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// 通道已关闭
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}

			w.Write(message)

			// 添加队列中的消息
			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write(newline)
				w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			// 发送心跳
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			pingMsg := WebSocketMessage{
				Type: WebSocketMessageTypePing,
				Data: PingMessage{
					Timestamp: time.Now().Unix(),
				},
			}
			pingBytes, _ := json.Marshal(pingMsg)

			if err := c.conn.WriteMessage(websocket.TextMessage, pingBytes); err != nil {
				return
			}
		}
	}
}

// handleMessage 处理接收到的消息
func (c *Client) handleMessage(message []byte) {
	// 解析消息
	var wsMessage WebSocketMessage
	if err := json.Unmarshal(message, &wsMessage); err != nil {
		c.logger.Error("Failed to unmarshal message", zap.Error(err))
		return
	}

	// 根据消息类型处理
	switch wsMessage.Type {
	case WebSocketMessageTypeMessage:
		// 处理聊天消息
		c.handleChatMessage(wsMessage)
	case WebSocketMessageTypePing:
		// 处理心跳消息
		c.handlePingMessage(wsMessage)
	case WebSocketMessageTypeSystem:
		// 处理系统消息
		c.handleSystemMessage(wsMessage)
	default:
		c.logger.Warn("Unknown message type", zap.String("type", string(wsMessage.Type)))
	}
}

// handleChatMessage 处理聊天消息
func (c *Client) handleChatMessage(wsMessage WebSocketMessage) {
	// 将消息数据转换为Message对象
	messageData, err := json.Marshal(wsMessage.Data)
	if err != nil {
		c.logger.Error("Failed to marshal message data", zap.Error(err))
		return
	}

	var message Message
	if err := json.Unmarshal(messageData, &message); err != nil {
		c.logger.Error("Failed to unmarshal message data", zap.Error(err))
		return
	}

	// 设置消息发送者ID
	message.SenderID = c.userID

	// 根据消息类型处理
	if message.GroupID != nil && *message.GroupID != "" {
		// 群聊消息
		c.handleGroupMessage(message)
	} else if message.ReceiverID != nil && *message.ReceiverID != "" {
		// 单聊消息
		c.handleDirectMessage(message)
	} else {
		c.logger.Warn("Invalid message: missing groupId or receiverId")
	}
}

// handleDirectMessage 处理单聊消息
func (c *Client) handleDirectMessage(message Message) {
	// 更新消息状态为已发送
	message.Status = MessageStatusSent
	message.CreatedAt = time.Now()
	message.UpdatedAt = time.Now()

	// 将消息发送给接收者
	responseMsg := WebSocketMessage{
		Type: WebSocketMessageTypeMessage,
		Data: message,
	}
	responseBytes, _ := json.Marshal(responseMsg)

	// 发送给接收者
	if message.ReceiverID != nil {
		receiverID := *message.ReceiverID
		if sent := c.manager.SendToUser(receiverID, responseBytes); sent {
			// 消息已发送给接收者，更新状态为已送达
			message.Status = MessageStatusDelivered
		}
	}

	// 发送给发送者（确认消息已发送）
	c.send <- responseBytes
}

// handleGroupMessage 处理群聊消息
func (c *Client) handleGroupMessage(message Message) {
	// 更新消息状态为已发送
	message.Status = MessageStatusSent
	message.CreatedAt = time.Now()
	message.UpdatedAt = time.Now()

	// 将消息封装为WebSocket消息
	responseMsg := WebSocketMessage{
		Type: WebSocketMessageTypeMessage,
		Data: message,
	}
	responseBytes, _ := json.Marshal(responseMsg)

	// TODO: 获取群组成员并发送消息
	// 这里需要调用群组服务获取群组成员列表
	// 然后将消息发送给所有群组成员

	// 暂时使用广播方式发送给所有连接的客户端
	c.manager.Broadcast(responseBytes)
}

// handlePingMessage 处理心跳消息
func (c *Client) handlePingMessage(wsMessage WebSocketMessage) {
	// 回复pong消息
	pongMsg := WebSocketMessage{
		Type: WebSocketMessageTypePong,
		Data: PongMessage{
			Timestamp: time.Now().Unix(),
		},
	}
	pongBytes, _ := json.Marshal(pongMsg)
	c.send <- pongBytes
}

// handleSystemMessage 处理系统消息
func (c *Client) handleSystemMessage(wsMessage WebSocketMessage) {
	// 处理系统消息
	c.logger.Info("Received system message", zap.Any("message", wsMessage.Data))
}