package storage

import (
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"go.uber.org/zap"

	"media-service/config"
)

// StorageProvider 存储提供者接口
type StorageProvider interface {
	// 文件上传
	UploadFile(key string, file multipart.File, fileSize int64, contentType string) (*UploadResult, error)
	
	// 文件下载
	DownloadFile(key string) (io.ReadCloser, error)
	
	// 获取文件URL
	GetFileURL(key string) (string, error)
	
	// 获取预签名URL（用于直接上传/下载）
	GetPresignedURL(key string, operation string, expiration time.Duration) (string, error)
	
	// 删除文件
	DeleteFile(key string) error
	
	// 检查文件是否存在
	FileExists(key string) (bool, error)
	
	// 获取文件信息
	GetFileInfo(key string) (*FileInfo, error)
	
	// 列出文件
	ListFiles(prefix string, maxKeys int) ([]*FileInfo, error)
	
	// 复制文件
	CopyFile(sourceKey, destKey string) error
}

// UploadResult 上传结果
type UploadResult struct {
	Key         string    `json:"key"`
	URL         string    `json:"url"`
	Size        int64     `json:"size"`
	ContentType string    `json:"content_type"`
	ETag        string    `json:"etag"`
	UploadedAt  time.Time `json:"uploaded_at"`
}

// FileInfo 文件信息
type FileInfo struct {
	Key          string    `json:"key"`
	Size         int64     `json:"size"`
	ContentType  string    `json:"content_type"`
	ETag         string    `json:"etag"`
	LastModified time.Time `json:"last_modified"`
	URL          string    `json:"url"`
}

// NewStorageProvider 创建存储提供者
func NewStorageProvider(cfg *config.Config, logger *zap.Logger) (StorageProvider, error) {
	switch strings.ToLower(cfg.Storage.Provider) {
	case "local":
		return NewLocalStorage(cfg, logger)
	case "s3":
		return NewS3Storage(cfg, logger)
	case "minio":
		return NewMinIOStorage(cfg, logger)
	default:
		return nil, fmt.Errorf("unsupported storage provider: %s", cfg.Storage.Provider)
	}
}

// LocalStorage 本地存储实现
type LocalStorage struct {
	basePath string
	baseURL  string
	logger   *zap.Logger
}

// NewLocalStorage 创建本地存储
func NewLocalStorage(cfg *config.Config, logger *zap.Logger) (*LocalStorage, error) {
	basePath := cfg.Storage.LocalPath
	if basePath == "" {
		basePath = "./uploads"
	}

	// 确保目录存在
	if err := os.MkdirAll(basePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}

	baseURL := cfg.Storage.BaseURL
	if baseURL == "" {
		baseURL = fmt.Sprintf("http://localhost:%d/api/v1/media/files", cfg.Server.Port)
	}

	return &LocalStorage{
		basePath: basePath,
		baseURL:  baseURL,
		logger:   logger,
	}, nil
}

// UploadFile 上传文件到本地存储
func (s *LocalStorage) UploadFile(key string, file multipart.File, fileSize int64, contentType string) (*UploadResult, error) {
	filePath := filepath.Join(s.basePath, key)
	
	// 确保目录存在
	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create directory: %w", err)
	}

	// 创建目标文件
	destFile, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create file: %w", err)
	}
	defer destFile.Close()

	// 复制文件内容
	writtenBytes, err := io.Copy(destFile, file)
	if err != nil {
		return nil, fmt.Errorf("failed to copy file: %w", err)
	}

	// 生成文件URL
	fileURL := fmt.Sprintf("%s/%s", strings.TrimRight(s.baseURL, "/"), key)

	return &UploadResult{
		Key:         key,
		URL:         fileURL,
		Size:        writtenBytes,
		ContentType: contentType,
		ETag:        fmt.Sprintf("\"%d\"", time.Now().Unix()),
		UploadedAt:  time.Now(),
	}, nil
}

// DownloadFile 从本地存储下载文件
func (s *LocalStorage) DownloadFile(key string) (io.ReadCloser, error) {
	filePath := filepath.Join(s.basePath, key)
	return os.Open(filePath)
}

// GetFileURL 获取文件URL
func (s *LocalStorage) GetFileURL(key string) (string, error) {
	return fmt.Sprintf("%s/%s", strings.TrimRight(s.baseURL, "/"), key), nil
}

// GetPresignedURL 获取预签名URL（本地存储不支持）
func (s *LocalStorage) GetPresignedURL(key string, operation string, expiration time.Duration) (string, error) {
	return "", fmt.Errorf("presigned URLs not supported for local storage")
}

// DeleteFile 删除本地文件
func (s *LocalStorage) DeleteFile(key string) error {
	filePath := filepath.Join(s.basePath, key)
	return os.Remove(filePath)
}

