package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"github.com/neohope/chatapp/notification-service/internal/domain"
)

type Handler struct {
	notificationService domain.NotificationService
	logger              *zap.Logger
}

type CreateNotificationRequest struct {
	UserID string                 `json:"user_id"`
	Type   string                 `json:"type"`
	Title  string                 `json:"title"`
	Body   string                 `json:"body"`
	Data   map[string]interface{} `json:"data,omitempty"`
}

type SendPushRequest struct {
	UserID      string                 `json:"user_id"`
	DeviceToken string                 `json:"device_token,omitempty"`
	Title       string                 `json:"title"`
	Body        string                 `json:"body"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Badge       int                    `json:"badge,omitempty"`
	Sound       string                 `json:"sound,omitempty"`
}

type RegisterDeviceRequest struct {
	UserID      string `json:"user_id"`
	DeviceToken string `json:"device_token"`
	Platform    string `json:"platform"`
}

type UpdatePreferencesRequest struct {
	PushEnabled          bool `json:"push_enabled"`
	EmailEnabled         bool `json:"email_enabled"`
	MessageNotifications bool `json:"message_notifications"`
	GroupNotifications   bool `json:"group_notifications"`
	SystemNotifications  bool `json:"system_notifications"`
}

type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

func NewHandler(notificationService domain.NotificationService, logger *zap.Logger) *Handler {
	return &Handler{
		notificationService: notificationService,
		logger:              logger,
	}
}

func (h *Handler) RegisterRoutes(router *mux.Router) {
	// 健康检查
	router.HandleFunc("/health", h.HealthCheck).Methods("GET")

	// 通知相关路由
	router.HandleFunc("/notifications", h.CreateNotification).Methods("POST")
	router.HandleFunc("/notifications", h.GetNotifications).Methods("GET")
	router.HandleFunc("/notifications/{id}/read", h.MarkAsRead).Methods("PUT")
	router.HandleFunc("/notifications/unread-count", h.GetUnreadCount).Methods("GET")

	// 推送通知路由
	router.HandleFunc("/push", h.SendPushNotification).Methods("POST")

	// 设备管理路由
	router.HandleFunc("/devices", h.RegisterDevice).Methods("POST")
	router.HandleFunc("/devices", h.UnregisterDevice).Methods("DELETE")

	// 偏好设置路由
	router.HandleFunc("/preferences", h.GetPreferences).Methods("GET")
	router.HandleFunc("/preferences", h.UpdatePreferences).Methods("PUT")
}

func (h *Handler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Success: true,
		Message: "Notification service is healthy",
	})
}

func (h *Handler) CreateNotification(w http.ResponseWriter, r *http.Request) {
	var req CreateNotificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// 验证必填字段
	if req.UserID == "" || req.Title == "" || req.Body == "" {
		h.respondError(w, http.StatusBadRequest, "Missing required fields")
		return
	}

	notification := &domain.Notification{
		UserID: req.UserID,
		Type:   domain.NotificationType(req.Type),
		Title:  req.Title,
		Body:   req.Body,
		Data:   req.Data,
	}

	if err := h.notificationService.SendNotification(notification); err != nil {
		h.logger.Error("Failed to send notification", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to send notification")
		return
	}

	h.respondSuccess(w, notification, "Notification sent successfully")
}

func (h *Handler) GetNotifications(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserID(r)
	if userID == "" {
		h.respondError(w, http.StatusUnauthorized, "User ID required")
		return
	}

	// 解析分页参数
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	notifications, err := h.notificationService.GetNotifications(userID, limit, offset)
	if err != nil {
		h.logger.Error("Failed to get notifications", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to get notifications")
		return
	}

	h.respondSuccess(w, notifications, "")
}

func (h *Handler) MarkAsRead(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	notificationID := vars["id"]

	if err := h.notificationService.MarkAsRead(notificationID); err != nil {
		h.logger.Error("Failed to mark notification as read", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to mark notification as read")
		return
	}

	h.respondSuccess(w, nil, "Notification marked as read")
}

func (h *Handler) GetUnreadCount(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserID(r)
	if userID == "" {
		h.respondError(w, http.StatusUnauthorized, "User ID required")
		return
	}

	count, err := h.notificationService.GetUnreadCount(userID)
	if err != nil {
		h.logger.Error("Failed to get unread count", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to get unread count")
		return
	}

	h.respondSuccess(w, map[string]int{"count": count}, "")
}

func (h *Handler) SendPushNotification(w http.ResponseWriter, r *http.Request) {
	var req SendPushRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.UserID == "" || req.Title == "" {
		h.respondError(w, http.StatusBadRequest, "Missing required fields")
		return
	}

	pushNotification := &domain.PushNotification{
		DeviceToken: req.DeviceToken,
		Title:       req.Title,
		Body:        req.Body,
		Data:        req.Data,
		Badge:       req.Badge,
		Sound:       req.Sound,
	}

	if req.Sound == "" {
		pushNotification.Sound = "default"
	}

	if err := h.notificationService.SendPushNotification(req.UserID, pushNotification); err != nil {
		h.logger.Error("Failed to send push notification", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to send push notification")
		return
	}

	h.respondSuccess(w, nil, "Push notification sent successfully")
}

func (h *Handler) RegisterDevice(w http.ResponseWriter, r *http.Request) {
	var req RegisterDeviceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.UserID == "" || req.DeviceToken == "" || req.Platform == "" {
		h.respondError(w, http.StatusBadRequest, "Missing required fields")
		return
	}

	if err := h.notificationService.RegisterDevice(req.UserID, req.DeviceToken, req.Platform); err != nil {
		h.logger.Error("Failed to register device", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to register device")
		return
	}

	h.respondSuccess(w, nil, "Device registered successfully")
}

func (h *Handler) UnregisterDevice(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("user_id")
	deviceToken := r.URL.Query().Get("device_token")

	if userID == "" || deviceToken == "" {
		h.respondError(w, http.StatusBadRequest, "Missing user_id or device_token")
		return
	}

	if err := h.notificationService.UnregisterDevice(userID, deviceToken); err != nil {
		h.logger.Error("Failed to unregister device", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to unregister device")
		return
	}

	h.respondSuccess(w, nil, "Device unregistered successfully")
}

func (h *Handler) GetPreferences(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserID(r)
	if userID == "" {
		h.respondError(w, http.StatusUnauthorized, "User ID required")
		return
	}

	preferences, err := h.notificationService.GetPreferences(userID)
	if err != nil {
		h.logger.Error("Failed to get preferences", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to get preferences")
		return
	}

	h.respondSuccess(w, preferences, "")
}

func (h *Handler) UpdatePreferences(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserID(r)
	if userID == "" {
		h.respondError(w, http.StatusUnauthorized, "User ID required")
		return
	}

	var req UpdatePreferencesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	preferences := &domain.NotificationPreference{
		UserID:               userID,
		PushEnabled:          req.PushEnabled,
		EmailEnabled:         req.EmailEnabled,
		MessageNotifications: req.MessageNotifications,
		GroupNotifications:   req.GroupNotifications,
		SystemNotifications:  req.SystemNotifications,
	}

	if err := h.notificationService.UpdatePreferences(userID, preferences); err != nil {
		h.logger.Error("Failed to update preferences", zap.Error(err))
		h.respondError(w, http.StatusInternalServerError, "Failed to update preferences")
		return
	}

	h.respondSuccess(w, preferences, "Preferences updated successfully")
}

func (h *Handler) getUserID(r *http.Request) string {
	// 从请求头中获取用户ID（由API Gateway注入）
	return r.Header.Get("X-User-ID")
}

func (h *Handler) respondSuccess(w http.ResponseWriter, data interface{}, message string) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Success: true,
		Message: message,
		Data:    data,
	})
}

func (h *Handler) respondError(w http.ResponseWriter, statusCode int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(Response{
		Success: false,
		Error:   message,
	})
}
