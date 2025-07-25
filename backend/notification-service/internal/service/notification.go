package service

import (
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/neohope/chatapp/notification-service/internal/domain"
)

type notificationService struct {
	notificationRepo domain.NotificationRepository
	deviceRepo       domain.UserDeviceRepository
	preferenceRepo   domain.NotificationPreferenceRepository
	pushService      domain.PushService
	logger           *zap.Logger
}

func NewNotificationService(
	notificationRepo domain.NotificationRepository,
	deviceRepo domain.UserDeviceRepository,
	preferenceRepo domain.NotificationPreferenceRepository,
	pushService domain.PushService,
	logger *zap.Logger,
) domain.NotificationService {
	return &notificationService{
		notificationRepo: notificationRepo,
		deviceRepo:       deviceRepo,
		preferenceRepo:   preferenceRepo,
		pushService:      pushService,
		logger:           logger,
	}
}

func (s *notificationService) SendNotification(notification *domain.Notification) error {
	// 生成ID和时间戳
	if notification.ID == "" {
		notification.ID = uuid.New().String()
	}
	notification.CreatedAt = time.Now()
	notification.Status = domain.NotificationStatusPending

	// 检查用户通知偏好
	preferences, err := s.preferenceRepo.GetByUserID(notification.UserID)
	if err != nil {
		s.logger.Error("Failed to get user preferences", zap.Error(err))
		// 使用默认偏好继续处理
	}

	// 根据通知类型检查是否应该发送
	if !s.shouldSendNotification(notification, preferences) {
		s.logger.Info("Notification skipped due to user preferences",
			zap.String("user_id", notification.UserID),
			zap.String("type", string(notification.Type)),
		)
		return nil
	}

	// 保存通知到数据库
	if err := s.notificationRepo.Create(notification); err != nil {
		s.logger.Error("Failed to create notification", zap.Error(err))
		return err
	}

	// 发送推送通知
	if preferences.PushEnabled {
		pushNotification := &domain.PushNotification{
			Title: notification.Title,
			Body:  notification.Body,
			Data:  notification.Data,
			Sound: "default",
		}

		if err := s.pushService.SendToUser(notification.UserID, pushNotification); err != nil {
			s.logger.Error("Failed to send push notification",
				zap.String("user_id", notification.UserID),
				zap.Error(err),
			)
			// 更新状态为失败
			s.notificationRepo.UpdateStatus(notification.ID, domain.NotificationStatusFailed)
			return err
		}
	}

	// 更新状态为已发送
	s.notificationRepo.UpdateStatus(notification.ID, domain.NotificationStatusSent)

	s.logger.Info("Notification sent successfully",
		zap.String("notification_id", notification.ID),
		zap.String("user_id", notification.UserID),
		zap.String("type", string(notification.Type)),
	)

	return nil
}

func (s *notificationService) SendPushNotification(userID string, push *domain.PushNotification) error {
	return s.pushService.SendToUser(userID, push)
}

func (s *notificationService) GetNotifications(userID string, limit, offset int) ([]*domain.Notification, error) {
	return s.notificationRepo.GetByUserID(userID, limit, offset)
}

func (s *notificationService) MarkAsRead(notificationID string) error {
	return s.notificationRepo.MarkAsRead(notificationID)
}

func (s *notificationService) GetUnreadCount(userID string) (int, error) {
	return s.notificationRepo.GetUnreadCount(userID)
}

func (s *notificationService) RegisterDevice(userID, deviceToken, platform string) error {
	// 检查设备是否已存在
	existingDevice, err := s.deviceRepo.GetByDeviceToken(deviceToken)
	if err == nil {
		// 设备已存在，更新用户ID和激活状态
		existingDevice.UserID = userID
		existingDevice.IsActive = true
		existingDevice.UpdatedAt = time.Now()
		return s.deviceRepo.Update(existingDevice)
	}

	// 创建新设备
	device := &domain.UserDevice{
		UserID:      userID,
		DeviceToken: deviceToken,
		Platform:    platform,
		IsActive:    true,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	return s.deviceRepo.Create(device)
}

func (s *notificationService) UnregisterDevice(userID, deviceToken string) error {
	return s.deviceRepo.Delete(userID, deviceToken)
}

func (s *notificationService) UpdatePreferences(userID string, preferences *domain.NotificationPreference) error {
	preferences.UserID = userID
	return s.preferenceRepo.Update(preferences)
}

func (s *notificationService) GetPreferences(userID string) (*domain.NotificationPreference, error) {
	return s.preferenceRepo.GetByUserID(userID)
}

func (s *notificationService) shouldSendNotification(notification *domain.Notification, preferences *domain.NotificationPreference) bool {
	if preferences == nil {
		return true // 默认发送
	}

	switch notification.Type {
	case domain.NotificationTypeMessage:
		return preferences.MessageNotifications
	case domain.NotificationTypeGroupInvite:
		return preferences.GroupNotifications
	case domain.NotificationTypeSystem:
		return preferences.SystemNotifications
	default:
		return true
	}
}
