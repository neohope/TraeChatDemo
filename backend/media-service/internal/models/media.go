package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MediaType 媒体类型枚举
type MediaType string

const (
	MediaTypeImage MediaType = "image"
	MediaTypeVideo MediaType = "video"
	MediaTypeAudio MediaType = "audio"
	MediaTypeFile  MediaType = "file"
)

// MediaStatus 媒体状态枚举
type MediaStatus string

const (
	MediaStatusUploading  MediaStatus = "uploading"
	MediaStatusProcessing MediaStatus = "processing"
	MediaStatusReady      MediaStatus = "ready"
	MediaStatusFailed     MediaStatus = "failed"
	MediaStatusDeleted    MediaStatus = "deleted"
)

// Media 媒体文件模型
type Media struct {
	ID          string      `json:"id" db:"id"`
	UserID      string      `json:"user_id" db:"user_id"`
	Filename    string      `json:"filename" db:"filename"`
	OriginalName string     `json:"original_name" db:"original_name"`
	MimeType    string      `json:"mime_type" db:"mime_type"`
	FileSize    int64       `json:"file_size" db:"file_size"`
	MediaType   MediaType   `json:"media_type" db:"media_type"`
	Status      MediaStatus `json:"status" db:"status"`
	StoragePath string      `json:"storage_path" db:"storage_path"`
	PublicURL   string      `json:"public_url" db:"public_url"`
	ThumbnailURL *string    `json:"thumbnail_url,omitempty" db:"thumbnail_url"`
	Metadata    *MediaMetadata `json:"metadata,omitempty" db:"metadata"`
	CreatedAt   time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at" db:"updated_at"`
	ExpiresAt   *time.Time  `json:"expires_at,omitempty" db:"expires_at"`
}

// MediaMetadata 媒体元数据
type MediaMetadata struct {
	// 图片元数据
	Width  *int `json:"width,omitempty"`
	Height *int `json:"height,omitempty"`

	// 视频元数据
	Duration *float64 `json:"duration,omitempty"` // 秒
	Bitrate  *int     `json:"bitrate,omitempty"`  // bps
	Codec    *string  `json:"codec,omitempty"`

	// 音频元数据
	SampleRate *int `json:"sample_rate,omitempty"` // Hz
	Channels   *int `json:"channels,omitempty"`

	// 通用元数据
	Checksum string            `json:"checksum,omitempty"`
	Exif     map[string]string `json:"exif,omitempty"`
}

// UploadRequest 上传请求
type UploadRequest struct {
	UserID      string            `json:"user_id"`
	Filename    string            `json:"filename"`
	MimeType    string            `json:"mime_type"`
	FileSize    int64             `json:"file_size"`
	MediaType   MediaType         `json:"media_type"`
	Metadata    map[string]string `json:"metadata,omitempty"`
	ExpiresAt   *time.Time        `json:"expires_at,omitempty"`
	IsTemporary bool              `json:"is_temporary,omitempty"`
}

// UploadResponse 上传响应
type UploadResponse struct {
	MediaID   string `json:"media_id"`
	UploadURL string `json:"upload_url"`
	PublicURL string `json:"public_url"`
	ExpiresAt int64  `json:"expires_at"`
}

// MediaListRequest 媒体列表请求
type MediaListRequest struct {
	UserID    string      `json:"user_id"`
	MediaType *MediaType  `json:"media_type,omitempty"`
	Status    *MediaStatus `json:"status,omitempty"`
	Limit     int         `json:"limit"`
	Offset    int         `json:"offset"`
	SortBy    string      `json:"sort_by"`    // created_at, file_size, filename
	SortOrder string      `json:"sort_order"` // asc, desc
}

// MediaListResponse 媒体列表响应
type MediaListResponse struct {
	Medias []Media `json:"medias"`
	Total  int     `json:"total"`
	Limit  int     `json:"limit"`
	Offset int     `json:"offset"`
}

// MediaUpdateRequest 媒体更新请求
type MediaUpdateRequest struct {
	Filename  *string        `json:"filename,omitempty"`
	Status    *MediaStatus   `json:"status,omitempty"`
	Metadata  *MediaMetadata `json:"metadata,omitempty"`
	ExpiresAt *time.Time     `json:"expires_at,omitempty"`
}

