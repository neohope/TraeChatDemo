package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/neohope/chatapp/message-service/internal/domain"
	"github.com/neohope/chatapp/message-service/pkg/auth"
	"go.uber.org/zap"
)

// MessageHandler 消息处理器
type MessageHandler struct {
	service    domain.MessageService
	jwtManager *auth.JWTManager
	logger     *zap.Logger
}

// NewMessageHandler 创建一个新的消息处理器
func NewMessageHandler(service domain.MessageService, jwtManager *auth.JWTManager, logger *zap.Logger) *MessageHandler {
	return &MessageHandler{
		service:    service,
		jwtManager: jwtManager,
		logger:     logger,
	}
}

// RegisterRoutes 注册路由
func (h *MessageHandler) RegisterRoutes(router *mux.Router) {
	// 公共API
	router.HandleFunc("/health", h.HealthCheck).Methods("GET")

	// 需要认证的API
	apiRouter := router.PathPrefix("/api/v1").Subrouter()
	apiRouter.Use(h.AuthMiddleware)

	// 消息相关API
	apiRouter.HandleFunc("/messages", h.SendMessage).Methods("POST")
	apiRouter.HandleFunc("/messages/{id}", h.GetMessage).Methods("GET")
	apiRouter.HandleFunc("/messages/{id}/status", h.UpdateMessageStatus).Methods("PUT")
	apiRouter.HandleFunc("/conversations/{id}/messages", h.GetConversationMessages).Methods("GET")

	// 会话相关API
	apiRouter.HandleFunc("/conversations", h.CreateConversation).Methods("POST")
	apiRouter.HandleFunc("/conversations", h.GetUserConversations).Methods("GET")
	apiRouter.HandleFunc("/conversations/{id}", h.GetConversation).Methods("GET")
}

// HealthCheck 健康检查
func (h *MessageHandler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]string{"status": "ok", "service": "message-service"})
}

// SendMessage 发送消息
func (h *MessageHandler) SendMessage(w http.ResponseWriter, r *http.Request) {
	userID, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req domain.SendMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	// 验证请求
	if req.Content == "" {
		respondError(w, http.StatusBadRequest, "message content is required")
		return
	}

	if req.ConversationID == "" {
		respondError(w, http.StatusBadRequest, "conversation ID is required")
		return
	}

	// 创建消息
	message := &domain.Message{
		ID:           uuid.New().String(),
		Conversation: req.ConversationID,
		SenderID:     userID,
		Type:         req.Type,
		Content:      req.Content,
		Metadata:     req.Metadata,
		Status:       domain.MessageStatusSent,
		CreatedAt:    time.Now().UTC(),
		UpdatedAt:    time.Now().UTC(),
		IsGroupChat:  req.IsGroupChat,
	}

	// 发送消息
	if err := h.service.SendMessage(r.Context(), message); err != nil {
		h.logger.Error("Failed to send message", zap.Error(err), zap.String("user_id", userID))
		respondError(w, http.StatusInternalServerError, "failed to send message")
		return
	}

	respondJSON(w, http.StatusCreated, message)
}

// GetMessage 获取消息
func (h *MessageHandler) GetMessage(w http.ResponseWriter, r *http.Request) {
	_, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// 获取消息ID
	vars := mux.Vars(r)
	messageID := vars["id"]
	if messageID == "" {
		respondError(w, http.StatusBadRequest, "message ID is required")
		return
	}

	// 获取消息
	message, err := h.service.GetMessage(r.Context(), messageID)
	if err != nil {
		h.logger.Error("Failed to get message", zap.Error(err), zap.String("message_id", messageID))
		respondError(w, http.StatusInternalServerError, "failed to get message")
		return
	}

	respondJSON(w, http.StatusOK, message)
}

