package repository

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/jmoiron/sqlx"
	"go.uber.org/zap"

	"media-service/internal/models"
)

// MediaRepository 媒体仓库接口
type MediaRepository interface {
	// 媒体文件管理
	CreateMedia(media *models.Media) error
	GetMediaByID(id string) (*models.Media, error)
	GetMediaByUserID(userID string, req *models.MediaListRequest) ([]*models.Media, int, error)
	UpdateMedia(id string, updates *models.MediaUpdateRequest) error
	DeleteMedia(id string) error
	DeleteExpiredMedia() error

	// 处理任务管理
	CreateProcessingJob(job *models.ProcessingJob) error
	GetProcessingJob(id string) (*models.ProcessingJob, error)
	GetPendingJobs(limit int) ([]*models.ProcessingJob, error)
	UpdateProcessingJob(id string, status string, result map[string]interface{}, errorMsg *string) error

	// 存储配额管理
	GetUserQuota(userID string) (*models.UserStorageQuota, error)
	UpdateUserQuota(userID string, usedQuota int64, fileCount int) error
	CreateUserQuota(quota *models.UserStorageQuota) error

	// 统计信息
	GetStorageStats() (*models.StorageInfo, error)
	GetUserStorageStats(userID string) (*models.StorageInfo, error)
}

// PostgreSQLMediaRepository PostgreSQL实现
type PostgreSQLMediaRepository struct {
	db     *sqlx.DB
	logger *zap.Logger
}

// NewPostgreSQLMediaRepository 创建PostgreSQL媒体仓库
func NewPostgreSQLMediaRepository(db *sqlx.DB, logger *zap.Logger) MediaRepository {
	return &PostgreSQLMediaRepository{
		db:     db,
		logger: logger,
	}
}

// CreateMedia 创建媒体文件记录
func (r *PostgreSQLMediaRepository) CreateMedia(media *models.Media) error {
	query := `
		INSERT INTO media_files (
			id, user_id, filename, original_name, mime_type, file_size,
			media_type, status, storage_path, public_url, thumbnail_url,
			metadata, created_at, updated_at, expires_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
		)`

	metadataJSON, _ := json.Marshal(media.Metadata)

	_, err := r.db.Exec(query,
		media.ID, media.UserID, media.Filename, media.OriginalName,
		media.MimeType, media.FileSize, media.MediaType, media.Status,
		media.StoragePath, media.PublicURL, media.ThumbnailURL,
		metadataJSON, media.CreatedAt, media.UpdatedAt, media.ExpiresAt,
	)

	if err != nil {
		r.logger.Error("Failed to create media", zap.Error(err), zap.String("media_id", media.ID))
		return fmt.Errorf("failed to create media: %w", err)
	}

	return nil
}

// GetMediaByID 根据ID获取媒体文件
func (r *PostgreSQLMediaRepository) GetMediaByID(id string) (*models.Media, error) {
	query := `
		SELECT id, user_id, filename, original_name, mime_type, file_size,
		       media_type, status, storage_path, public_url, thumbnail_url,
		       metadata, created_at, updated_at, expires_at
		FROM media_files
		WHERE id = $1 AND status != 'deleted'
	`

	media := &models.Media{}
	var metadataJSON []byte

	err := r.db.QueryRow(query, id).Scan(
		&media.ID, &media.UserID, &media.Filename, &media.OriginalName,
		&media.MimeType, &media.FileSize, &media.MediaType, &media.Status,
		&media.StoragePath, &media.PublicURL, &media.ThumbnailURL,
		&metadataJSON, &media.CreatedAt, &media.UpdatedAt, &media.ExpiresAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get media: %w", err)
	}

	if len(metadataJSON) > 0 {
		var metadata models.MediaMetadata
		if err := json.Unmarshal(metadataJSON, &metadata); err == nil {
			media.Metadata = &metadata
		}
	}

	return media, nil
}

