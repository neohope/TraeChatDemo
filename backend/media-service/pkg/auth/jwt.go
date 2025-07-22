package auth

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"

	"media-service/pkg/response"
)

// Claims JWT声明
type Claims struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// JWTManager JWT管理器
type JWTManager struct {
	secretKey     []byte
	tokenDuration time.Duration
	logger        *zap.Logger
}

// NewJWTManager 创建JWT管理器
func NewJWTManager(secretKey string, tokenDuration time.Duration, logger *zap.Logger) *JWTManager {
	return &JWTManager{
		secretKey:     []byte(secretKey),
		tokenDuration: tokenDuration,
		logger:        logger,
	}
}

// GenerateToken 生成JWT令牌
func (manager *JWTManager) GenerateToken(userID, username, email, role string) (string, error) {
	claims := &Claims{
		UserID:   userID,
		Username: username,
		Email:    email,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(manager.tokenDuration)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "media-service",
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(manager.secretKey)
}

// VerifyToken 验证JWT令牌
func (manager *JWTManager) VerifyToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return manager.secretKey, nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}

	return claims, nil
}

// RefreshToken 刷新JWT令牌
func (manager *JWTManager) RefreshToken(tokenString string) (string, error) {
	claims, err := manager.VerifyToken(tokenString)
	if err != nil {
		return "", err
	}

	// 检查令牌是否即将过期（在过期前30分钟内可以刷新）
	if time.Until(claims.ExpiresAt.Time) > 30*time.Minute {
		return "", fmt.Errorf("token is not eligible for refresh")
	}

	return manager.GenerateToken(claims.UserID, claims.Username, claims.Email, claims.Role)
}

// 全局JWT管理器实例
var globalJWTManager *JWTManager

// InitJWT 初始化JWT管理器
func InitJWT(secretKey string, tokenDuration time.Duration, logger *zap.Logger) {
	globalJWTManager = NewJWTManager(secretKey, tokenDuration, logger)
}

// JWTMiddleware JWT中间件
func JWTMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 从请求头获取令牌
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			response.Error(w, http.StatusUnauthorized, "Authorization header required", nil)
			return
		}

		// 检查Bearer前缀
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.Error(w, http.StatusUnauthorized, "Invalid authorization header format", nil)
			return
		}

		tokenString := parts[1]

		// 验证令牌
		claims, err := globalJWTManager.VerifyToken(tokenString)
		if err != nil {
			globalJWTManager.logger.Warn("Invalid JWT token", zap.Error(err))
			response.Error(w, http.StatusUnauthorized, "Invalid token", nil)
			return
		}

		// 将用户信息添加到上下文
		ctx := context.WithValue(r.Context(), "user_id", claims.UserID)
		ctx = context.WithValue(ctx, "username", claims.Username)
		ctx = context.WithValue(ctx, "email", claims.Email)
		ctx = context.WithValue(ctx, "role", claims.Role)
		ctx = context.WithValue(ctx, "claims", claims)

		// 继续处理请求
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// OptionalJWTMiddleware 可选的JWT中间件（不强制要求认证）
func OptionalJWTMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 从请求头获取令牌
		authHeader := r.Header.Get("Authorization")
		if authHeader != "" {
			// 检查Bearer前缀
			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) == 2 && parts[0] == "Bearer" {
				tokenString := parts[1]

				// 验证令牌
				claims, err := globalJWTManager.VerifyToken(tokenString)
				if err == nil {
					// 将用户信息添加到上下文
					ctx := context.WithValue(r.Context(), "user_id", claims.UserID)
					ctx = context.WithValue(ctx, "username", claims.Username)
					ctx = context.WithValue(ctx, "email", claims.Email)
					ctx = context.WithValue(ctx, "role", claims.Role)
					ctx = context.WithValue(ctx, "claims", claims)
					r = r.WithContext(ctx)
				}
			}
		}

		// 继续处理请求
		next.ServeHTTP(w, r)
	})
}

// AdminMiddleware 管理员权限中间件
func AdminMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		role := GetRoleFromContext(r.Context())
		if role != "admin" {
			response.Error(w, http.StatusForbidden, "Admin access required", nil)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// CORS中间件
func CORSMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Max-Age", "86400")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// 日志中间件
func LoggingMiddleware(logger *zap.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			// 创建响应写入器包装器来捕获状态码
			wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

			next.ServeHTTP(wrapped, r)

			duration := time.Since(start)
			userID := GetUserIDFromContext(r.Context())

			logger.Info("HTTP Request",
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.String("query", r.URL.RawQuery),
				zap.String("user_agent", r.UserAgent()),
				zap.String("remote_addr", r.RemoteAddr),
				zap.String("user_id", userID),
				zap.Int("status_code", wrapped.statusCode),
				zap.Duration("duration", duration),
			)
		})
	}
}

// responseWriter 包装器用于捕获状态码
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// 上下文辅助函数

// GetUserIDFromContext 从上下文获取用户ID
func GetUserIDFromContext(ctx context.Context) string {
	if userID, ok := ctx.Value("user_id").(string); ok {
		return userID
	}
	return ""
}

// GetUsernameFromContext 从上下文获取用户名
func GetUsernameFromContext(ctx context.Context) string {
	if username, ok := ctx.Value("username").(string); ok {
		return username
	}
	return ""
}

// GetEmailFromContext 从上下文获取邮箱
func GetEmailFromContext(ctx context.Context) string {
	if email, ok := ctx.Value("email").(string); ok {
		return email
	}
	return ""
}

// GetRoleFromContext 从上下文获取角色
func GetRoleFromContext(ctx context.Context) string {
	if role, ok := ctx.Value("role").(string); ok {
		return role
	}
	return ""
}

// GetClaimsFromContext 从上下文获取JWT声明
func GetClaimsFromContext(ctx context.Context) *Claims {
	if claims, ok := ctx.Value("claims").(*Claims); ok {
		return claims
	}
	return nil
}

// IsAuthenticated 检查是否已认证
func IsAuthenticated(ctx context.Context) bool {
	return GetUserIDFromContext(ctx) != ""
}

// IsAdmin 检查是否为管理员
func IsAdmin(ctx context.Context) bool {
	return GetRoleFromContext(ctx) == "admin"
}