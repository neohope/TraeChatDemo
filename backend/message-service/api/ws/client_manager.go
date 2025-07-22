package ws

import (
	"encoding/json"
	"sync"
	"time"

	"go.uber.org/zap"
)

// ClientManager 客户端管理器
type ClientManager struct {
	clients    map[string]*Client // 客户端映射表，键为用户ID，值为客户端
	register   chan *Client       // 注册通道
	unregister chan *Client       // 注销通道
	broadcast  chan []byte        // 广播通道
	mutex      sync.RWMutex       // 读写锁
	logger     *zap.Logger        // 日志记录器
}

// NewClientManager 创建客户端管理器
func NewClientManager(logger *zap.Logger) *ClientManager {
	return &ClientManager{
		clients:    make(map[string]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan []byte),
		logger:     logger,
	}
}

// Start 启动客户端管理器
func (manager *ClientManager) Start() {
	manager.logger.Info("Starting WebSocket client manager")
	for {
		select {
		case client := <-manager.register:
			// 注册客户端
			manager.mutex.Lock()
			manager.clients[client.userID] = client
			manager.mutex.Unlock()
			manager.logger.Info("Client registered", zap.String("userID", client.userID))

			// 发送系统消息通知客户端连接成功
			systemMsg := WebSocketMessage{
				Type: WebSocketMessageTypeSystem,
				Data: SystemMessage{
					Type:    "connected",
					Content: "Connected to WebSocket server",
					Data:    map[string]interface{}{"timestamp": time.Now().Unix()},
				},
			}
			msgBytes, _ := json.Marshal(systemMsg)
			client.send <- msgBytes

		case client := <-manager.unregister:
			// 注销客户端
			manager.mutex.Lock()
			if _, ok := manager.clients[client.userID]; ok {
				delete(manager.clients, client.userID)
				close(client.send)
				manager.logger.Info("Client unregistered", zap.String("userID", client.userID))
			}
			manager.mutex.Unlock()

		case message := <-manager.broadcast:
			// 广播消息给所有客户端
			manager.mutex.RLock()
			for _, client := range manager.clients {
				select {
				case client.send <- message:
					// 消息发送成功
				default:
					// 消息发送失败，关闭客户端连接
					close(client.send)
					delete(manager.clients, client.userID)
				}
			}
			manager.mutex.RUnlock()
		}
	}
}

// Register 注册客户端
func (manager *ClientManager) Register(client *Client) {
	manager.register <- client
}

// Unregister 注销客户端
func (manager *ClientManager) Unregister(client *Client) {
	manager.unregister <- client
}

// Broadcast 广播消息给所有客户端
func (manager *ClientManager) Broadcast(message []byte) {
	manager.broadcast <- message
}

// SendToUser 发送消息给指定用户
func (manager *ClientManager) SendToUser(userID string, message []byte) bool {
	manager.mutex.RLock()
	defer manager.mutex.RUnlock()

	if client, ok := manager.clients[userID]; ok {
		client.send <- message
		return true
	}
	return false
}

// GetClient 获取指定用户的客户端
func (manager *ClientManager) GetClient(userID string) (*Client, bool) {
	manager.mutex.RLock()
	defer manager.mutex.RUnlock()

	client, ok := manager.clients[userID]
	return client, ok
}

// GetConnectedUsers 获取所有已连接的用户ID
func (manager *ClientManager) GetConnectedUsers() []string {
	manager.mutex.RLock()
	defer manager.mutex.RUnlock()

	userIDs := make([]string, 0, len(manager.clients))
	for userID := range manager.clients {
		userIDs = append(userIDs, userID)
	}
	return userIDs
}

// GetClientCount 获取客户端数量
func (manager *ClientManager) GetClientCount() int {
	manager.mutex.RLock()
	defer manager.mutex.RUnlock()

	return len(manager.clients)
}