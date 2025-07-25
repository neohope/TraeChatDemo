package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	HTTPPort     int
	LogLevel     string
	Redis        RedisConfig
	WebSocket    WebSocketConfig
	PushNotification PushConfig
}

type RedisConfig struct {
	Host     string
	Port     int
	Password string
	DB       int
}

type WebSocketConfig struct {
	ReadBufferSize  int
	WriteBufferSize int
	MaxConnections  int
}

type PushConfig struct {
	FCMServerKey string
	APNSKeyFile  string
	APNSKeyID    string
	APNSTeamID   string
}

func LoadConfig() (*Config, error) {
	// 加载.env文件
	godotenv.Load()

	httpPort, _ := strconv.Atoi(getEnv("HTTP_PORT", "8085"))
	redisPort, _ := strconv.Atoi(getEnv("REDIS_PORT", "6379"))
	redisDB, _ := strconv.Atoi(getEnv("REDIS_DB", "0"))
	readBufferSize, _ := strconv.Atoi(getEnv("WS_READ_BUFFER_SIZE", "1024"))
	writeBufferSize, _ := strconv.Atoi(getEnv("WS_WRITE_BUFFER_SIZE", "1024"))
	maxConnections, _ := strconv.Atoi(getEnv("WS_MAX_CONNECTIONS", "1000"))

	return &Config{
		HTTPPort: httpPort,
		LogLevel: getEnv("LOG_LEVEL", "info"),
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     redisPort,
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       redisDB,
		},
		WebSocket: WebSocketConfig{
			ReadBufferSize:  readBufferSize,
			WriteBufferSize: writeBufferSize,
			MaxConnections:  maxConnections,
		},
		PushNotification: PushConfig{
			FCMServerKey: getEnv("FCM_SERVER_KEY", ""),
			APNSKeyFile:  getEnv("APNS_KEY_FILE", ""),
			APNSKeyID:    getEnv("APNS_KEY_ID", ""),
			APNSTeamID:   getEnv("APNS_TEAM_ID", ""),
		},
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}