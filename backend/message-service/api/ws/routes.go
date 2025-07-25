package ws

import (
	"github.com/gorilla/mux"
	"github.com/neohope/chatapp/message-service/internal/domain"
	"github.com/neohope/chatapp/message-service/pkg/auth"
	"go.uber.org/zap"
)

// RegisterRoutes 注册WebSocket路由
func RegisterRoutes(router *mux.Router, messageService domain.MessageService, jwtManager *auth.JWTManager, logger *zap.Logger) {
	// 创建WebSocket处理器
	websocketHandler := NewWebSocketHandler(messageService, jwtManager, logger)

	// 注册WebSocket路由
	router.HandleFunc("/ws", websocketHandler.ServeWS)

	logger.Info("WebSocket routes registered")
}
