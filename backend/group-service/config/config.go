package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config 应用配置结构
type Config struct {
	// 服务配置
	HTTPPort int
	LogLevel string

	// 数据库配置
	Database DatabaseConfig

	// JWT配置
	JWT JWTConfig

	// 外部服务配置
	UserServiceURL string
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

// LoadConfig 从环境变量加载配置
func LoadConfig() (*Config, error) {
	// 加载.env文件
	_ = godotenv.Load()

	config := &Config{
		HTTPPort: getEnvAsInt("HTTP_PORT", 8083),
		LogLevel: getEnv("LOG_LEVEL", "info"),
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
		UserServiceURL: getEnv("USER_SERVICE_URL", "http://localhost:8081"),
	}

	return config, nil
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

// getEnv 获取环境变量，如果不存在则返回默认值
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt 获取环境变量并转换为整数
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}