// ThumbnailRequest 缩略图请求
type ThumbnailRequest struct {
	MediaID string `json:"media_id"`
	Width   int    `json:"width"`
	Height  int    `json:"height"`
	Quality int    `json:"quality"`
}

// ProcessingJob 处理任务
type ProcessingJob struct {
	ID        string                 `json:"id" db:"id"`
	MediaID   string                 `json:"media_id" db:"media_id"`
	JobType   string                 `json:"job_type" db:"job_type"` // thumbnail, compress, convert
	Status    string                 `json:"status" db:"status"`     // pending, processing, completed, failed
	Params    map[string]interface{} `json:"params" db:"params"`
	Result    map[string]interface{} `json:"result,omitempty" db:"result"`
	Error     *string                `json:"error,omitempty" db:"error"`
	CreatedAt time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt time.Time              `json:"updated_at" db:"updated_at"`
	StartedAt *time.Time             `json:"started_at,omitempty" db:"started_at"`
	CompletedAt *time.Time           `json:"completed_at,omitempty" db:"completed_at"`
}

// StorageInfo 存储信息
type StorageInfo struct {
	TotalSize     int64 `json:"total_size"`
	UsedSize      int64 `json:"used_size"`
	AvailableSize int64 `json:"available_size"`
	FileCount     int   `json:"file_count"`
}

// UserStorageQuota 用户存储配额
type UserStorageQuota struct {
	UserID       string    `json:"user_id" db:"user_id"`
	TotalQuota   int64     `json:"total_quota" db:"total_quota"`     // 总配额（字节）
	UsedQuota    int64     `json:"used_quota" db:"used_quota"`       // 已使用配额（字节）
	FileCount    int       `json:"file_count" db:"file_count"`       // 文件数量
	MaxFileSize  int64     `json:"max_file_size" db:"max_file_size"` // 单文件最大大小
	MaxFileCount int       `json:"max_file_count" db:"max_file_count"` // 最大文件数量
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// NewMedia 创建新的媒体文件记录
func NewMedia(userID, filename, originalName, mimeType string, fileSize int64, mediaType MediaType) *Media {
	return &Media{
		ID:           uuid.New().String(),
		UserID:       userID,
		Filename:     filename,
		OriginalName: originalName,
		MimeType:     mimeType,
		FileSize:     fileSize,
		MediaType:    mediaType,
		Status:       MediaStatusUploading,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
}

// NewProcessingJob 创建新的处理任务
func NewProcessingJob(mediaID, jobType string, params map[string]interface{}) *ProcessingJob {
	return &ProcessingJob{
		ID:        uuid.New().String(),
		MediaID:   mediaID,
		JobType:   jobType,
		Status:    "pending",
		Params:    params,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

// IsImage 检查是否为图片类型
func (m *Media) IsImage() bool {
	return m.MediaType == MediaTypeImage
}

// IsVideo 检查是否为视频类型
func (m *Media) IsVideo() bool {
	return m.MediaType == MediaTypeVideo
}

// IsAudio 检查是否为音频类型
func (m *Media) IsAudio() bool {
	return m.MediaType == MediaTypeAudio
}

// IsFile 检查是否为文件类型
func (m *Media) IsFile() bool {
	return m.MediaType == MediaTypeFile
}

// IsReady 检查媒体是否准备就绪
func (m *Media) IsReady() bool {
	return m.Status == MediaStatusReady
}

// IsExpired 检查媒体是否已过期
func (m *Media) IsExpired() bool {
	if m.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*m.ExpiresAt)
}

// GetFileExtension 获取文件扩展名
func (m *Media) GetFileExtension() string {
	if len(m.Filename) == 0 {
		return ""
	}
	for i := len(m.Filename) - 1; i >= 0; i-- {
		if m.Filename[i] == '.' {
			return m.Filename[i+1:]
		}
	}
	return ""
}

// Value 实现driver.Valuer接口
func (m MediaMetadata) Value() (driver.Value, error) {
	return json.Marshal(m)
}

// Scan 实现sql.Scanner接口
func (m *MediaMetadata) Scan(value interface{}) error {
	if value == nil {
		return nil
	}

	switch v := value.(type) {
	case []byte:
		return json.Unmarshal(v, m)
	case string:
		return json.Unmarshal([]byte(v), m)
	default:
		return fmt.Errorf("cannot scan %T into MediaMetadata", value)
	}
}