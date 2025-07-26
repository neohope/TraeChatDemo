package service

import (
	"context"
	"errors"
	"strings"

	"go.uber.org/zap"

	"github.com/neohope/chatapp/user-service/internal/domain"
	"github.com/neohope/chatapp/user-service/pkg/auth"
)

// UserService 实现domain.UserService接口
type UserService struct {
	userRepo   domain.UserRepository
	jwtManager *auth.JWTManager
	logger     *zap.Logger
}

// NewUserService 创建一个新的用户服务
func NewUserService(userRepo domain.UserRepository, jwtManager *auth.JWTManager, logger *zap.Logger) domain.UserService {
	return &UserService{
		userRepo:   userRepo,
		jwtManager: jwtManager,
		logger:     logger,
	}
}

// Register 注册新用户
func (s *UserService) Register(ctx context.Context, user *domain.User, password string) error {
	// 验证邮箱是否已存在
	existingUser, err := s.userRepo.GetByEmail(ctx, user.Email)
	if err == nil && existingUser != nil {
		return errors.New("email already exists")
	}

	// 验证用户名是否已存在
	existingUser, err = s.userRepo.GetByUsername(ctx, user.Username)
	if err == nil && existingUser != nil {
		return errors.New("username already exists")
	}

	// 哈希密码
	hashedPassword, err := auth.HashPassword(password)
	if err != nil {
		s.logger.Error("Failed to hash password", zap.Error(err))
		return errors.New("failed to process password")
	}

	// 设置用户状态和密码
	user.Status = domain.UserStatusActive
	user.Password = hashedPassword

	// 创建用户
	if createErr := s.userRepo.Create(ctx, user); createErr != nil {
		s.logger.Error("Failed to create user", zap.Error(err))
		return errors.New("failed to create user")
	}

	return nil
}

// Login 用户登录
func (s *UserService) Login(ctx context.Context, email, password string) (string, error) {
	// 查找用户
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		s.logger.Info("User not found", zap.String("email", email), zap.Error(err))
		return "", errors.New("invalid email or password")
	}

	s.logger.Info("User found for login", zap.String("email", email), zap.String("userID", user.ID))

	// 检查用户状态
	if user.Status != domain.UserStatusActive {
		s.logger.Info("User account is not active", zap.String("email", email), zap.String("status", string(user.Status)))
		return "", errors.New("account is not active")
	}

	// 验证密码
	s.logger.Info("Checking password", zap.String("email", email))
	if checkErr := auth.CheckPassword(password, user.Password); checkErr != nil {
		s.logger.Info("Invalid password", zap.String("email", email), zap.Error(checkErr))
		return "", errors.New("invalid email or password")
	}

	s.logger.Info("Password verified successfully", zap.String("email", email))

	// 生成JWT令牌
	token, err := s.jwtManager.GenerateToken(user)
	if err != nil {
		s.logger.Error("Failed to generate token", zap.Error(err))
		return "", errors.New("failed to generate authentication token")
	}

	return token, nil
}

// GetUserByID 通过ID获取用户
func (s *UserService) GetUserByID(ctx context.Context, id string) (*domain.User, error) {
	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		s.logger.Info("User not found", zap.String("id", id), zap.Error(err))
		return nil, errors.New("user not found")
	}

	// 清除敏感信息
	user.Password = ""

	return user, nil
}

// UpdateUser 更新用户信息
func (s *UserService) UpdateUser(ctx context.Context, user *domain.User) error {
	// 获取现有用户
	existingUser, err := s.userRepo.GetByID(ctx, user.ID)
	if err != nil {
		s.logger.Info("User not found for update", zap.String("id", user.ID), zap.Error(err))
		return errors.New("user not found")
	}

	// 保留不应更新的字段
	user.Email = existingUser.Email         // 不允许更新邮箱
	user.Username = existingUser.Username   // 不允许更新用户名
	user.Password = existingUser.Password   // 保留原密码
	user.CreatedAt = existingUser.CreatedAt // 保留创建时间

	// 更新用户
	if updateErr := s.userRepo.Update(ctx, user); updateErr != nil {
		s.logger.Error("Failed to update user", zap.String("id", user.ID), zap.Error(updateErr))
		return errors.New("failed to update user")
	}

	return nil
}

// DeleteUser 删除用户
func (s *UserService) DeleteUser(ctx context.Context, id string) error {
	// 检查用户是否存在
	_, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		s.logger.Info("User not found for deletion", zap.String("id", id), zap.Error(err))
		return errors.New("user not found")
	}

	// 删除用户
	if deleteErr := s.userRepo.Delete(ctx, id); deleteErr != nil {
		s.logger.Error("Failed to delete user", zap.String("id", id), zap.Error(deleteErr))
		return errors.New("failed to delete user")
	}

	return nil
}

// ListUsers 获取用户列表
func (s *UserService) ListUsers(ctx context.Context, limit, offset int) ([]*domain.User, error) {
	users, err := s.userRepo.List(ctx, limit, offset)
	if err != nil {
		s.logger.Error("Failed to list users", zap.Error(err))
		return nil, errors.New("failed to retrieve users")
	}

	// 清除敏感信息
	for _, user := range users {
		user.Password = ""
	}

	return users, nil
}

// ChangePassword 修改用户密码
func (s *UserService) ChangePassword(ctx context.Context, userID, oldPassword, newPassword string) error {
	// 获取用户
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		s.logger.Info("User not found for password change", zap.String("id", userID), zap.Error(err))
		return errors.New("user not found")
	}

	// 验证旧密码
	if checkErr := auth.CheckPassword(oldPassword, user.Password); checkErr != nil {
		s.logger.Info("Invalid old password", zap.String("id", userID))
		return errors.New("invalid old password")
	}

	// 验证新密码
	if strings.TrimSpace(newPassword) == "" || len(newPassword) < 8 {
		return errors.New("new password must be at least 8 characters long")
	}

	// 哈希新密码
	hashedPassword, err := auth.HashPassword(newPassword)
	if err != nil {
		s.logger.Error("Failed to hash new password", zap.Error(err))
		return errors.New("failed to process new password")
	}

	// 更新密码
	user.Password = hashedPassword
	if updateErr := s.userRepo.Update(ctx, user); updateErr != nil {
		s.logger.Error("Failed to update password", zap.String("id", userID), zap.Error(updateErr))
		return errors.New("failed to update password")
	}

	return nil
}
