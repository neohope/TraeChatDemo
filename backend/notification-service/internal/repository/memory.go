package repository

import (
	"errors"
	"sort"
	"sync"
	"time"

	"github.com/neohope/chatapp/notification-service/internal/domain"
)

type MemoryNotificationRepository struct {
	mu                sync.RWMutex
	notifications     map[string]*domain.Notification
	userNotifications map[string][]string // userID -> notificationIDs
}

type MemoryUserDeviceRepository struct {
	mu          sync.RWMutex
	devices     map[string]*domain.UserDevice // deviceToken -> UserDevice
	userDevices map[string][]string           // userID -> deviceTokens
}

type MemoryNotificationPreferenceRepository struct {
	mu          sync.RWMutex
	preferences map[string]*domain.NotificationPreference // userID -> preferences
}

func NewMemoryNotificationRepository() *MemoryNotificationRepository {
	return &MemoryNotificationRepository{
		notifications:     make(map[string]*domain.Notification),
		userNotifications: make(map[string][]string),
	}
}

func NewMemoryUserDeviceRepository() *MemoryUserDeviceRepository {
	return &MemoryUserDeviceRepository{
		devices:     make(map[string]*domain.UserDevice),
		userDevices: make(map[string][]string),
	}
}

func NewMemoryNotificationPreferenceRepository() *MemoryNotificationPreferenceRepository {
	return &MemoryNotificationPreferenceRepository{
		preferences: make(map[string]*domain.NotificationPreference),
	}
}

// NotificationRepository implementation
func (r *MemoryNotificationRepository) Create(notification *domain.Notification) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.notifications[notification.ID] = notification
	r.userNotifications[notification.UserID] = append(r.userNotifications[notification.UserID], notification.ID)
	return nil
}

func (r *MemoryNotificationRepository) GetByID(id string) (*domain.Notification, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	notification, exists := r.notifications[id]
	if !exists {
		return nil, errors.New("notification not found")
	}
	return notification, nil
}

func (r *MemoryNotificationRepository) GetByUserID(userID string, limit, offset int) ([]*domain.Notification, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	notificationIDs, exists := r.userNotifications[userID]
	if !exists {
		return []*domain.Notification{}, nil
	}

	// 获取通知并按时间排序
	var notifications []*domain.Notification
	for _, id := range notificationIDs {
		if notification, exists := r.notifications[id]; exists {
			notifications = append(notifications, notification)
		}
	}

	// 按创建时间倒序排序
	sort.Slice(notifications, func(i, j int) bool {
		return notifications[i].CreatedAt.After(notifications[j].CreatedAt)
	})

	// 应用分页
	start := offset
	if start >= len(notifications) {
		return []*domain.Notification{}, nil
	}

	end := start + limit
	if end > len(notifications) {
		end = len(notifications)
	}

	return notifications[start:end], nil
}

func (r *MemoryNotificationRepository) UpdateStatus(id string, status domain.NotificationStatus) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	notification, exists := r.notifications[id]
	if !exists {
		return errors.New("notification not found")
	}

	notification.Status = status
	if status == domain.NotificationStatusSent {
		now := time.Now()
		notification.SentAt = &now
	}
	return nil
}

func (r *MemoryNotificationRepository) MarkAsRead(id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	notification, exists := r.notifications[id]
	if !exists {
		return errors.New("notification not found")
	}

	notification.Status = domain.NotificationStatusRead
	now := time.Now()
	notification.ReadAt = &now
	return nil
}

func (r *MemoryNotificationRepository) Delete(id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	notification, exists := r.notifications[id]
	if !exists {
		return errors.New("notification not found")
	}

	// 从用户通知列表中移除
	userNotifications := r.userNotifications[notification.UserID]
	for i, notificationID := range userNotifications {
		if notificationID == id {
			r.userNotifications[notification.UserID] = append(userNotifications[:i], userNotifications[i+1:]...)
			break
		}
	}

	delete(r.notifications, id)
	return nil
}

func (r *MemoryNotificationRepository) GetUnreadCount(userID string) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	notificationIDs, exists := r.userNotifications[userID]
	if !exists {
		return 0, nil
	}

	count := 0
	for _, id := range notificationIDs {
		if notification, exists := r.notifications[id]; exists {
			if notification.Status != domain.NotificationStatusRead {
				count++
			}
		}
	}

	return count, nil
}

// UserDeviceRepository implementation
func (r *MemoryUserDeviceRepository) Create(device *domain.UserDevice) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.devices[device.DeviceToken] = device
	r.userDevices[device.UserID] = append(r.userDevices[device.UserID], device.DeviceToken)
	return nil
}

func (r *MemoryUserDeviceRepository) GetByUserID(userID string) ([]*domain.UserDevice, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	deviceTokens, exists := r.userDevices[userID]
	if !exists {
		return []*domain.UserDevice{}, nil
	}

	var devices []*domain.UserDevice
	for _, token := range deviceTokens {
		if device, exists := r.devices[token]; exists && device.IsActive {
			devices = append(devices, device)
		}
	}

	return devices, nil
}

func (r *MemoryUserDeviceRepository) GetByDeviceToken(deviceToken string) (*domain.UserDevice, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	device, exists := r.devices[deviceToken]
	if !exists {
		return nil, errors.New("device not found")
	}
	return device, nil
}

func (r *MemoryUserDeviceRepository) Update(device *domain.UserDevice) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.devices[device.DeviceToken]; !exists {
		return errors.New("device not found")
	}

	device.UpdatedAt = time.Now()
	r.devices[device.DeviceToken] = device
	return nil
}

func (r *MemoryUserDeviceRepository) Delete(userID, deviceToken string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// 从设备映射中删除
	delete(r.devices, deviceToken)

	// 从用户设备列表中删除
	userTokens := r.userDevices[userID]
	for i, token := range userTokens {
		if token == deviceToken {
			r.userDevices[userID] = append(userTokens[:i], userTokens[i+1:]...)
			break
		}
	}

	return nil
}

func (r *MemoryUserDeviceRepository) DeactivateDevice(deviceToken string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	device, exists := r.devices[deviceToken]
	if !exists {
		return errors.New("device not found")
	}

	device.IsActive = false
	device.UpdatedAt = time.Now()
	return nil
}

// NotificationPreferenceRepository implementation
func (r *MemoryNotificationPreferenceRepository) Create(preference *domain.NotificationPreference) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.preferences[preference.UserID] = preference
	return nil
}

func (r *MemoryNotificationPreferenceRepository) GetByUserID(userID string) (*domain.NotificationPreference, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	preference, exists := r.preferences[userID]
	if !exists {
		// 返回默认偏好设置
		return &domain.NotificationPreference{
			UserID:               userID,
			PushEnabled:          true,
			EmailEnabled:         true,
			MessageNotifications: true,
			GroupNotifications:   true,
			SystemNotifications:  true,
		}, nil
	}
	return preference, nil
}

func (r *MemoryNotificationPreferenceRepository) Update(preference *domain.NotificationPreference) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.preferences[preference.UserID] = preference
	return nil
}

func (r *MemoryNotificationPreferenceRepository) Delete(userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.preferences, userID)
	return nil
}