// GetMediaByUserID 根据用户ID获取媒体文件列表
func (r *PostgreSQLMediaRepository) GetMediaByUserID(userID string, req *models.MediaListRequest) ([]*models.Media, int, error) {
	// 构建查询条件
	where := "WHERE user_id = $1 AND status != 'deleted'"
	args := []interface{}{userID}
	argIndex := 2

	if req.MediaType != nil {
		where += fmt.Sprintf(" AND media_type = $%d", argIndex)
		args = append(args, *req.MediaType)
		argIndex++
	}

	if req.Status != nil {
		where += fmt.Sprintf(" AND status = $%d", argIndex)
		args = append(args, *req.Status)
		argIndex++
	}

	// 获取总数
	countQuery := "SELECT COUNT(*) FROM media_files " + where
	var total int
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count media: %w", err)
	}

	// 构建排序和分页
	orderBy := "ORDER BY created_at DESC"
	if req.SortBy != "" {
		order := "DESC"
		if req.SortOrder == "asc" {
			order = "ASC"
		}
		orderBy = fmt.Sprintf("ORDER BY %s %s", req.SortBy, order)
	}

	limit := fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIndex, argIndex+1)
	args = append(args, req.Limit, req.Offset)

	// 查询数据
	query := `
		SELECT id, user_id, filename, original_name, mime_type, file_size,
		       media_type, status, storage_path, public_url, thumbnail_url,
		       metadata, created_at, updated_at, expires_at
		FROM media_files
		` + where + " " + orderBy + limit

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query media: %w", err)
	}
	defer rows.Close()

	var medias []*models.Media
	for rows.Next() {
		media := &models.Media{}
		var metadataJSON []byte

		err := rows.Scan(
			&media.ID, &media.UserID, &media.Filename, &media.OriginalName,
			&media.MimeType, &media.FileSize, &media.MediaType, &media.Status,
			&media.StoragePath, &media.PublicURL, &media.ThumbnailURL,
			&metadataJSON, &media.CreatedAt, &media.UpdatedAt, &media.ExpiresAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan media: %w", err)
		}

		if len(metadataJSON) > 0 {
			var metadata models.MediaMetadata
			if err := json.Unmarshal(metadataJSON, &metadata); err == nil {
				media.Metadata = &metadata
			}
		}

		medias = append(medias, media)
	}

	return medias, total, nil
}

