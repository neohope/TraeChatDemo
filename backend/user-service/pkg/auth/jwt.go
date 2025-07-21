package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v4"

	"github.com/yourusername/chatapp/user-service/internal/domain"
)

// JWTManager JWT管理器
type JWTManager struct {
	secretKey       string
	expirationHours int
}

// CustomClaims 自定义JWT声明
type CustomClaims struct {
	UserID   string         `json:"user_id"`
	Username string         `json:"username"`
	Email    string         `json:"email"`
	Status   domain.UserStatus `json:"status"`
	jwt.RegisteredClaims
}

// NewJWTManager 创建一个新的JWT管理器
func NewJWTManager(secretKey string, expirationHours int) *JWTManager {
	return &JWTManager{
		secretKey:       secretKey,
		expirationHours: expirationHours,
	}
}

// GenerateToken 为用户生成JWT令牌
func (m *JWTManager) GenerateToken(user *domain.User) (string, error) {
	// 设置过期时间
	expiration := time.Now().Add(time.Duration(m.expirationHours) * time.Hour)

	// 创建声明
	claims := CustomClaims{
		UserID:   user.ID,
		Username: user.Username,
		Email:    user.Email,
		Status:   user.Status,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiration),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   user.ID,
		},
	}

	// 创建令牌
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// 签名令牌
	tokenString, err := token.SignedString([]byte(m.secretKey))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// ValidateToken 验证JWT令牌
func (m *JWTManager) ValidateToken(tokenString string) (*CustomClaims, error) {
	// 解析令牌
	token, err := jwt.ParseWithClaims(
		tokenString,
		&CustomClaims{},
		func(token *jwt.Token) (interface{}, error) {
			// 验证签名方法
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, errors.New("unexpected signing method")
			}
			return []byte(m.secretKey), nil
		},
	)

	if err != nil {
		return nil, err
	}

	// 验证令牌有效性
	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	// 提取声明
	claims, ok := token.Claims.(*CustomClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	return claims, nil
}