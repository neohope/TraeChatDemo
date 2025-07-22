package ws

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/yourusername/chatapp/message-service/internal/domain"
	"github.com/yourusername/chatapp/message-service/pkg/auth"
	"go.uber.org/zap"
)

// WebSocketHandler WebSocket处理器
type WebSocketHandler struct {
	clientManager  *ClientManager
	messageService domain.MessageService
	jwtManager     *auth.JWTManager
	logger         *zap.Logger
}

// 升级HTTP连接为WebSocket的配置
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// 在生产环境中应该检查Origin
		return true
	},
}

// NewWebSocketHandler 创建一个新的WebSocket处理器
func NewWebSocketHandler(messageService domain.MessageService, jwtManager *auth.JWTManager, logger *zap.Logger) *WebSocketHandler {
	// 创建客户端管理器
	clientManager := NewClientManager(logger)
	
	handler := &WebSocketHandler{
		clientManager:  clientManager,
		messageService: messageService,
		jwtManager:     jwtManager,
		logger:         logger,
	}

	// 启动客户端管理器
	go clientManager.Start()

	return handler
}

// SendToUser 发送消息给特定用户
func (h *WebSocketHandler) SendToUser(userID string, message interface{}) error {
	msgBytes, err := json.Marshal(message)
	if err != nil {
		return err
	}

	h.clientManager.SendToUser(userID, msgBytes)
	return nil
}

// BroadcastToAll 广播消息给所有连接的客户端
func (h *WebSocketHandler) BroadcastToAll(message interface{}) error {
	msgBytes, err := json.Marshal(message)
	if err != nil {
		return err
	}

	h.clientManager.Broadcast(msgBytes)
	return nil
}

// GetConnectedUsers 获取所有已连接的用户ID
func (h *WebSocketHandler) GetConnectedUsers() []string {
	return h.clientManager.GetConnectedUsers()
}

// GetClientCount 获取客户端数量
func (h *WebSocketHandler) GetClientCount() int {
	return h.clientManager.GetClientCount()
}

// ServeWS 处理WebSocket请求
func (h *WebSocketHandler) ServeWS(w http.ResponseWriter, r *http.Request) {
	// 从请求中获取token
	token := r.URL.Query().Get("token")
	if token == "" {
		h.logger.Warn("Missing token in WebSocket request")
		http.Error(w, "Missing authentication token", http.StatusUnauthorized)
		return
	}

	// 验证token
	claims, err := h.jwtManager.VerifyToken(token)
	if err != nil {
		h.logger.Warn("Invalid token", zap.Error(err))
		http.Error(w, "Invalid authentication token", http.StatusUnauthorized)
		return
	}

	// 升级HTTP连接为WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		h.logger.Error("Failed to upgrade connection to WebSocket", zap.Error(err))
		return
	}

	// 创建新客户端
	client := NewClient(h.clientManager, conn, claims.UserID, h.logger)

	// 注册客户端
	h.clientManager.Register(client)

	// 启动客户端的读写goroutines
	go client.ReadPump()
	go client.WritePump()
}