// FileExists 检查文件是否存在
func (s *LocalStorage) FileExists(key string) (bool, error) {
	filePath := filepath.Join(s.basePath, key)
	_, err := os.Stat(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

// GetFileInfo 获取文件信息
func (s *LocalStorage) GetFileInfo(key string) (*FileInfo, error) {
	filePath := filepath.Join(s.basePath, key)
	stat, err := os.Stat(filePath)
	if err != nil {
		return nil, err
	}

	fileURL, _ := s.GetFileURL(key)

	return &FileInfo{
		Key:          key,
		Size:         stat.Size(),
		ContentType:  "application/octet-stream", // 本地存储无法确定MIME类型
		ETag:         fmt.Sprintf("\"%d\"", stat.ModTime().Unix()),
		LastModified: stat.ModTime(),
		URL:          fileURL,
	}, nil
}

// ListFiles 列出文件
func (s *LocalStorage) ListFiles(prefix string, maxKeys int) ([]*FileInfo, error) {
	var files []*FileInfo
	count := 0

	err := filepath.Walk(s.basePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		if count >= maxKeys {
			return filepath.SkipDir
		}

		relPath, err := filepath.Rel(s.basePath, path)
		if err != nil {
			return err
		}

		if strings.HasPrefix(relPath, prefix) {
			fileURL, _ := s.GetFileURL(relPath)
			files = append(files, &FileInfo{
				Key:          relPath,
				Size:         info.Size(),
				ContentType:  "application/octet-stream",
				ETag:         fmt.Sprintf("\"%d\"", info.ModTime().Unix()),
				LastModified: info.ModTime(),
				URL:          fileURL,
			})
			count++
		}

		return nil
	})

	return files, err
}

// CopyFile 复制文件
func (s *LocalStorage) CopyFile(sourceKey, destKey string) error {
	sourcePath := filepath.Join(s.basePath, sourceKey)
	destPath := filepath.Join(s.basePath, destKey)

	// 确保目标目录存在
	destDir := filepath.Dir(destPath)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	// 打开源文件
	sourceFile, err := os.Open(sourcePath)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer sourceFile.Close()

	// 创建目标文件
	destFile, err := os.Create(destPath)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %w", err)
	}
	defer destFile.Close()

	// 复制文件内容
	_, err = io.Copy(destFile, sourceFile)
	return err
}

// S3Storage AWS S3存储实现
type S3Storage struct {
	bucket     string
	region     string
	baseURL    string
	s3Client   *s3.S3
	uploader   *s3manager.Uploader
	downloader *s3manager.Downloader
	logger     *zap.Logger
}

// NewS3Storage 创建S3存储
func NewS3Storage(cfg *config.Config, logger *zap.Logger) (*S3Storage, error) {
	// 创建AWS会话
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(cfg.AWS.Region),
		Credentials: credentials.NewStaticCredentials(
			cfg.AWS.AccessKeyID,
			cfg.AWS.SecretAccessKey,
			"",
		),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create AWS session: %w", err)
	}

	s3Client := s3.New(sess)
	uploader := s3manager.NewUploader(sess)
	downloader := s3manager.NewDownloader(sess)

	baseURL := cfg.Storage.BaseURL
	if baseURL == "" {
		baseURL = fmt.Sprintf("https://%s.s3.%s.amazonaws.com", cfg.AWS.BucketName, cfg.AWS.Region)
	}

	return &S3Storage{
		bucket:     cfg.AWS.BucketName,
		region:     cfg.AWS.Region,
		baseURL:    baseURL,
		s3Client:   s3Client,
		uploader:   uploader,
		downloader: downloader,
		logger:     logger,
	}, nil
}

// UploadFile 上传文件到S3
func (s *S3Storage) UploadFile(key string, file multipart.File, fileSize int64, contentType string) (*UploadResult, error) {
	uploadInput := &s3manager.UploadInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		Body:        file,
		ContentType: aws.String(contentType),
	}

	result, err := s.uploader.Upload(uploadInput)
	if err != nil {
		return nil, fmt.Errorf("failed to upload to S3: %w", err)
	}

	return &UploadResult{
		Key:         key,
		URL:         result.Location,
		Size:        fileSize,
		ContentType: contentType,
		ETag:        aws.StringValue(result.ETag),
		UploadedAt:  time.Now(),
	}, nil
}

// DownloadFile 从S3下载文件
func (s *S3Storage) DownloadFile(key string) (io.ReadCloser, error) {
	getObjectInput := &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}

	result, err := s.s3Client.GetObject(getObjectInput)
	if err != nil {
		return nil, fmt.Errorf("failed to download from S3: %w", err)
	}

	return result.Body, nil
}

// GetFileURL 获取S3文件URL
func (s *S3Storage) GetFileURL(key string) (string, error) {
	return fmt.Sprintf("%s/%s", strings.TrimRight(s.baseURL, "/"), key), nil
}

// GetPresignedURL 获取S3预签名URL
func (s *S3Storage) GetPresignedURL(key string, operation string, expiration time.Duration) (string, error) {
	var req *request.Request

	switch operation {
	case "GET":
		getObjectInput := &s3.GetObjectInput{
			Bucket: aws.String(s.bucket),
			Key:    aws.String(key),
		}
		req, _ = s.s3Client.GetObjectRequest(getObjectInput)
	case "PUT":
		putObjectInput := &s3.PutObjectInput{
			Bucket: aws.String(s.bucket),
			Key:    aws.String(key),
		}
		req, _ = s.s3Client.PutObjectRequest(putObjectInput)
	default:
		return "", fmt.Errorf("unsupported operation: %s", operation)
	}

	urlStr, err := req.Presign(expiration)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return urlStr, nil
}

