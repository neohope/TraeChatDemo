package service

import (
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/h2non/filetype"
	"go.uber.org/zap"

	"media-service/config"
	"media-service/internal/models"
	"media-service/internal/repository"
	"media-service/internal/storage"
)

// MediaService 媒体服务接口
type MediaService interface {
	// 文件上传
	UploadFile(userID string, file multipart.File, header *multipart.FileHeader) (*models.UploadResponse, error)
	
	// 获取媒体文件
	GetMedia(userID, mediaID string) (*models.Media, error)
	
	// 获取媒体文件列表
	GetMediaList(userID string, req *models.MediaListRequest) (*models.MediaListResponse, error)
	
	// 更新媒体文件
	UpdateMedia(userID, mediaID string, req *models.MediaUpdateRequest) error
	
	// 删除媒体文件
	DeleteMedia(userID, mediaID string) error
	
	// 生成缩略图
	GenerateThumbnail(userID, mediaID string, req *models.ThumbnailRequest) (*models.Media, error)
	
	// 获取预签名URL
	GetPresignedURL(userID, mediaID, operation string, expiration time.Duration) (string, error)
	
	// 获取用户存储统计
	GetUserStorageStats(userID string) (*models.StorageInfo, error)
	
	// 获取系统存储统计
	GetSystemStorageStats() (*models.StorageInfo, error)
	
	// 清理过期文件
	CleanupExpiredFiles() error
	
	// 处理媒体文件（异步）
	ProcessMedia(mediaID string, jobType string, params map[string]interface{}) (*models.ProcessingJob, error)
	
	// 获取处理任务状态
	GetProcessingJobStatus(jobID string) (*models.ProcessingJob, error)
}

// mediaService 媒体服务实现
type mediaService struct {
	repo           repository.MediaRepository
	storageProvider storage.StorageProvider
	config         *config.Config
	logger         *zap.Logger
}

// NewMediaService 创建媒体服务
func NewMediaService(
	repo repository.MediaRepository,
	storageProvider storage.StorageProvider,
	config *config.Config,
	logger *zap.Logger,
) MediaService {
	return &mediaService{
		repo:           repo,
		storageProvider: storageProvider,
		config:         config,
		logger:         logger,
	}
}