// UpdateMessageStatus 更新消息状态
func (h *MessageHandler) UpdateMessageStatus(w http.ResponseWriter, r *http.Request) {
	_, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// 获取消息ID
	vars := mux.Vars(r)
	messageID := vars["id"]
	if messageID == "" {
		respondError(w, http.StatusBadRequest, "message ID is required")
		return
	}

	// 解析请求体
	var req struct {
		Status domain.MessageStatus `json:"status"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Status == "" {
		respondError(w, http.StatusBadRequest, "status is required")
		return
	}

	// 更新状态
	if err := h.service.UpdateMessageStatus(r.Context(), messageID, req.Status); err != nil {
		h.logger.Error("Failed to update message status",
			zap.Error(err),
			zap.String("message_id", messageID),
			zap.String("status", string(req.Status)),
		)
		respondError(w, http.StatusInternalServerError, "failed to update message status")
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"status": "updated"})
}

// GetConversationMessages 获取会话消息
func (h *MessageHandler) GetConversationMessages(w http.ResponseWriter, r *http.Request) {
	_, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// 获取会话ID
	vars := mux.Vars(r)
	conversationID := vars["id"]
	if conversationID == "" {
		respondError(w, http.StatusBadRequest, "conversation ID is required")
		return
	}

	// 获取分页参数
	limit, offset := h.getPaginationParams(r)

	// 获取消息
	messages, err := h.service.GetConversationMessages(r.Context(), conversationID, limit, offset)
	if err != nil {
		h.logger.Error("Failed to get conversation messages",
			zap.Error(err),
			zap.String("conversation_id", conversationID),
		)
		respondError(w, http.StatusInternalServerError, "failed to get conversation messages")
		return
	}

	respondJSON(w, http.StatusOK, messages)
}

// CreateConversation 创建会话
func (h *MessageHandler) CreateConversation(w http.ResponseWriter, r *http.Request) {
	userID, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req domain.CreateConversationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	// 验证请求
	if req.Type == "" {
		respondError(w, http.StatusBadRequest, "conversation type is required")
		return
	}

	if len(req.Participants) == 0 {
		respondError(w, http.StatusBadRequest, "at least one participant is required")
		return
	}

	// 确保当前用户在参与者列表中
	hasCurrentUser := false
	for _, participant := range req.Participants {
		if participant == userID {
			hasCurrentUser = true
			break
		}
	}

	if !hasCurrentUser {
		req.Participants = append(req.Participants, userID)
	}

	// 创建会话
	conversation := &domain.Conversation{
		ID:           uuid.New().String(),
		Type:         req.Type,
		Participants: req.Participants,
		CreatedAt:    time.Now().UTC(),
		UpdatedAt:    time.Now().UTC(),
	}

	if err := h.service.CreateConversation(r.Context(), conversation); err != nil {
		h.logger.Error("Failed to create conversation", zap.Error(err), zap.String("user_id", userID))
		respondError(w, http.StatusInternalServerError, "failed to create conversation")
		return
	}

	respondJSON(w, http.StatusCreated, conversation)
}

// GetUserConversations 获取用户会话列表
func (h *MessageHandler) GetUserConversations(w http.ResponseWriter, r *http.Request) {
	userID, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// 获取分页参数
	limit, offset := h.getPaginationParams(r)

	// 获取会话列表
	conversations, err := h.service.GetUserConversations(r.Context(), userID, limit, offset)
	if err != nil {
		h.logger.Error("Failed to get user conversations", zap.Error(err), zap.String("user_id", userID))
		respondError(w, http.StatusInternalServerError, "failed to get user conversations")
		return
	}

	respondJSON(w, http.StatusOK, conversations)
}

// GetConversation 获取会话
func (h *MessageHandler) GetConversation(w http.ResponseWriter, r *http.Request) {
	_, err := h.getUserIDFromContext(r.Context())
	if err != nil {
		respondError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// 获取会话ID
	vars := mux.Vars(r)
	conversationID := vars["id"]
	if conversationID == "" {
		respondError(w, http.StatusBadRequest, "conversation ID is required")
		return
	}

	// 获取会话
	conversation, err := h.service.GetConversation(r.Context(), conversationID)
	if err != nil {
		h.logger.Error("Failed to get conversation", zap.Error(err), zap.String("conversation_id", conversationID))
		respondError(w, http.StatusInternalServerError, "failed to get conversation")
		return
	}

	respondJSON(w, http.StatusOK, conversation)
}

// AuthMiddleware 认证中间件
func (h *MessageHandler) AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 从请求头获取令牌
		tokenString := r.Header.Get("Authorization")
		if tokenString == "" {
			respondError(w, http.StatusUnauthorized, "missing authorization header")
			return
		}

		// 移除Bearer前缀
		if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
			tokenString = tokenString[7:]
		}

		// 验证令牌
		claims, err := h.jwtManager.VerifyToken(tokenString)
		if err != nil {
			respondError(w, http.StatusUnauthorized, "invalid token")
			return
		}

		// 将用户ID添加到请求上下文
		ctx := context.WithValue(r.Context(), "user_id", claims.UserID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// 从上下文获取用户ID
func (h *MessageHandler) getUserIDFromContext(ctx context.Context) (string, error) {
	userID, ok := ctx.Value("user_id").(string)
	if !ok || userID == "" {
		return "", errors.New("user ID not found in context")
	}
	return userID, nil
}

// 获取分页参数
func (h *MessageHandler) getPaginationParams(r *http.Request) (int, int) {
	// 默认值
	limit := 20
	offset := 0

	// 从查询参数获取
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
			if limit > 100 {
				limit = 100 // 限制最大获取数量
			}
		}
	}

	if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
		if parsedOffset, err := strconv.Atoi(offsetStr); err == nil && parsedOffset >= 0 {
			offset = parsedOffset
		}
	}

	return limit, offset
}

// respondJSON 响应JSON数据
func respondJSON(w http.ResponseWriter, status int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"error":"failed to marshal response"}`)) // nolint: errcheck
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(response) // nolint: errcheck
}

// respondError 响应错误
func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}