// UpdateMedia 更新媒体文件
func (r *PostgreSQLMediaRepository) UpdateMedia(id string, updates *models.MediaUpdateRequest) error {
	setClauses := []string{}
	args := []interface{}{}
	argIndex := 1

	if updates.Filename != nil {
		setClauses = append(setClauses, fmt.Sprintf("filename = $%d", argIndex))
		args = append(args, *updates.Filename)
		argIndex++
	}

	if updates.Status != nil {
		setClauses = append(setClauses, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *updates.Status)
		argIndex++
	}

	if updates.Metadata != nil {
		metadataJSON, _ := json.Marshal(updates.Metadata)
		setClauses = append(setClauses, fmt.Sprintf("metadata = $%d", argIndex))
		args = append(args, metadataJSON)
		argIndex++
	}

	if updates.ExpiresAt != nil {
		setClauses = append(setClauses, fmt.Sprintf("expires_at = $%d", argIndex))
		args = append(args, *updates.ExpiresAt)
		argIndex++
	}

	if len(setClauses) == 0 {
		return nil
	}

	setClauses = append(setClauses, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	args = append(args, id)

	query := fmt.Sprintf(
		"UPDATE media_files SET %s WHERE id = $%d",
		string(setClauses[0]), argIndex,
	)
	for i := 1; i < len(setClauses); i++ {
		query = fmt.Sprintf("%s, %s", query, setClauses[i])
	}

	_, err := r.db.Exec(query, args...)
	if err != nil {
		r.logger.Error("Failed to update media", zap.Error(err), zap.String("media_id", id))
		return fmt.Errorf("failed to update media: %w", err)
	}

	return nil
}

// DeleteMedia 删除媒体文件（软删除）
func (r *PostgreSQLMediaRepository) DeleteMedia(id string) error {
	query := "UPDATE media_files SET status = 'deleted', updated_at = $1 WHERE id = $2"
	_, err := r.db.Exec(query, time.Now(), id)
	if err != nil {
		r.logger.Error("Failed to delete media", zap.Error(err), zap.String("media_id", id))
		return fmt.Errorf("failed to delete media: %w", err)
	}
	return nil
}

// DeleteExpiredMedia 删除过期媒体文件
func (r *PostgreSQLMediaRepository) DeleteExpiredMedia() error {
	query := `
		UPDATE media_files 
		SET status = 'deleted', updated_at = $1 
		WHERE expires_at IS NOT NULL AND expires_at < $1 AND status != 'deleted'
	`
	_, err := r.db.Exec(query, time.Now())
	return err
}

// CreateProcessingJob 创建处理任务
func (r *PostgreSQLMediaRepository) CreateProcessingJob(job *models.ProcessingJob) error {
	query := `
		INSERT INTO processing_jobs (
			id, media_id, job_type, status, params, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	paramsJSON, _ := json.Marshal(job.Params)

	_, err := r.db.Exec(query,
		job.ID, job.MediaID, job.JobType, job.Status,
		paramsJSON, job.CreatedAt, job.UpdatedAt,
	)

	return err
}

// GetProcessingJob 获取处理任务
func (r *PostgreSQLMediaRepository) GetProcessingJob(id string) (*models.ProcessingJob, error) {
	query := `
		SELECT id, media_id, job_type, status, params, result, error,
		       created_at, updated_at, started_at, completed_at
		FROM processing_jobs
		WHERE id = $1
	`

	job := &models.ProcessingJob{}
	var paramsJSON, resultJSON []byte

	err := r.db.QueryRow(query, id).Scan(
		&job.ID, &job.MediaID, &job.JobType, &job.Status,
		&paramsJSON, &resultJSON, &job.Error,
		&job.CreatedAt, &job.UpdatedAt, &job.StartedAt, &job.CompletedAt,
	)

	if err != nil {
		return nil, err
	}

	if len(paramsJSON) > 0 {
		json.Unmarshal(paramsJSON, &job.Params)
	}

	if len(resultJSON) > 0 {
		json.Unmarshal(resultJSON, &job.Result)
	}

	return job, nil
}

// GetPendingJobs 获取待处理任务
func (r *PostgreSQLMediaRepository) GetPendingJobs(limit int) ([]*models.ProcessingJob, error) {
	query := `
		SELECT id, media_id, job_type, status, params, result, error,
		       created_at, updated_at, started_at, completed_at
		FROM processing_jobs
		WHERE status = 'pending'
		ORDER BY created_at ASC
		LIMIT $1
	`

	rows, err := r.db.Query(query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var jobs []*models.ProcessingJob
	for rows.Next() {
		job := &models.ProcessingJob{}
		var paramsJSON, resultJSON []byte

		err := rows.Scan(
			&job.ID, &job.MediaID, &job.JobType, &job.Status,
			&paramsJSON, &resultJSON, &job.Error,
			&job.CreatedAt, &job.UpdatedAt, &job.StartedAt, &job.CompletedAt,
		)
		if err != nil {
			return nil, err
		}

		if len(paramsJSON) > 0 {
			json.Unmarshal(paramsJSON, &job.Params)
		}

		if len(resultJSON) > 0 {
			json.Unmarshal(resultJSON, &job.Result)
		}

		jobs = append(jobs, job)
	}

	return jobs, nil
}

// UpdateProcessingJob 更新处理任务
func (r *PostgreSQLMediaRepository) UpdateProcessingJob(id string, status string, result map[string]interface{}, errorMsg *string) error {
	var resultJSON []byte
	if result != nil {
		resultJSON, _ = json.Marshal(result)
	}

	query := `
		UPDATE processing_jobs 
		SET status = $1, result = $2, error = $3, updated_at = $4,
		    started_at = CASE WHEN status = 'pending' AND $1 = 'processing' THEN $4 ELSE started_at END,
		    completed_at = CASE WHEN $1 IN ('completed', 'failed') THEN $4 ELSE completed_at END
		WHERE id = $5
	`

	_, err := r.db.Exec(query, status, resultJSON, errorMsg, time.Now(), id)
	return err
}

// GetUserQuota 获取用户存储配额
func (r *PostgreSQLMediaRepository) GetUserQuota(userID string) (*models.UserStorageQuota, error) {
	query := `
		SELECT user_id, total_quota, used_quota, file_count, max_file_size, max_file_count,
		       created_at, updated_at
		FROM user_storage_quotas
		WHERE user_id = $1
	`

	quota := &models.UserStorageQuota{}
	err := r.db.QueryRow(query, userID).Scan(
		&quota.UserID, &quota.TotalQuota, &quota.UsedQuota, &quota.FileCount,
		&quota.MaxFileSize, &quota.MaxFileCount, &quota.CreatedAt, &quota.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return quota, nil
}

// UpdateUserQuota 更新用户存储配额
func (r *PostgreSQLMediaRepository) UpdateUserQuota(userID string, usedQuota int64, fileCount int) error {
	query := `
		UPDATE user_storage_quotas 
		SET used_quota = $1, file_count = $2, updated_at = $3
		WHERE user_id = $4
	`
	_, err := r.db.Exec(query, usedQuota, fileCount, time.Now(), userID)
	return err
}

// CreateUserQuota 创建用户存储配额
func (r *PostgreSQLMediaRepository) CreateUserQuota(quota *models.UserStorageQuota) error {
	query := `
		INSERT INTO user_storage_quotas (
			user_id, total_quota, used_quota, file_count, max_file_size, max_file_count,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (user_id) DO NOTHING
	`

	_, err := r.db.Exec(query,
		quota.UserID, quota.TotalQuota, quota.UsedQuota, quota.FileCount,
		quota.MaxFileSize, quota.MaxFileCount, quota.CreatedAt, quota.UpdatedAt,
	)

	return err
}

// GetStorageStats 获取存储统计信息
func (r *PostgreSQLMediaRepository) GetStorageStats() (*models.StorageInfo, error) {
	query := `
		SELECT 
			COALESCE(SUM(file_size), 0) as total_size,
			COUNT(*) as file_count
		FROM media_files 
		WHERE status != 'deleted'
	`

	stats := &models.StorageInfo{}
	err := r.db.QueryRow(query).Scan(&stats.UsedSize, &stats.FileCount)
	if err != nil {
		return nil, err
	}

	// 这里可以根据实际情况设置总大小和可用大小
	stats.TotalSize = 1024 * 1024 * 1024 * 1024 // 1TB
	stats.AvailableSize = stats.TotalSize - stats.UsedSize

	return stats, nil
}

// GetUserStorageStats 获取用户存储统计信息
func (r *PostgreSQLMediaRepository) GetUserStorageStats(userID string) (*models.StorageInfo, error) {
	query := `
		SELECT 
			COALESCE(SUM(file_size), 0) as used_size,
			COUNT(*) as file_count
		FROM media_files 
		WHERE user_id = $1 AND status != 'deleted'
	`

	stats := &models.StorageInfo{}
	err := r.db.QueryRow(query, userID).Scan(&stats.UsedSize, &stats.FileCount)
	if err != nil {
		return nil, err
	}

	// 获取用户配额信息
	quota, err := r.GetUserQuota(userID)
	if err == nil {
		stats.TotalSize = quota.TotalQuota
		stats.AvailableSize = quota.TotalQuota - stats.UsedSize
	} else {
		// 默认配额
		stats.TotalSize = 1024 * 1024 * 1024 // 1GB
		stats.AvailableSize = stats.TotalSize - stats.UsedSize
	}

	return stats, nil
}

// MemoryMediaRepository 内存实现（用于测试和开发）
type MemoryMediaRepository struct {
	medias         map[string]*models.Media
	jobs           map[string]*models.ProcessingJob
	quotas         map[string]*models.UserStorageQuota
	mutex          sync.RWMutex
	logger         *zap.Logger
}

// NewMemoryMediaRepository 创建内存媒体仓库
func NewMemoryMediaRepository(logger *zap.Logger) MediaRepository {
	return &MemoryMediaRepository{
		medias: make(map[string]*models.Media),
		jobs:   make(map[string]*models.ProcessingJob),
		quotas: make(map[string]*models.UserStorageQuota),
		logger: logger,
	}
}

// CreateMedia 创建媒体文件记录
func (r *MemoryMediaRepository) CreateMedia(media *models.Media) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	r.medias[media.ID] = media
	return nil
}

// GetMediaByID 根据ID获取媒体文件
func (r *MemoryMediaRepository) GetMediaByID(id string) (*models.Media, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	media, exists := r.medias[id]
	if !exists || media.Status == models.MediaStatusDeleted {
		return nil, fmt.Errorf("media not found")
	}

	return media, nil
}

// GetMediaByUserID 根据用户ID获取媒体文件列表
func (r *MemoryMediaRepository) GetMediaByUserID(userID string, req *models.MediaListRequest) ([]*models.Media, int, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var allMedias []*models.Media
	for _, media := range r.medias {
		if media.UserID == userID && media.Status != models.MediaStatusDeleted {
			if req.MediaType != nil && media.MediaType != *req.MediaType {
				continue
			}
			if req.Status != nil && media.Status != *req.Status {
				continue
			}
			allMedias = append(allMedias, media)
		}
	}

	total := len(allMedias)

	// 简单分页
	start := req.Offset
	if start > total {
		start = total
	}
	end := start + req.Limit
	if end > total {
		end = total
	}

	result := allMedias[start:end]
	return result, total, nil
}

// UpdateMedia 更新媒体文件
func (r *MemoryMediaRepository) UpdateMedia(id string, updates *models.MediaUpdateRequest) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	media, exists := r.medias[id]
	if !exists {
		return fmt.Errorf("media not found")
	}

	if updates.Filename != nil {
		media.Filename = *updates.Filename
	}
	if updates.Status != nil {
		media.Status = *updates.Status
	}
	if updates.Metadata != nil {
		media.Metadata = updates.Metadata
	}
	if updates.ExpiresAt != nil {
		media.ExpiresAt = updates.ExpiresAt
	}

	media.UpdatedAt = time.Now()
	return nil
}

// DeleteMedia 删除媒体文件
func (r *MemoryMediaRepository) DeleteMedia(id string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	media, exists := r.medias[id]
	if !exists {
		return fmt.Errorf("media not found")
	}

	media.Status = models.MediaStatusDeleted
	media.UpdatedAt = time.Now()
	return nil
}

// DeleteExpiredMedia 删除过期媒体文件
func (r *MemoryMediaRepository) DeleteExpiredMedia() error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	now := time.Now()
	for _, media := range r.medias {
		if media.ExpiresAt != nil && now.After(*media.ExpiresAt) && media.Status != models.MediaStatusDeleted {
			media.Status = models.MediaStatusDeleted
			media.UpdatedAt = now
		}
	}

	return nil
}

// CreateProcessingJob 创建处理任务
func (r *MemoryMediaRepository) CreateProcessingJob(job *models.ProcessingJob) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	r.jobs[job.ID] = job
	return nil
}

// GetProcessingJob 获取处理任务
func (r *MemoryMediaRepository) GetProcessingJob(id string) (*models.ProcessingJob, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	job, exists := r.jobs[id]
	if !exists {
		return nil, fmt.Errorf("job not found")
	}

	return job, nil
}

// GetPendingJobs 获取待处理任务
func (r *MemoryMediaRepository) GetPendingJobs(limit int) ([]*models.ProcessingJob, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var pendingJobs []*models.ProcessingJob
	for _, job := range r.jobs {
		if job.Status == "pending" {
			pendingJobs = append(pendingJobs, job)
			if len(pendingJobs) >= limit {
				break
			}
		}
	}

	return pendingJobs, nil
}

// UpdateProcessingJob 更新处理任务
func (r *MemoryMediaRepository) UpdateProcessingJob(id string, status string, result map[string]interface{}, errorMsg *string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	job, exists := r.jobs[id]
	if !exists {
		return fmt.Errorf("job not found")
	}

	job.Status = status
	job.Result = result
	job.Error = errorMsg
	job.UpdatedAt = time.Now()

	if status == "processing" && job.StartedAt == nil {
		now := time.Now()
		job.StartedAt = &now
	}

	if status == "completed" || status == "failed" {
		now := time.Now()
		job.CompletedAt = &now
	}

	return nil
}

// GetUserQuota 获取用户存储配额
func (r *MemoryMediaRepository) GetUserQuota(userID string) (*models.UserStorageQuota, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	quota, exists := r.quotas[userID]
	if !exists {
		return nil, fmt.Errorf("quota not found")
	}

	return quota, nil
}

// UpdateUserQuota 更新用户存储配额
func (r *MemoryMediaRepository) UpdateUserQuota(userID string, usedQuota int64, fileCount int) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	quota, exists := r.quotas[userID]
	if !exists {
		return fmt.Errorf("quota not found")
	}

	quota.UsedQuota = usedQuota
	quota.FileCount = fileCount
	quota.UpdatedAt = time.Now()

	return nil
}

// CreateUserQuota 创建用户存储配额
func (r *MemoryMediaRepository) CreateUserQuota(quota *models.UserStorageQuota) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.quotas[quota.UserID]; exists {
		return nil // 已存在，忽略
	}

	r.quotas[quota.UserID] = quota
	return nil
}

// GetStorageStats 获取存储统计信息
func (r *MemoryMediaRepository) GetStorageStats() (*models.StorageInfo, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var totalSize int64
	var fileCount int

	for _, media := range r.medias {
		if media.Status != models.MediaStatusDeleted {
			totalSize += media.FileSize
			fileCount++
		}
	}

	return &models.StorageInfo{
		TotalSize:     1024 * 1024 * 1024 * 1024, // 1TB
		UsedSize:      totalSize,
		AvailableSize: 1024*1024*1024*1024 - totalSize,
		FileCount:     fileCount,
	}, nil
}

// GetUserStorageStats 获取用户存储统计信息
func (r *MemoryMediaRepository) GetUserStorageStats(userID string) (*models.StorageInfo, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var usedSize int64
	var fileCount int

	for _, media := range r.medias {
		if media.UserID == userID && media.Status != models.MediaStatusDeleted {
			usedSize += media.FileSize
			fileCount++
		}
	}

	// 获取用户配额
	totalSize := int64(1024 * 1024 * 1024) // 默认1GB
	if quota, exists := r.quotas[userID]; exists {
		totalSize = quota.TotalQuota
	}

	return &models.StorageInfo{
		TotalSize:     totalSize,
		UsedSize:      usedSize,
		AvailableSize: totalSize - usedSize,
		FileCount:     fileCount,
	}, nil
}