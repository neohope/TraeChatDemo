package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/neohope/chatapp/group-service/internal/models"
	"github.com/neohope/chatapp/group-service/internal/service"
	"github.com/neohope/chatapp/group-service/pkg/jwt"
	"go.uber.org/zap"
)

// GroupHandler 群组处理器
type GroupHandler struct {
	groupService service.GroupService
	jwtManager   *jwt.JWTManager
	logger       *zap.Logger
}

// NewGroupHandler 创建群组处理器
func NewGroupHandler(groupService service.GroupService, jwtManager *jwt.JWTManager, logger *zap.Logger) *GroupHandler {
	return &GroupHandler{
		groupService: groupService,
		jwtManager:   jwtManager,
		logger:       logger,
	}
}

// RegisterRoutes 注册路由
func (h *GroupHandler) RegisterRoutes(router *mux.Router) {
	// 群组管理
	router.HandleFunc("/groups", h.authMiddleware(h.CreateGroup)).Methods("POST")
	router.HandleFunc("/groups/{groupId}", h.authMiddleware(h.GetGroup)).Methods("GET")
	router.HandleFunc("/groups/{groupId}", h.authMiddleware(h.UpdateGroup)).Methods("PUT")
	router.HandleFunc("/groups/{groupId}", h.authMiddleware(h.DeleteGroup)).Methods("DELETE")
	router.HandleFunc("/groups/search", h.SearchGroups).Methods("GET")
	router.HandleFunc("/users/{userId}/groups", h.authMiddleware(h.GetUserGroups)).Methods("GET")

	// 成员管理
	router.HandleFunc("/groups/{groupId}/members", h.authMiddleware(h.AddMember)).Methods("POST")
	router.HandleFunc("/groups/{groupId}/members", h.authMiddleware(h.GetGroupMembers)).Methods("GET")
	router.HandleFunc("/groups/{groupId}/members/{userId}", h.authMiddleware(h.UpdateMember)).Methods("PUT")
	router.HandleFunc("/groups/{groupId}/members/{userId}", h.authMiddleware(h.RemoveMember)).Methods("DELETE")
	router.HandleFunc("/groups/{groupId}/leave", h.authMiddleware(h.LeaveGroup)).Methods("POST")

	// 邀请管理
	router.HandleFunc("/groups/{groupId}/invitations", h.authMiddleware(h.InviteUser)).Methods("POST")
	router.HandleFunc("/invitations/{invitationId}/accept", h.authMiddleware(h.AcceptInvitation)).Methods("POST")
	router.HandleFunc("/invitations/{invitationId}/reject", h.authMiddleware(h.RejectInvitation)).Methods("POST")
	router.HandleFunc("/users/{userId}/invitations", h.authMiddleware(h.GetPendingInvitations)).Methods("GET")

	// 健康检查
	router.HandleFunc("/health", h.HealthCheck).Methods("GET")
}

// CreateGroup 创建群组
func (h *GroupHandler) CreateGroup(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)

	var req models.CreateGroupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	group, err := h.groupService.CreateGroup(r.Context(), userID, &req)
	if err != nil {
		h.logger.Error("Failed to create group", zap.Error(err), zap.String("user_id", userID.String()))
		h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSONResponse(w, http.StatusCreated, group)
}

// GetGroup 获取群组信息
func (h *GroupHandler) GetGroup(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	group, err := h.groupService.GetGroup(r.Context(), userID, groupID)
	if err != nil {
		h.logger.Error("Failed to get group", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "not found") {
			h.writeErrorResponse(w, http.StatusNotFound, err.Error())
		} else if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, group)
}

