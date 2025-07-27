package delivery

import (
	"context"
	"net/http"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/neohope/chatapp/api-gateway/pkg/auth"
)

type Middleware struct {
	jwtManager  *auth.JWTManager
	logger      *zap.Logger
	rateLimiter *RateLimiter
}

type RateLimiter struct {
	mu      sync.Mutex
	clients map[string]*Client
	rps     int
	enabled bool
}

type Client struct {
	lastSeen time.Time
	tokens   int
}

func NewMiddleware(jwtManager *auth.JWTManager, logger *zap.Logger, rateLimitEnabled bool, rps int) *Middleware {
	return &Middleware{
		jwtManager: jwtManager,
		logger:     logger,
		rateLimiter: &RateLimiter{
			clients: make(map[string]*Client),
			rps:     rps,
			enabled: rateLimitEnabled,
		},
	}
}

// CORS middleware
func (m *Middleware) CORS(allowedOrigins, allowedMethods, allowedHeaders []string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			
			// 检查是否允许所有来源
			allowAll := false
			for _, allowedOrigin := range allowedOrigins {
				if allowedOrigin == "*" {
					allowAll = true
					break
				}
			}

			if allowAll {
				// 允许所有来源
				w.Header().Set("Access-Control-Allow-Origin", "*")
			} else if origin != "" {
				// 检查特定来源
				for _, allowedOrigin := range allowedOrigins {
					if allowedOrigin == origin {
						w.Header().Set("Access-Control-Allow-Origin", origin)
						w.Header().Set("Access-Control-Allow-Credentials", "true")
						break
					}
				}
			}

			// 设置其他CORS头
			w.Header().Set("Access-Control-Allow-Methods", joinStrings(allowedMethods, ", "))
			w.Header().Set("Access-Control-Allow-Headers", joinStrings(allowedHeaders, ", "))
			w.Header().Set("Access-Control-Max-Age", "86400") // 24小时预检缓存

			// 处理预检请求
			if r.Method == "OPTIONS" {
				// 确保设置了正确的CORS头
				if origin != "" {
					// 检查特定来源
					for _, allowedOrigin := range allowedOrigins {
						if allowedOrigin == origin || allowedOrigin == "*" {
							w.Header().Set("Access-Control-Allow-Origin", origin)
							w.Header().Set("Access-Control-Allow-Credentials", "true")
							break
						}
					}
				}
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// JWT Authentication middleware
func (m *Middleware) JWTAuth() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token, err := m.jwtManager.ExtractTokenFromHeader(r)
			if err != nil {
				m.logger.Warn("Failed to extract token", zap.Error(err))
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			claims, err := m.jwtManager.ValidateToken(token)
			if err != nil {
				m.logger.Warn("Invalid token", zap.Error(err))
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			// Add user info to context
			ctx := context.WithValue(r.Context(), "user_id", claims.UserID)
			ctx = context.WithValue(ctx, "email", claims.Email)
			r = r.WithContext(ctx)

			next.ServeHTTP(w, r)
		})
	}
}

// Rate limiting middleware
func (m *Middleware) RateLimit() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !m.rateLimiter.enabled {
				next.ServeHTTP(w, r)
				return
			}

			clientIP := r.RemoteAddr
			if !m.rateLimiter.Allow(clientIP) {
				m.logger.Warn("Rate limit exceeded", zap.String("client_ip", clientIP))
				http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// Logging middleware
func (m *Middleware) Logging() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			next.ServeHTTP(w, r)
			duration := time.Since(start)

			m.logger.Info("HTTP Request",
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.String("remote_addr", r.RemoteAddr),
				zap.Duration("duration", duration),
			)
		})
	}
}

func (rl *RateLimiter) Allow(clientIP string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	client, exists := rl.clients[clientIP]

	if !exists {
		rl.clients[clientIP] = &Client{
			lastSeen: now,
			tokens:   rl.rps - 1,
		}
		return true
	}

	// Clean up old clients
	if now.Sub(client.lastSeen) > time.Minute {
		client.tokens = rl.rps
	}

	client.lastSeen = now

	if client.tokens > 0 {
		client.tokens--
		return true
	}

	return false
}

func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return ""
	}
	result := strs[0]
	for i := 1; i < len(strs); i++ {
		result += sep + strs[i]
	}
	return result
}
