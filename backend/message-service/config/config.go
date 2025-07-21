package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config 应用配置结构体
type Config struct {
	Service   ServiceConfig
	Database  DatabaseConfig
	JWT       JWTConfig
	Kafka     KafkaConfig
	Redis     RedisConfig
	UserSvc   ServiceEndpoint
	GroupSvc  ServiceEndpoint
	MediaSvc  ServiceEndpoint
	NotifySvc ServiceEndpoint
}

// ServiceConfig 服务配置
type ServiceConfig struct {
	HTTPPort int
	GRPCPort int
	LogLevel string
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	DBName   string
	SSLMode  string
}

// JWTConfig JWT配置
type JWTConfig struct {
	SecretKey       string
	ExpirationHours int
}

// KafkaConfig Kafka配置
type KafkaConfig struct {
	Brokers []string
	Topic   string
}

// RedisConfig Redis配置
type RedisConfig struct {
	Addr     string
	Password string
	DB       int
}

// ServiceEndpoint 微服务端点配置
type ServiceEndpoint struct {
	Host string
	Port int
}

// LoadConfig 从环境变量或.env文件加载配置
func LoadConfig() (*Config, error) {
	// 尝试加载.env文件，如果存在的话
	_ = godotenv.Load()

	return &Config{
		Service: ServiceConfig{
			HTTPPort: getEnvAsInt("HTTP_PORT", 8082),
			GRPCPort: getEnvAsInt("GRPC_PORT", 9082),
			LogLevel: getEnv("LOG_LEVEL", "debug"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", 5432),
			Username: getEnv("DB_USERNAME", "postgres"),
			Password: getEnv("DB_PASSWORD", "postgres"),
			DBName:   getEnv("DB_NAME", "chatapp"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		JWT: JWTConfig{
			SecretKey:       getEnv("JWT_SECRET_KEY", "your_super_secret_key_change_in_production"),
			ExpirationHours: getEnvAsInt("JWT_EXPIRATION_HOURS", 24),
		},
		Kafka: KafkaConfig{
			Brokers: []string{getEnv("KAFKA_BROKER", "localhost:9092")},
			Topic:   getEnv("KAFKA_TOPIC", "messages"),
		},
		Redis: RedisConfig{
			Addr:     getEnv("REDIS_ADDR", "localhost:6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		UserSvc: ServiceEndpoint{
			Host: getEnv("USER_SVC_HOST", "localhost"),
			Port: getEnvAsInt("USER_SVC_PORT", 8081),
		},
		GroupSvc: ServiceEndpoint{
			Host: getEnv("GROUP_SVC_HOST", "localhost"),
			Port: getEnvAsInt("GROUP_SVC_PORT", 8083),
		},
		MediaSvc: ServiceEndpoint{
			Host: getEnv("MEDIA_SVC_HOST", "localhost"),
			Port: getEnvAsInt("MEDIA_SVC_PORT", 8084),
		},
		NotifySvc: ServiceEndpoint{
			Host: getEnv("NOTIFY_SVC_HOST", "localhost"),
			Port: getEnvAsInt("NOTIFY_SVC_PORT", 8085),
		},
	}, nil
}

// 获取环境变量，如果不存在则返回默认值
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// 获取环境变量并转换为整数，如果不存在或转换失败则返回默认值
func getEnvAsInt(key string, defaultValue int) int {
	valueStr := getEnv(key, "")
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return defaultValue
	}

	return value
}

// GetPostgresConnString 获取PostgreSQL连接字符串
func (c *Config) GetPostgresConnString() string {
	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Database.Host,
		c.Database.Port,
		c.Database.Username,
		c.Database.Password,
		c.Database.DBName,
		c.Database.SSLMode,
	)
}

// GetUserServiceEndpoint 获取用户服务端点
func (c *Config) GetUserServiceEndpoint() string {
	return fmt.Sprintf("%s:%d", c.UserSvc.Host, c.UserSvc.Port)
}

// GetGroupServiceEndpoint 获取群组服务端点
func (c *Config) GetGroupServiceEndpoint() string {
	return fmt.Sprintf("%s:%d", c.GroupSvc.Host, c.GroupSvc.Port)
}

// GetMediaServiceEndpoint 获取媒体服务端点
func (c *Config) GetMediaServiceEndpoint() string {
	return fmt.Sprintf("%s:%d", c.MediaSvc.Host, c.MediaSvc.Port)
}

// GetNotificationServiceEndpoint 获取通知服务端点
func (c *Config) GetNotificationServiceEndpoint() string {
	return fmt.Sprintf("%s:%d", c.NotifySvc.Host, c.NotifySvc.Port)
}