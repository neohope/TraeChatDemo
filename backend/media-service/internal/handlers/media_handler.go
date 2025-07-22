package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"media-service/internal/models"
	"media-service/internal/service"
	"media-service/pkg/auth"
	"media-service/pkg/response"
)

// MediaHandler 媒体处理器
type MediaHandler struct {
	mediaService service.MediaService
	logger       *zap.Logger
}

// NewMediaHandler 创建媒体处理器
func NewMediaHandler(mediaService service.MediaService, logger *zap.Logger) *MediaHandler {
	return &MediaHandler{
		mediaService: mediaService,
		logger:       logger,
	}
}

// RegisterRoutes 注册路由
func (h *MediaHandler) RegisterRoutes(router *mux.Router) {
	// 需要认证的路由
	authRouter := router.PathPrefix("/api/v1/media").Subrouter()
	authRouter.Use(auth.JWTMiddleware)

	// 文件上传
	authRouter.HandleFunc("/upload", h.UploadFile).Methods("POST")

	// 媒体文件管理
	authRouter.HandleFunc("/files", h.GetMediaList).Methods("GET")
	authRouter.HandleFunc("/files/{id}", h.GetMedia).Methods("GET")
	authRouter.HandleFunc("/files/{id}", h.UpdateMedia).Methods("PUT")
	authRouter.HandleFunc("/files/{id}", h.DeleteMedia).Methods("DELETE")

	// 缩略图生成
	authRouter.HandleFunc("/files/{id}/thumbnail", h.GenerateThumbnail).Methods("POST")

	// 预签名URL
	authRouter.HandleFunc("/files/{id}/presigned-url", h.GetPresignedURL).Methods("GET")

	// 处理任务
	authRouter.HandleFunc("/jobs/{id}", h.GetProcessingJobStatus).Methods("GET")

	// 存储统计
	authRouter.HandleFunc("/stats/user", h.GetUserStorageStats).Methods("GET")
	authRouter.HandleFunc("/stats/system", h.GetSystemStorageStats).Methods("GET")

	// 公共路由（不需要认证）
	publicRouter := router.PathPrefix("/api/v1/media").Subrouter()

	// 健康检查
	publicRouter.HandleFunc("/health", h.HealthCheck).Methods("GET")

	// 文件服务（如果使用本地存储）
	publicRouter.PathPrefix("/files/").Handler(http.StripPrefix("/api/v1/media/files/", http.FileServer(http.Dir("./uploads/"))))
}

// UploadFile 上传文件
func (h *MediaHandler) UploadFile(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	// 解析multipart表单
	err := r.ParseMultipartForm(32 << 20) // 32MB
	if err != nil {
		h.logger.Error("Failed to parse multipart form", zap.Error(err))
		response.Error(w, http.StatusBadRequest, "Failed to parse form", nil)
		return
	}

	// 获取文件
	file, header, err := r.FormFile("file")
	if err != nil {
		h.logger.Error("Failed to get file from form", zap.Error(err))
		response.Error(w, http.StatusBadRequest, "No file provided", nil)
		return
	}
	defer file.Close()

	// 上传文件
	uploadResponse, err := h.mediaService.UploadFile(userID, file, header)
	if err != nil {
		h.logger.Error("Failed to upload file",
			zap.String("user_id", userID),
			zap.String("filename", header.Filename),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "quota") || strings.Contains(err.Error(), "limit") {
			response.Error(w, http.StatusPaymentRequired, err.Error(), nil)
		} else if strings.Contains(err.Error(), "not allowed") {
			response.Error(w, http.StatusUnsupportedMediaType, err.Error(), nil)
		} else if strings.Contains(err.Error(), "size") {
			response.Error(w, http.StatusRequestEntityTooLarge, err.Error(), nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to upload file", nil)
		}
		return
	}

	response.Success(w, uploadResponse)
}

// GetMediaList 获取媒体文件列表
func (h *MediaHandler) GetMediaList(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	// 解析查询参数
	req := &models.MediaListRequest{
		Limit:  20,
		Offset: 0,
	}

	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil {
			req.Limit = limit
		}
	}

	if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil {
			req.Offset = offset
		}
	}

	if mediaType := r.URL.Query().Get("media_type"); mediaType != "" {
		mt := models.MediaType(mediaType)
		req.MediaType = &mt
	}

	if status := r.URL.Query().Get("status"); status != "" {
		s := models.MediaStatus(status)
		req.Status = &s
	}

	req.SortBy = r.URL.Query().Get("sort_by")
	req.SortOrder = r.URL.Query().Get("sort_order")

	// 获取媒体列表
	mediaList, err := h.mediaService.GetMediaList(userID, req)
	if err != nil {
		h.logger.Error("Failed to get media list",
			zap.String("user_id", userID),
			zap.Error(err),
		)
		response.Error(w, http.StatusInternalServerError, "Failed to get media list", nil)
		return
	}

	response.Success(w, mediaList)
}

