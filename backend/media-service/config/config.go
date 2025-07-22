package config

import (
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

// ServerConfig 服务器配置
type ServerConfig struct {
	Port         int `json:"port"`
	ReadTimeout  int `json:"read_timeout"`
	WriteTimeout int `json:"write_timeout"`
	IdleTimeout  int `json:"idle_timeout"`
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host            string `json:"host"`
	Port            int    `json:"port"`
	User            string `json:"user"`
	Password        string `json:"password"`
	DBName          string `json:"dbname"`
	SSLMode         string `json:"sslmode"`
	MaxOpenConns    int    `json:"max_open_conns"`
	MaxIdleConns    int    `json:"max_idle_conns"`
	ConnMaxLifetime int    `json:"conn_max_lifetime"`
}

// LogConfig 日志配置
type LogConfig struct {
	Level string `json:"level"`
}

// JWTConfig JWT配置
type JWTConfig struct {
	SecretKey       string `json:"secret_key"`
	ExpirationHours int    `json:"expiration_hours"`
}

// StorageConfig 存储配置
type StorageConfig struct {
	Provider  string `json:"provider"`   // local, s3, minio
	LocalPath string `json:"local_path"` // 本地存储路径
	BaseURL   string `json:"base_url"`   // 基础URL
}

// AWSConfig AWS配置
type AWSConfig struct {
	Region          string `json:"region"`
	AccessKeyID     string `json:"access_key_id"`
	SecretAccessKey string `json:"secret_access_key"`
	BucketName      string `json:"bucket_name"`
	Endpoint        string `json:"endpoint"`
}

// FileConfig 文件配置
type FileConfig struct {
	MaxFileSize       int64    `json:"max_file_size"`
	MaxImageSize      int64    `json:"max_image_size"`
	MaxVideoSize      int64    `json:"max_video_size"`
	AllowedImageTypes []string `json:"allowed_image_types"`
	AllowedVideoTypes []string `json:"allowed_video_types"`
	AllowedAudioTypes []string `json:"allowed_audio_types"`
	AllowedFileTypes  []string `json:"allowed_file_types"`
}

// ImageConfig 图片处理配置
type ImageConfig struct {
	ThumbnailWidth  int `json:"thumbnail_width"`
	ThumbnailHeight int `json:"thumbnail_height"`
	ImageQuality    int `json:"image_quality"`
}

// CDNConfig CDN配置
type CDNConfig struct {
	Enabled bool   `json:"enabled"`
	BaseURL string `json:"base_url"`
}

// ExternalConfig 外部服务配置
type ExternalConfig struct {
	UserServiceURL string `json:"user_service_url"`
}

// Config 媒体服务配置
type Config struct {
	Server   ServerConfig   `json:"server"`
	Database DatabaseConfig `json:"database"`
	Log      LogConfig      `json:"log"`
	JWT      JWTConfig      `json:"jwt"`
	Storage  StorageConfig  `json:"storage"`
	AWS      AWSConfig      `json:"aws"`
	File     FileConfig     `json:"file"`
	Image    ImageConfig    `json:"image"`
	CDN      CDNConfig      `json:"cdn"`
	External ExternalConfig `json:"external"`
}

// Load 加载配置
func Load() *Config {
	// 尝试加载.env文件
	_ = godotenv.Load()

	return &Config{
		Server: ServerConfig{
			Port:         getEnvAsInt("SERVER_PORT", 8084),
			ReadTimeout:  getEnvAsInt("SERVER_READ_TIMEOUT", 30),
			WriteTimeout: getEnvAsInt("SERVER_WRITE_TIMEOUT", 30),
			IdleTimeout:  getEnvAsInt("SERVER_IDLE_TIMEOUT", 120),
		},
		Database: DatabaseConfig{
			Host:            getEnv("DB_HOST", "localhost"),
			Port:            getEnvAsInt("DB_PORT", 5432),
			User:            getEnv("DB_USER", "postgres"),
			Password:        getEnv("DB_PASSWORD", "postgres"),
			DBName:          getEnv("DB_NAME", "chatapp"),
			SSLMode:         getEnv("DB_SSLMODE", "disable"),
			MaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 25),
			ConnMaxLifetime: getEnvAsInt("DB_CONN_MAX_LIFETIME", 5),
		},
		Log: LogConfig{
			Level: getEnv("LOG_LEVEL", "info"),
		},
		JWT: JWTConfig{
			SecretKey:       getEnv("JWT_SECRET_KEY", "your_super_secret_key_change_in_production"),
			ExpirationHours: getEnvAsInt("JWT_EXPIRATION_HOURS", 24),
		},
		Storage: StorageConfig{
			Provider:  getEnv("STORAGE_PROVIDER", "local"),
			LocalPath: getEnv("STORAGE_LOCAL_PATH", "./uploads"),
			BaseURL:   getEnv("STORAGE_BASE_URL", "http://localhost:8084"),
		},
		AWS: AWSConfig{
			Region:          getEnv("AWS_REGION", "us-east-1"),
			AccessKeyID:     getEnv("AWS_ACCESS_KEY_ID", ""),
			SecretAccessKey: getEnv("AWS_SECRET_ACCESS_KEY", ""),
			BucketName:      getEnv("S3_BUCKET_NAME", ""),
			Endpoint:        getEnv("AWS_ENDPOINT", ""),
		},
		File: FileConfig{
			MaxFileSize:       getEnvAsInt64("MAX_FILE_SIZE", 100*1024*1024),
			MaxImageSize:      getEnvAsInt64("MAX_IMAGE_SIZE", 10*1024*1024),
			MaxVideoSize:      getEnvAsInt64("MAX_VIDEO_SIZE", 500*1024*1024),
			AllowedImageTypes: getEnvAsSlice("ALLOWED_IMAGE_TYPES", "jpg,jpeg,png,gif,webp"),
			AllowedVideoTypes: getEnvAsSlice("ALLOWED_VIDEO_TYPES", "mp4,avi,mov,wmv,flv,webm"),
			AllowedAudioTypes: getEnvAsSlice("ALLOWED_AUDIO_TYPES", "mp3,wav,aac,ogg,m4a"),
			AllowedFileTypes:  getEnvAsSlice("ALLOWED_FILE_TYPES", "pdf,doc,docx,xls,xlsx,ppt,pptx,txt,zip,rar"),
		},
		Image: ImageConfig{
			ThumbnailWidth:  getEnvAsInt("THUMBNAIL_WIDTH", 200),
			ThumbnailHeight: getEnvAsInt("THUMBNAIL_HEIGHT", 200),
			ImageQuality:    getEnvAsInt("IMAGE_QUALITY", 85),
		},
		CDN: CDNConfig{
			Enabled: getEnvAsBool("CDN_ENABLED", false),
			BaseURL: getEnv("CDN_BASE_URL", ""),
		},
		External: ExternalConfig{
			UserServiceURL: getEnv("USER_SERVICE_URL", "http://localhost:8081"),
		},
	}
}

// GetPostgreSQLConnectionString 获取PostgreSQL连接字符串
func (c *Config) GetPostgreSQLConnectionString() string {
	return "host=" + c.Database.Host +
		" port=" + strconv.Itoa(c.Database.Port) +
		" user=" + c.Database.User +
		" password=" + c.Database.Password +
		" dbname=" + c.Database.DBName +
		" sslmode=" + c.Database.SSLMode
}

// 辅助函数
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsInt64(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}

func getEnvAsSlice(key, defaultValue string) []string {
	value := getEnv(key, defaultValue)
	return strings.Split(value, ",")
}