// DeleteFile 删除S3文件
func (s *S3Storage) DeleteFile(key string) error {
	deleteObjectInput := &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}

	_, err := s.s3Client.DeleteObject(deleteObjectInput)
	if err != nil {
		return fmt.Errorf("failed to delete from S3: %w", err)
	}

	return nil
}

// FileExists 检查S3文件是否存在
func (s *S3Storage) FileExists(key string) (bool, error) {
	headObjectInput := &s3.HeadObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}

	_, err := s.s3Client.HeadObject(headObjectInput)
	if err != nil {
		if strings.Contains(err.Error(), "NotFound") {
			return false, nil
		}
		return false, err
	}

	return true, nil
}

// GetFileInfo 获取S3文件信息
func (s *S3Storage) GetFileInfo(key string) (*FileInfo, error) {
	headObjectInput := &s3.HeadObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}

	result, err := s.s3Client.HeadObject(headObjectInput)
	if err != nil {
		return nil, fmt.Errorf("failed to get S3 object info: %w", err)
	}

	fileURL, _ := s.GetFileURL(key)

	return &FileInfo{
		Key:          key,
		Size:         aws.Int64Value(result.ContentLength),
		ContentType:  aws.StringValue(result.ContentType),
		ETag:         aws.StringValue(result.ETag),
		LastModified: aws.TimeValue(result.LastModified),
		URL:          fileURL,
	}, nil
}

// ListFiles 列出S3文件
func (s *S3Storage) ListFiles(prefix string, maxKeys int) ([]*FileInfo, error) {
	listObjectsInput := &s3.ListObjectsV2Input{
		Bucket:  aws.String(s.bucket),
		Prefix:  aws.String(prefix),
		MaxKeys: aws.Int64(int64(maxKeys)),
	}

	result, err := s.s3Client.ListObjectsV2(listObjectsInput)
	if err != nil {
		return nil, fmt.Errorf("failed to list S3 objects: %w", err)
	}

	var files []*FileInfo
	for _, obj := range result.Contents {
		fileURL, _ := s.GetFileURL(aws.StringValue(obj.Key))
		files = append(files, &FileInfo{
			Key:          aws.StringValue(obj.Key),
			Size:         aws.Int64Value(obj.Size),
			ContentType:  "application/octet-stream", // S3 ListObjects不返回ContentType
			ETag:         aws.StringValue(obj.ETag),
			LastModified: aws.TimeValue(obj.LastModified),
			URL:          fileURL,
		})
	}

	return files, nil
}

// CopyFile 复制S3文件
func (s *S3Storage) CopyFile(sourceKey, destKey string) error {
	copySource := fmt.Sprintf("%s/%s", s.bucket, sourceKey)
	copyObjectInput := &s3.CopyObjectInput{
		Bucket:     aws.String(s.bucket),
		Key:        aws.String(destKey),
		CopySource: aws.String(copySource),
	}

	_, err := s.s3Client.CopyObject(copyObjectInput)
	if err != nil {
		return fmt.Errorf("failed to copy S3 object: %w", err)
	}

	return nil
}

// MinIOStorage MinIO存储实现（兼容S3 API）
type MinIOStorage struct {
	*S3Storage
}

// NewMinIOStorage 创建MinIO存储
func NewMinIOStorage(cfg *config.Config, logger *zap.Logger) (*MinIOStorage, error) {
	// MinIO使用自定义端点
	endpoint := cfg.AWS.Endpoint
	if endpoint == "" {
		endpoint = "localhost:9000"
	}

	// 创建AWS会话（MinIO兼容S3 API）
	sess, err := session.NewSession(&aws.Config{
		Region:           aws.String(cfg.AWS.Region),
		Endpoint:         aws.String(endpoint),
		S3ForcePathStyle: aws.Bool(true), // MinIO需要路径样式
		Credentials: credentials.NewStaticCredentials(
			cfg.AWS.AccessKeyID,
			cfg.AWS.SecretAccessKey,
			"",
		),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create MinIO session: %w", err)
	}

	s3Client := s3.New(sess)
	uploader := s3manager.NewUploader(sess)
	downloader := s3manager.NewDownloader(sess)

	baseURL := cfg.Storage.BaseURL
	if baseURL == "" {
		baseURL = fmt.Sprintf("http://%s/%s", endpoint, cfg.AWS.BucketName)
	}

	s3Storage := &S3Storage{
		bucket:     cfg.AWS.BucketName,
		region:     cfg.AWS.Region,
		baseURL:    baseURL,
		s3Client:   s3Client,
		uploader:   uploader,
		downloader: downloader,
		logger:     logger,
	}

	return &MinIOStorage{
		S3Storage: s3Storage,
	}, nil
}