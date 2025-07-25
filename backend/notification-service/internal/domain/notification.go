package domain

import (
	"time"
)

type NotificationType string

const (
	NotificationTypeMessage     NotificationType = "message"
	NotificationTypeGroupInvite NotificationType = "group_invite"
	NotificationTypeFriendRequest NotificationType = "friend_request"
	NotificationTypeSystem      NotificationType = "system"
)

type NotificationStatus string

const (
	NotificationStatusPending NotificationStatus = "pending"
	NotificationStatusSent    NotificationStatus = "sent"
	NotificationStatusRead    NotificationStatus = "read"
	NotificationStatusFailed  NotificationStatus = "failed"
)

type Notification struct {
	ID        string             `json:"id"`
	UserID    string             `json:"user_id"`
	Type      NotificationType   `json:"type"`
	Title     string             `json:"title"`
	Body      string             `json:"body"`
	Data      map[string]interface{} `json:"data,omitempty"`
	Status    NotificationStatus `json:"status"`
	CreatedAt time.Time          `json:"created_at"`
	SentAt    *time.Time         `json:"sent_at,omitempty"`
	ReadAt    *time.Time         `json:"read_at,omitempty"`
}

type PushNotification struct {
	DeviceToken string                 `json:"device_token"`
	Title       string                 `json:"title"`
	Body        string                 `json:"body"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Badge       int                    `json:"badge,omitempty"`
	Sound       string                 `json:"sound,omitempty"`
}

type UserDevice struct {
	UserID      string    `json:"user_id"`
	DeviceToken string    `json:"device_token"`
	Platform    string    `json:"platform"` // ios, android
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type NotificationPreference struct {
	UserID              string `json:"user_id"`
	PushEnabled         bool   `json:"push_enabled"`
	EmailEnabled        bool   `json:"email_enabled"`
	MessageNotifications bool   `json:"message_notifications"`
	GroupNotifications  bool   `json:"group_notifications"`
	SystemNotifications bool   `json:"system_notifications"`
}

// Repository interfaces
type NotificationRepository interface {
	Create(notification *Notification) error
	GetByID(id string) (*Notification, error)
	GetByUserID(userID string, limit, offset int) ([]*Notification, error)
	UpdateStatus(id string, status NotificationStatus) error
	MarkAsRead(id string) error
	Delete(id string) error
	GetUnreadCount(userID string) (int, error)
}

type UserDeviceRepository interface {
	Create(device *UserDevice) error
	GetByUserID(userID string) ([]*UserDevice, error)
	GetByDeviceToken(deviceToken string) (*UserDevice, error)
	Update(device *UserDevice) error
	Delete(userID, deviceToken string) error
	DeactivateDevice(deviceToken string) error
}

type NotificationPreferenceRepository interface {
	Create(preference *NotificationPreference) error
	GetByUserID(userID string) (*NotificationPreference, error)
	Update(preference *NotificationPreference) error
	Delete(userID string) error
}

// Service interfaces
type NotificationService interface {
	SendNotification(notification *Notification) error
	SendPushNotification(userID string, push *PushNotification) error
	GetNotifications(userID string, limit, offset int) ([]*Notification, error)
	MarkAsRead(notificationID string) error
	GetUnreadCount(userID string) (int, error)
	RegisterDevice(userID, deviceToken, platform string) error
	UnregisterDevice(userID, deviceToken string) error
	UpdatePreferences(userID string, preferences *NotificationPreference) error
	GetPreferences(userID string) (*NotificationPreference, error)
}

type PushService interface {
	SendToDevice(deviceToken string, notification *PushNotification) error
	SendToUser(userID string, notification *PushNotification) error
	SendToMultipleUsers(userIDs []string, notification *PushNotification) error
}