// GetMedia 获取单个媒体文件
func (h *MediaHandler) GetMedia(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	vars := mux.Vars(r)
	mediaID := vars["id"]

	media, err := h.mediaService.GetMedia(userID, mediaID)
	if err != nil {
		h.logger.Error("Failed to get media",
			zap.String("user_id", userID),
			zap.String("media_id", mediaID),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "not found") {
			response.Error(w, http.StatusNotFound, "Media not found", nil)
		} else if strings.Contains(err.Error(), "access denied") {
			response.Error(w, http.StatusForbidden, "Access denied", nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to get media", nil)
		}
		return
	}

	response.Success(w, media)
}

// UpdateMedia 更新媒体文件
func (h *MediaHandler) UpdateMedia(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	vars := mux.Vars(r)
	mediaID := vars["id"]

	var req models.MediaUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	err := h.mediaService.UpdateMedia(userID, mediaID, &req)
	if err != nil {
		h.logger.Error("Failed to update media",
			zap.String("user_id", userID),
			zap.String("media_id", mediaID),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "not found") {
			response.Error(w, http.StatusNotFound, "Media not found", nil)
		} else if strings.Contains(err.Error(), "access denied") {
			response.Error(w, http.StatusForbidden, "Access denied", nil)
		} else if strings.Contains(err.Error(), "invalid") {
			response.Error(w, http.StatusBadRequest, err.Error(), nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to update media", nil)
		}
		return
	}

	response.Success(w, map[string]string{"message": "Media updated successfully"})
}

// DeleteMedia 删除媒体文件
func (h *MediaHandler) DeleteMedia(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	vars := mux.Vars(r)
	mediaID := vars["id"]

	err := h.mediaService.DeleteMedia(userID, mediaID)
	if err != nil {
		h.logger.Error("Failed to delete media",
			zap.String("user_id", userID),
			zap.String("media_id", mediaID),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "not found") {
			response.Error(w, http.StatusNotFound, "Media not found", nil)
		} else if strings.Contains(err.Error(), "access denied") {
			response.Error(w, http.StatusForbidden, "Access denied", nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to delete media", nil)
		}
		return
	}

	response.Success(w, map[string]string{"message": "Media deleted successfully"})
}

// GenerateThumbnail 生成缩略图
func (h *MediaHandler) GenerateThumbnail(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	vars := mux.Vars(r)
	mediaID := vars["id"]

	var req models.ThumbnailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		// 使用默认值
		req = models.ThumbnailRequest{
			Width:   200,
			Height:  200,
			Quality: 80,
		}
	}

	// 验证参数
	if req.Width <= 0 || req.Width > 2000 {
		req.Width = 200
	}
	if req.Height <= 0 || req.Height > 2000 {
		req.Height = 200
	}
	if req.Quality <= 0 || req.Quality > 100 {
		req.Quality = 80
	}

	media, err := h.mediaService.GenerateThumbnail(userID, mediaID, &req)
	if err != nil {
		h.logger.Error("Failed to generate thumbnail",
			zap.String("user_id", userID),
			zap.String("media_id", mediaID),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "not found") {
			response.Error(w, http.StatusNotFound, "Media not found", nil)
		} else if strings.Contains(err.Error(), "access denied") {
			response.Error(w, http.StatusForbidden, "Access denied", nil)
		} else if strings.Contains(err.Error(), "only be generated for images") {
			response.Error(w, http.StatusBadRequest, "Thumbnails can only be generated for images", nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to generate thumbnail", nil)
		}
		return
	}

	response.Success(w, map[string]interface{}{
		"message": "Thumbnail generation started",
		"media":   media,
	})
}

// GetPresignedURL 获取预签名URL
func (h *MediaHandler) GetPresignedURL(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	vars := mux.Vars(r)
	mediaID := vars["id"]

	operation := r.URL.Query().Get("operation")
	if operation == "" {
		operation = "GET"
	}

	expirationStr := r.URL.Query().Get("expiration")
	expiration := 1 * time.Hour // 默认1小时
	if expirationStr != "" {
		if exp, err := time.ParseDuration(expirationStr); err == nil {
			expiration = exp
		}
	}

	url, err := h.mediaService.GetPresignedURL(userID, mediaID, operation, expiration)
	if err != nil {
		h.logger.Error("Failed to get presigned URL",
			zap.String("user_id", userID),
			zap.String("media_id", mediaID),
			zap.String("operation", operation),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "not found") {
			response.Error(w, http.StatusNotFound, "Media not found", nil)
		} else if strings.Contains(err.Error(), "access denied") {
			response.Error(w, http.StatusForbidden, "Access denied", nil)
		} else if strings.Contains(err.Error(), "not supported") {
			response.Error(w, http.StatusNotImplemented, "Presigned URLs not supported", nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to get presigned URL", nil)
		}
		return
	}

	response.Success(w, map[string]interface{}{
		"url":        url,
		"operation":  operation,
		"expires_at": time.Now().Add(expiration),
	})
}

// GetProcessingJobStatus 获取处理任务状态
func (h *MediaHandler) GetProcessingJobStatus(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	vars := mux.Vars(r)
	jobID := vars["id"]

	job, err := h.mediaService.GetProcessingJobStatus(jobID)
	if err != nil {
		h.logger.Error("Failed to get processing job status",
			zap.String("user_id", userID),
			zap.String("job_id", jobID),
			zap.Error(err),
		)

		if strings.Contains(err.Error(), "not found") {
			response.Error(w, http.StatusNotFound, "Job not found", nil)
		} else {
			response.Error(w, http.StatusInternalServerError, "Failed to get job status", nil)
		}
		return
	}

	// 验证用户权限（通过媒体文件）
	media, err := h.mediaService.GetMedia(userID, job.MediaID)
	if err != nil {
		response.Error(w, http.StatusForbidden, "Access denied", nil)
		return
	}

	_ = media // 避免未使用变量警告

	response.Success(w, job)
}

// GetUserStorageStats 获取用户存储统计
func (h *MediaHandler) GetUserStorageStats(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	stats, err := h.mediaService.GetUserStorageStats(userID)
	if err != nil {
		h.logger.Error("Failed to get user storage stats",
			zap.String("user_id", userID),
			zap.Error(err),
		)
		response.Error(w, http.StatusInternalServerError, "Failed to get storage stats", nil)
		return
	}

	response.Success(w, stats)
}

// GetSystemStorageStats 获取系统存储统计
func (h *MediaHandler) GetSystemStorageStats(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	// 这里可以添加管理员权限检查
	// if !isAdmin(userID) {
	//     response.Error(w, http.StatusForbidden, "Admin access required", nil)
	//     return
	// }

	stats, err := h.mediaService.GetSystemStorageStats()
	if err != nil {
		h.logger.Error("Failed to get system storage stats",
			zap.String("user_id", userID),
			zap.Error(err),
		)
		response.Error(w, http.StatusInternalServerError, "Failed to get storage stats", nil)
		return
	}

	response.Success(w, stats)
}

// HealthCheck 健康检查
func (h *MediaHandler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	response.Success(w, map[string]interface{}{
		"service": "media-service",
		"status":  "healthy",
		"time":    time.Now(),
	})
}
