package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"go.uber.org/zap"

	"github.com/neohope/chatapp/notification-service/config"
	"github.com/neohope/chatapp/notification-service/internal/domain"
)

type pushService struct {
	deviceRepo domain.UserDeviceRepository
	config     *config.PushConfig
	client     *http.Client
	logger     *zap.Logger
}

type FCMMessage struct {
	To              string                 `json:"to,omitempty"`
	RegistrationIDs []string               `json:"registration_ids,omitempty"`
	Notification    FCMNotification        `json:"notification"`
	Data            map[string]interface{} `json:"data,omitempty"`
	Priority        string                 `json:"priority"`
}

type FCMNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
	Sound string `json:"sound,omitempty"`
	Badge int    `json:"badge,omitempty"`
}

type FCMResponse struct {
	MulticastID  int64       `json:"multicast_id"`
	Success      int         `json:"success"`
	Failure      int         `json:"failure"`
	CanonicalIDs int         `json:"canonical_ids"`
	Results      []FCMResult `json:"results"`
}

type FCMResult struct {
	MessageID      string `json:"message_id,omitempty"`
	RegistrationID string `json:"registration_id,omitempty"`
	Error          string `json:"error,omitempty"`
}

func NewPushService(
	deviceRepo domain.UserDeviceRepository,
	config *config.PushConfig,
	logger *zap.Logger,
) domain.PushService {
	return &pushService{
		deviceRepo: deviceRepo,
		config:     config,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		logger: logger,
	}
}

func (s *pushService) SendToDevice(deviceToken string, notification *domain.PushNotification) error {
	// 获取设备信息
	device, err := s.deviceRepo.GetByDeviceToken(deviceToken)
	if err != nil {
		s.logger.Error("Device not found", zap.String("device_token", deviceToken), zap.Error(err))
		return err
	}

	if !device.IsActive {
		s.logger.Warn("Device is inactive", zap.String("device_token", deviceToken))
		return fmt.Errorf("device is inactive")
	}

	switch device.Platform {
	case "android":
		return s.sendFCM([]string{deviceToken}, notification)
	case "ios":
		return s.sendAPNS(deviceToken, notification)
	default:
		return fmt.Errorf("unsupported platform: %s", device.Platform)
	}
}

func (s *pushService) SendToUser(userID string, notification *domain.PushNotification) error {
	// 获取用户的所有设备
	devices, err := s.deviceRepo.GetByUserID(userID)
	if err != nil {
		s.logger.Error("Failed to get user devices", zap.String("user_id", userID), zap.Error(err))
		return err
	}

	if len(devices) == 0 {
		s.logger.Info("No devices found for user", zap.String("user_id", userID))
		return nil
	}

	// 按平台分组设备
	androidTokens := make([]string, 0)
	iosTokens := make([]string, 0)

	for _, device := range devices {
		if !device.IsActive {
			continue
		}

		switch device.Platform {
		case "android":
			androidTokens = append(androidTokens, device.DeviceToken)
		case "ios":
			iosTokens = append(iosTokens, device.DeviceToken)
		}
	}

	// 发送到Android设备
	if len(androidTokens) > 0 {
		if err := s.sendFCM(androidTokens, notification); err != nil {
			s.logger.Error("Failed to send FCM notification", zap.Error(err))
		}
	}

	// 发送到iOS设备
	for _, token := range iosTokens {
		if err := s.sendAPNS(token, notification); err != nil {
			s.logger.Error("Failed to send APNS notification", zap.String("token", token), zap.Error(err))
		}
	}

	return nil
}

func (s *pushService) SendToMultipleUsers(userIDs []string, notification *domain.PushNotification) error {
	for _, userID := range userIDs {
		if err := s.SendToUser(userID, notification); err != nil {
			s.logger.Error("Failed to send notification to user",
				zap.String("user_id", userID),
				zap.Error(err),
			)
		}
	}
	return nil
}

func (s *pushService) sendFCM(deviceTokens []string, notification *domain.PushNotification) error {
	if s.config.FCMServerKey == "" {
		s.logger.Warn("FCM server key not configured")
		return fmt.Errorf("FCM server key not configured")
	}

	message := FCMMessage{
		RegistrationIDs: deviceTokens,
		Notification: FCMNotification{
			Title: notification.Title,
			Body:  notification.Body,
			Sound: notification.Sound,
			Badge: notification.Badge,
		},
		Data:     notification.Data,
		Priority: "high",
	}

	jsonData, err := json.Marshal(message)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", "https://fcm.googleapis.com/fcm/send", bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "key="+s.config.FCMServerKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("FCM request failed with status: %d", resp.StatusCode)
	}

	var fcmResponse FCMResponse
	if err := json.NewDecoder(resp.Body).Decode(&fcmResponse); err != nil {
		return err
	}

	// 处理失败的设备令牌
	for i, result := range fcmResponse.Results {
		if result.Error != "" {
			s.logger.Warn("FCM delivery failed",
				zap.String("device_token", deviceTokens[i]),
				zap.String("error", result.Error),
			)

			// 如果是无效的令牌，停用设备
			if result.Error == "NotRegistered" || result.Error == "InvalidRegistration" {
				s.deviceRepo.DeactivateDevice(deviceTokens[i])
			}
		}
	}

	s.logger.Info("FCM notification sent",
		zap.Int("success", fcmResponse.Success),
		zap.Int("failure", fcmResponse.Failure),
	)

	return nil
}

func (s *pushService) sendAPNS(deviceToken string, notification *domain.PushNotification) error {
	// 简化的APNS实现
	// 在实际项目中，应该使用官方的APNS库
	s.logger.Info("APNS notification would be sent",
		zap.String("device_token", deviceToken),
		zap.String("title", notification.Title),
		zap.String("body", notification.Body),
	)

	// TODO: 实现真正的APNS推送
	// 这里只是模拟成功
	return nil
}