// UpdateGroup 更新群组信息
func (h *GroupHandler) UpdateGroup(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	var req models.UpdateGroupRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	group, err := h.groupService.UpdateGroup(r.Context(), userID, groupID, &req)
	if err != nil {
		h.logger.Error("Failed to update group", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, group)
}

// DeleteGroup 删除群组
func (h *GroupHandler) DeleteGroup(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	if err := h.groupService.DeleteGroup(r.Context(), userID, groupID); err != nil {
		h.logger.Error("Failed to delete group", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Group deleted successfully"})
}

// SearchGroups 搜索群组
func (h *GroupHandler) SearchGroups(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))

	if limit <= 0 {
		limit = 20
	}
	if offset < 0 {
		offset = 0
	}

	groups, err := h.groupService.SearchGroups(r.Context(), query, limit, offset)
	if err != nil {
		h.logger.Error("Failed to search groups", zap.Error(err))
		h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSONResponse(w, http.StatusOK, groups)
}

// GetUserGroups 获取用户群组
func (h *GroupHandler) GetUserGroups(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	targetUserID, err := h.getUserIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	// 只能查看自己的群组
	if userID != targetUserID {
		h.writeErrorResponse(w, http.StatusForbidden, "Access denied")
		return
	}

	groups, err := h.groupService.GetUserGroups(r.Context(), userID)
	if err != nil {
		h.logger.Error("Failed to get user groups", zap.Error(err), zap.String("user_id", userID.String()))
		h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSONResponse(w, http.StatusOK, groups)
}

// AddMember 添加群组成员
func (h *GroupHandler) AddMember(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	var req models.AddMemberRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if err := h.groupService.AddMember(r.Context(), userID, groupID, &req); err != nil {
		h.logger.Error("Failed to add member", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else if strings.Contains(err.Error(), "already a member") || strings.Contains(err.Error(), "maximum member limit") {
			h.writeErrorResponse(w, http.StatusConflict, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Member added successfully"})
}

// GetGroupMembers 获取群组成员
func (h *GroupHandler) GetGroupMembers(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	members, err := h.groupService.GetGroupMembers(r.Context(), userID, groupID)
	if err != nil {
		h.logger.Error("Failed to get group members", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, members)
}

// UpdateMember 更新群组成员
func (h *GroupHandler) UpdateMember(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}
	targetUserID, err := h.getTargetUserIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	var req models.UpdateMemberRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if err := h.groupService.UpdateMember(r.Context(), userID, groupID, targetUserID, &req); err != nil {
		h.logger.Error("Failed to update member", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Member updated successfully"})
}

// RemoveMember 移除群组成员
func (h *GroupHandler) RemoveMember(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}
	targetUserID, err := h.getTargetUserIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	if err := h.groupService.RemoveMember(r.Context(), userID, groupID, targetUserID); err != nil {
		h.logger.Error("Failed to remove member", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Member removed successfully"})
}

// LeaveGroup 离开群组
func (h *GroupHandler) LeaveGroup(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	if err := h.groupService.LeaveGroup(r.Context(), userID, groupID); err != nil {
		h.logger.Error("Failed to leave group", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "group owner cannot leave") {
			h.writeErrorResponse(w, http.StatusConflict, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Left group successfully"})
}

// InviteUser 邀请用户
func (h *GroupHandler) InviteUser(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	groupID, err := h.getGroupIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	var req models.InviteRequest
	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	invitation, err := h.groupService.InviteUser(r.Context(), userID, groupID, &req)
	if err != nil {
		h.logger.Error("Failed to invite user", zap.Error(err), zap.String("group_id", groupID.String()))
		if strings.Contains(err.Error(), "access denied") {
			h.writeErrorResponse(w, http.StatusForbidden, err.Error())
		} else if strings.Contains(err.Error(), "already a member") {
			h.writeErrorResponse(w, http.StatusConflict, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusCreated, invitation)
}

// AcceptInvitation 接受邀请
func (h *GroupHandler) AcceptInvitation(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	invitationID, err := h.getInvitationIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid invitation ID")
		return
	}

	if err := h.groupService.AcceptInvitation(r.Context(), userID, invitationID); err != nil {
		h.logger.Error("Failed to accept invitation", zap.Error(err), zap.String("invitation_id", invitationID.String()))
		if strings.Contains(err.Error(), "not for this user") || strings.Contains(err.Error(), "not pending") || strings.Contains(err.Error(), "expired") {
			h.writeErrorResponse(w, http.StatusBadRequest, err.Error())
		} else if strings.Contains(err.Error(), "maximum member limit") {
			h.writeErrorResponse(w, http.StatusConflict, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Invitation accepted successfully"})
}

// RejectInvitation 拒绝邀请
func (h *GroupHandler) RejectInvitation(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	invitationID, err := h.getInvitationIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid invitation ID")
		return
	}

	if err := h.groupService.RejectInvitation(r.Context(), userID, invitationID); err != nil {
		h.logger.Error("Failed to reject invitation", zap.Error(err), zap.String("invitation_id", invitationID.String()))
		if strings.Contains(err.Error(), "not for this user") || strings.Contains(err.Error(), "not pending") {
			h.writeErrorResponse(w, http.StatusBadRequest, err.Error())
		} else {
			h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		}
		return
	}

	h.writeJSONResponse(w, http.StatusOK, map[string]string{"message": "Invitation rejected successfully"})
}

// GetPendingInvitations 获取待处理邀请
func (h *GroupHandler) GetPendingInvitations(w http.ResponseWriter, r *http.Request) {
	userID := h.getUserIDFromContext(r)
	targetUserID, err := h.getUserIDFromPath(r)
	if err != nil {
		h.writeErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	// 只能查看自己的邀请
	if userID != targetUserID {
		h.writeErrorResponse(w, http.StatusForbidden, "Access denied")
		return
	}

	invitations, err := h.groupService.GetPendingInvitations(r.Context(), userID)
	if err != nil {
		h.logger.Error("Failed to get pending invitations", zap.Error(err), zap.String("user_id", userID.String()))
		h.writeErrorResponse(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSONResponse(w, http.StatusOK, invitations)
}

// HealthCheck 健康检查
func (h *GroupHandler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	h.writeJSONResponse(w, http.StatusOK, map[string]string{
		"status":  "healthy",
		"service": "group-service",
	})
}

// 中间件和工具方法

// authMiddleware JWT认证中间件
func (h *GroupHandler) authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			h.writeErrorResponse(w, http.StatusUnauthorized, "Authorization header required")
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			h.writeErrorResponse(w, http.StatusUnauthorized, "Invalid authorization header format")
			return
		}

		claims, err := h.jwtManager.ValidateToken(tokenString)
		if err != nil {
			h.logger.Error("Failed to validate token", zap.Error(err))
			h.writeErrorResponse(w, http.StatusUnauthorized, "Invalid token")
			return
		}

		// 将用户信息添加到请求头中
		r.Header.Set("X-User-ID", claims.UserID.String())
		r.Header.Set("X-Username", claims.Username)
		r.Header.Set("X-Email", claims.Email)

		next(w, r)
	}
}

// getUserIDFromContext 从请求中获取用户ID
func (h *GroupHandler) getUserIDFromContext(r *http.Request) uuid.UUID {
	userIDStr := r.Header.Get("X-User-ID")
	userID, _ := uuid.Parse(userIDStr)
	return userID
}

// getGroupIDFromPath 从路径中获取群组ID
func (h *GroupHandler) getGroupIDFromPath(r *http.Request) (uuid.UUID, error) {
	vars := mux.Vars(r)
	return uuid.Parse(vars["groupId"])
}

// getUserIDFromPath 从路径中获取用户ID
func (h *GroupHandler) getUserIDFromPath(r *http.Request) (uuid.UUID, error) {
	vars := mux.Vars(r)
	return uuid.Parse(vars["userId"])
}

// getTargetUserIDFromPath 从路径中获取目标用户ID
func (h *GroupHandler) getTargetUserIDFromPath(r *http.Request) (uuid.UUID, error) {
	vars := mux.Vars(r)
	return uuid.Parse(vars["userId"])
}

// getInvitationIDFromPath 从路径中获取邀请ID
func (h *GroupHandler) getInvitationIDFromPath(r *http.Request) (uuid.UUID, error) {
	vars := mux.Vars(r)
	return uuid.Parse(vars["invitationId"])
}

// writeJSONResponse 写入JSON响应
func (h *GroupHandler) writeJSONResponse(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

// writeErrorResponse 写入错误响应
func (h *GroupHandler) writeErrorResponse(w http.ResponseWriter, statusCode int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}