// UploadFile 上传文件
func (s *mediaService) UploadFile(userID string, file multipart.File, header *multipart.FileHeader) (*models.UploadResponse, error) {
	// 验证文件大小
	if header.Size > s.config.File.MaxFileSize {
		return nil, fmt.Errorf("file size %d exceeds maximum allowed size %d", header.Size, s.config.File.MaxFileSize)
	}

	// 检测文件类型
	fileBytes := make([]byte, 512)
	n, err := file.Read(fileBytes)
	if err != nil {
		return nil, fmt.Errorf("failed to read file for type detection: %w", err)
	}
	
	// 重置文件指针
	file.Seek(0, 0)

	// 检测MIME类型
	kind, _ := filetype.Match(fileBytes[:n])

	mimeType := ""
	if kind != filetype.Unknown {
		mimeType = kind.MIME.Value
	}
	if mimeType == "" {
		mimeType = header.Header.Get("Content-Type")
		if mimeType == "" {
			mimeType = "application/octet-stream"
		}
	}

	// 验证文件类型
	if !s.isAllowedFileType(mimeType) {
		return nil, fmt.Errorf("file type %s is not allowed", mimeType)
	}

	// 检查用户存储配额
	if err = s.checkUserQuota(userID, header.Size); err != nil {
		return nil, err
	}

	// 生成文件ID和存储路径
	mediaID := uuid.New().String()
	fileExt := filepath.Ext(header.Filename)
	if fileExt == "" && kind.Extension != "" {
		fileExt = "." + kind.Extension
	}
	
	filename := fmt.Sprintf("%s%s", mediaID, fileExt)
	storageKey := s.generateStorageKey(userID, filename)

	// 上传到存储
	uploadResult, err := s.storageProvider.UploadFile(storageKey, file, header.Size, mimeType)
	if err != nil {
		return nil, fmt.Errorf("failed to upload file: %w", err)
	}

	// 确定媒体类型
	mediaType := s.getMediaType(mimeType)

	// 创建媒体记录
	media := &models.Media{
		ID:           mediaID,
		UserID:       userID,
		Filename:     filename,
		OriginalName: header.Filename,
		MimeType:     mimeType,
		FileSize:     header.Size,
		MediaType:    mediaType,
		Status:       models.MediaStatusReady,
		StoragePath:  s.config.Storage.LocalPath + "/" + storageKey,
		PublicURL:    s.config.Storage.BaseURL + "/" + storageKey,
		Metadata:     s.extractMetadata(header, mimeType),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	// 设置过期时间（可以根据需要配置）
	// expiresAt := time.Now().Add(24 * time.Hour) // 24小时后过期
	// media.ExpiresAt = &expiresAt

	// 保存到数据库
	if err := s.repo.CreateMedia(media); err != nil {
		// 如果数据库保存失败，删除已上传的文件
		s.storageProvider.DeleteFile(storageKey)
		return nil, fmt.Errorf("failed to save media record: %w", err)
	}

	// 更新用户配额
	s.updateUserQuota(userID, header.Size, 1)

	// 如果是图片，异步生成缩略图
	if mediaType == models.MediaTypeImage {
		go s.generateThumbnailAsync(mediaID)
	}

	s.logger.Info("File uploaded successfully",
		zap.String("user_id", userID),
		zap.String("media_id", mediaID),
		zap.String("filename", header.Filename),
		zap.Int64("size", header.Size),
	)

	return &models.UploadResponse{
		MediaID:   mediaID,
		UploadURL: uploadResult.URL,
		PublicURL: uploadResult.URL,
		ExpiresAt: media.CreatedAt.Unix() + 3600, // 1小时后过期
	}, nil
}

// GetMedia 获取媒体文件
func (s *mediaService) GetMedia(userID, mediaID string) (*models.Media, error) {
	media, err := s.repo.GetMediaByID(mediaID)
	if err != nil {
		return nil, fmt.Errorf("failed to get media: %w", err)
	}

	// 检查权限
	if media.UserID != userID {
		return nil, fmt.Errorf("access denied")
	}

	return media, nil
}

// GetMediaList 获取媒体文件列表
func (s *mediaService) GetMediaList(userID string, req *models.MediaListRequest) (*models.MediaListResponse, error) {
	// 设置默认值
	if req.Limit <= 0 {
		req.Limit = 20
	}
	if req.Limit > 100 {
		req.Limit = 100
	}
	if req.Offset < 0 {
		req.Offset = 0
	}

	medias, total, err := s.repo.GetMediaByUserID(userID, req)
	if err != nil {
		return nil, fmt.Errorf("failed to get media list: %w", err)
	}

	// 转换指针切片为值切片
	mediaList := make([]models.Media, len(medias))
	for i, media := range medias {
		mediaList[i] = *media
	}

	return &models.MediaListResponse{
		Medias: mediaList,
		Total:  total,
		Limit:  req.Limit,
		Offset: req.Offset,
	}, nil
}

// UpdateMedia 更新媒体文件
func (s *mediaService) UpdateMedia(userID, mediaID string, req *models.MediaUpdateRequest) error {
	// 检查权限
	media, err := s.GetMedia(userID, mediaID)
	if err != nil {
		return err
	}

	// 验证状态转换
	if req.Status != nil {
		if !s.isValidStatusTransition(media.Status, *req.Status) {
			return fmt.Errorf("invalid status transition from %s to %s", media.Status, *req.Status)
		}
	}

	return s.repo.UpdateMedia(mediaID, req)
}

// DeleteMedia 删除媒体文件
func (s *mediaService) DeleteMedia(userID, mediaID string) error {
	// 检查权限
	media, err := s.GetMedia(userID, mediaID)
	if err != nil {
		return err
	}

	// 软删除数据库记录
	if err := s.repo.DeleteMedia(mediaID); err != nil {
		return fmt.Errorf("failed to delete media record: %w", err)
	}

	// 异步删除存储文件
	go func() {
		if err := s.storageProvider.DeleteFile(media.StoragePath); err != nil {
			s.logger.Error("Failed to delete file from storage",
				zap.String("media_id", mediaID),
				zap.String("storage_path", media.StoragePath),
				zap.Error(err),
			)
		}

		// 删除缩略图
		if media.ThumbnailURL != nil && *media.ThumbnailURL != "" {
			thumbnailKey := s.getThumbnailKey(media.StoragePath)
			s.storageProvider.DeleteFile(thumbnailKey)
		}
	}()

	// 更新用户配额
	s.updateUserQuota(userID, -media.FileSize, -1)

	s.logger.Info("Media deleted",
		zap.String("user_id", userID),
		zap.String("media_id", mediaID),
	)

	return nil
}

// GenerateThumbnail 生成缩略图
func (s *mediaService) GenerateThumbnail(userID, mediaID string, req *models.ThumbnailRequest) (*models.Media, error) {
	// 检查权限
	media, err := s.GetMedia(userID, mediaID)
	if err != nil {
		return nil, err
	}

	// 检查是否为图片
	if media.MediaType != models.MediaTypeImage {
		return nil, fmt.Errorf("thumbnails can only be generated for images")
	}

	// 创建处理任务
	jobParams := map[string]interface{}{
		"width":   req.Width,
		"height":  req.Height,
		"quality": req.Quality,
	}

	job, err := s.ProcessMedia(mediaID, "thumbnail", jobParams)
	if err != nil {
		return nil, fmt.Errorf("failed to create thumbnail job: %w", err)
	}

	// 这里可以选择同步等待或返回任务ID
	// 为了简化，我们返回原始媒体信息
	s.logger.Info("Thumbnail generation started",
		zap.String("media_id", mediaID),
		zap.String("job_id", job.ID),
	)

	return media, nil
}

// GetPresignedURL 获取预签名URL
func (s *mediaService) GetPresignedURL(userID, mediaID, operation string, expiration time.Duration) (string, error) {
	// 检查权限
	media, err := s.GetMedia(userID, mediaID)
	if err != nil {
		return "", err
	}

	return s.storageProvider.GetPresignedURL(media.StoragePath, operation, expiration)
}

// GetUserStorageStats 获取用户存储统计
func (s *mediaService) GetUserStorageStats(userID string) (*models.StorageInfo, error) {
	return s.repo.GetUserStorageStats(userID)
}

// GetSystemStorageStats 获取系统存储统计
func (s *mediaService) GetSystemStorageStats() (*models.StorageInfo, error) {
	return s.repo.GetStorageStats()
}

// CleanupExpiredFiles 清理过期文件
func (s *mediaService) CleanupExpiredFiles() error {
	return s.repo.DeleteExpiredMedia()
}

// ProcessMedia 处理媒体文件
func (s *mediaService) ProcessMedia(mediaID string, jobType string, params map[string]interface{}) (*models.ProcessingJob, error) {
	job := &models.ProcessingJob{
		ID:        uuid.New().String(),
		MediaID:   mediaID,
		JobType:   jobType,
		Status:    "pending",
		Params:    params,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.repo.CreateProcessingJob(job); err != nil {
		return nil, fmt.Errorf("failed to create processing job: %w", err)
	}

	return job, nil
}

// GetProcessingJobStatus 获取处理任务状态
func (s *mediaService) GetProcessingJobStatus(jobID string) (*models.ProcessingJob, error) {
	return s.repo.GetProcessingJob(jobID)
}

// 辅助方法

// isAllowedFileType 检查文件类型是否允许
func (s *mediaService) isAllowedFileType(mimeType string) bool {
	// 检查所有允许的文件类型
	allowedTypes := append(s.config.File.AllowedImageTypes, s.config.File.AllowedVideoTypes...)
	allowedTypes = append(allowedTypes, s.config.File.AllowedAudioTypes...)
	allowedTypes = append(allowedTypes, s.config.File.AllowedFileTypes...)

	if len(allowedTypes) == 0 {
		return true // 如果没有配置限制，允许所有类型
	}

	for _, allowedType := range allowedTypes {
		if strings.HasPrefix(mimeType, allowedType) {
			return true
		}
	}

	return false
}

// getMediaType 根据MIME类型确定媒体类型
func (s *mediaService) getMediaType(mimeType string) models.MediaType {
	switch {
	case strings.HasPrefix(mimeType, "image/"):
		return models.MediaTypeImage
	case strings.HasPrefix(mimeType, "video/"):
		return models.MediaTypeVideo
	case strings.HasPrefix(mimeType, "audio/"):
		return models.MediaTypeAudio
	default:
		return models.MediaTypeFile
	}
}

// generateStorageKey 生成存储键
func (s *mediaService) generateStorageKey(userID, filename string) string {
	date := time.Now().Format("2006/01/02")
	return fmt.Sprintf("users/%s/%s/%s", userID, date, filename)
}

// extractMetadata 提取文件元数据
func (s *mediaService) extractMetadata(header *multipart.FileHeader, mimeType string) *models.MediaMetadata {
	metadata := &models.MediaMetadata{
		Checksum: "", // 可以在这里计算文件校验和
	}

	// 这里可以根据文件类型提取更多元数据
	// 例如图片的尺寸、视频的时长等

	return metadata
}

// checkUserQuota 检查用户配额
func (s *mediaService) checkUserQuota(userID string, fileSize int64) error {
	quota, err := s.repo.GetUserQuota(userID)
	if err != nil {
		// 如果用户配额不存在，创建默认配额
		defaultQuota := &models.UserStorageQuota{
			UserID:       userID,
			TotalQuota:   1024 * 1024 * 1024, // 1GB 默认配额
			UsedQuota:    0,
			FileCount:    0,
			MaxFileSize:  s.config.File.MaxFileSize,
			MaxFileCount: 1000, // 默认最大文件数量
			CreatedAt:    time.Now(),
			UpdatedAt:    time.Now(),
		}
		s.repo.CreateUserQuota(defaultQuota)
		quota = defaultQuota
	}

	// 检查存储空间
	if quota.UsedQuota+fileSize > quota.TotalQuota {
		return fmt.Errorf("storage quota exceeded: used %d + %d > %d", quota.UsedQuota, fileSize, quota.TotalQuota)
	}

	// 检查文件数量
	if quota.FileCount >= quota.MaxFileCount {
		return fmt.Errorf("file count limit exceeded: %d >= %d", quota.FileCount, quota.MaxFileCount)
	}

	// 检查单文件大小
	if fileSize > quota.MaxFileSize {
		return fmt.Errorf("file size exceeds limit: %d > %d", fileSize, quota.MaxFileSize)
	}

	return nil
}

// updateUserQuota 更新用户配额
func (s *mediaService) updateUserQuota(userID string, sizeChange int64, countChange int) {
	quota, err := s.repo.GetUserQuota(userID)
	if err != nil {
		s.logger.Error("Failed to get user quota for update", zap.String("user_id", userID), zap.Error(err))
		return
	}

	newUsedQuota := quota.UsedQuota + sizeChange
	newFileCount := quota.FileCount + countChange

	if newUsedQuota < 0 {
		newUsedQuota = 0
	}
	if newFileCount < 0 {
		newFileCount = 0
	}

	if err := s.repo.UpdateUserQuota(userID, newUsedQuota, newFileCount); err != nil {
		s.logger.Error("Failed to update user quota", zap.String("user_id", userID), zap.Error(err))
	}
}

// isValidStatusTransition 检查状态转换是否有效
func (s *mediaService) isValidStatusTransition(from, to models.MediaStatus) bool {
	validTransitions := map[models.MediaStatus][]models.MediaStatus{
		models.MediaStatusUploading:  {models.MediaStatusProcessing, models.MediaStatusReady, models.MediaStatusFailed, models.MediaStatusDeleted},
		models.MediaStatusProcessing: {models.MediaStatusReady, models.MediaStatusFailed, models.MediaStatusDeleted},
		models.MediaStatusReady:      {models.MediaStatusProcessing, models.MediaStatusDeleted},
		models.MediaStatusFailed:     {models.MediaStatusProcessing, models.MediaStatusDeleted},
		models.MediaStatusDeleted:    {}, // 删除状态不能转换到其他状态
	}

	allowedStates, exists := validTransitions[from]
	if !exists {
		return false
	}

	for _, allowedState := range allowedStates {
		if allowedState == to {
			return true
		}
	}

	return false
}

// generateThumbnailAsync 异步生成缩略图
func (s *mediaService) generateThumbnailAsync(mediaID string) {
	// 这里应该实现实际的缩略图生成逻辑
	// 可以使用图像处理库如imaging
	s.logger.Info("Generating thumbnail", zap.String("media_id", mediaID))
	
	// 创建缩略图生成任务
	params := map[string]interface{}{
		"width":   200,
		"height":  200,
		"quality": 80,
	}
	
	_, err := s.ProcessMedia(mediaID, "thumbnail", params)
	if err != nil {
		s.logger.Error("Failed to create thumbnail job", zap.String("media_id", mediaID), zap.Error(err))
	}
}

// getThumbnailKey 获取缩略图存储键
func (s *mediaService) getThumbnailKey(originalKey string) string {
	ext := filepath.Ext(originalKey)
	base := strings.TrimSuffix(originalKey, ext)
	return fmt.Sprintf("%s_thumb%s", base, ext)
}