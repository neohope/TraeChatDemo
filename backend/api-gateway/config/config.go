package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	HTTPPort         int
	LogLevel         string
	JWT              JWTConfig
	Services         ServicesConfig
	RateLimit        RateLimitConfig
	CORS             CORSConfig
}

type JWTConfig struct {
	SecretKey string
}

type ServicesConfig struct {
	UserService         string
	GroupService        string
	MessageService      string
	MediaService        string
	NotificationService string
}

type RateLimitConfig struct {
	Enabled bool
	RPS     int
}

type CORSConfig struct {
	AllowedOrigins []string
	AllowedMethods []string
	AllowedHeaders []string
}

func LoadConfig() (*Config, error) {
	// 加载.env文件
	godotenv.Load()

	httpPort, _ := strconv.Atoi(getEnv("HTTP_PORT", "8080"))
	rps, _ := strconv.Atoi(getEnv("RATE_LIMIT_RPS", "100"))
	rateLimitEnabled, _ := strconv.ParseBool(getEnv("RATE_LIMIT_ENABLED", "true"))

	return &Config{
		HTTPPort: httpPort,
		LogLevel: getEnv("LOG_LEVEL", "info"),
		JWT: JWTConfig{
			SecretKey: getEnv("JWT_SECRET_KEY", "your-secret-key"),
		},
		Services: ServicesConfig{
			UserService:         getEnv("USER_SERVICE_URL", "http://localhost:8081"),
			GroupService:        getEnv("GROUP_SERVICE_URL", "http://localhost:8082"),
			MessageService:      getEnv("MESSAGE_SERVICE_URL", "http://localhost:8083"),
			MediaService:        getEnv("MEDIA_SERVICE_URL", "http://localhost:8084"),
			NotificationService: getEnv("NOTIFICATION_SERVICE_URL", "http://localhost:8085"),
		},
		RateLimit: RateLimitConfig{
			Enabled: rateLimitEnabled,
			RPS:     rps,
		},
		CORS: CORSConfig{
			AllowedOrigins: []string{"http://localhost:3000", "*"},
			AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
			AllowedHeaders: []string{"Content-Type", "Authorization", "X-Requested-With", "Accept", "Origin", "X-User-ID"},
		},
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}