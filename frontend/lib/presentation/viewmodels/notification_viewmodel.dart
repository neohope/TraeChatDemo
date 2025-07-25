import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/services/notification_service.dart';
import '../../domain/models/notification_model.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';

/// 通知ViewModel
class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final LocalStorage _localStorage = LocalStorage();
  final AppLogger _logger = AppLogger.instance;

  // 状态变量
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _fcmToken;
  NotificationSettings _settings = const NotificationSettings();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get fcmToken => _fcmToken;
  NotificationSettings get settings => _settings;
  NotificationSettings get notificationSettings => _settings;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      // 初始化通知服务
      await _notificationService.initialize();
      
      // 获取FCM Token
      _fcmToken = _notificationService.fcmToken;
      
      // 加载设置
      await _loadSettings();
      
      // 加载通知历史
      await _loadNotifications();
      
      _isInitialized = true;
      _logger.info('通知ViewModel初始化成功');
    } catch (e) {
      _setError('初始化通知服务失败: $e');
      _logger.error('通知ViewModel初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载通知设置
  Future<void> _loadSettings() async {
    try {
      final settingsJson = await _localStorage.getString('notification_settings');
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = NotificationSettings.fromJson(settingsMap);
      }
    } catch (e) {
      _logger.error('加载通知设置失败: $e');
    }
  }

  /// 公开的加载通知设置方法
  Future<void> loadSettings() async {
    await _loadSettings();
    notifyListeners();
  }

  /// 保存通知设置
  Future<void> _saveSettings() async {
    try {
      await _localStorage.setString('notification_settings', jsonEncode(_settings.toJson()));
    } catch (e) {
      _logger.error('保存通知设置失败: $e');
    }
  }

  /// 加载通知历史
  Future<void> _loadNotifications() async {
    try {
      final notificationsJson = await _localStorage.getStringList('notifications');
      if (notificationsJson != null) {
        _notifications = notificationsJson
            .map((json) => NotificationModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
            .toList();
        _updateUnreadCount();
      }
    } catch (e) {
      _logger.error('加载通知历史失败: $e');
    }
  }

  /// 保存通知历史
  Future<void> _saveNotifications() async {
    try {
      final notificationsJson = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await _localStorage.setStringList('notifications', notificationsJson);
    } catch (e) {
      _logger.error('保存通知历史失败: $e');
    }
  }

  /// 更新未读数量
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  /// 添加新通知
  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    _updateUnreadCount();
    await _saveNotifications();
    notifyListeners();
  }

  /// 标记通知为已读
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].markAsRead();
      _updateUnreadCount();
      await _saveNotifications();
      notifyListeners();
    }
  }

  /// 标记所有通知为已读
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.markAsRead()).toList();
    _updateUnreadCount();
    await _saveNotifications();
    notifyListeners();
  }

  /// 删除通知
  Future<void> deleteNotification(int notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
    await _saveNotifications();
    notifyListeners();
  }

  /// 清除所有通知
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _unreadCount = 0;
    await _saveNotifications();
    await _notificationService.clearAllNotifications();
    notifyListeners();
  }

  /// 更新通知设置
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// 重置通知设置为默认值
  Future<void> resetSettings() async {
    _settings = const NotificationSettings();
    await _saveSettings();
    notifyListeners();
  }

  /// 切换推送通知
  Future<void> togglePushNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enablePushNotifications: enabled));
  }

  /// 切换声音通知
  Future<void> toggleSoundNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enableSoundNotifications: enabled));
  }

  /// 切换震动通知
  Future<void> toggleVibrationNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enableVibrationNotifications: enabled));
  }

  /// 切换消息通知
  Future<void> toggleMessageNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enableMessageNotifications: enabled));
  }

  /// 切换好友请求通知
  Future<void> toggleFriendRequestNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enableFriendRequestNotifications: enabled));
  }

  /// 切换群组邀请通知
  Future<void> toggleGroupInviteNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enableGroupInviteNotifications: enabled));
  }

  /// 切换系统通知
  Future<void> toggleSystemNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(enableSystemNotifications: enabled));
  }

  /// 切换免打扰模式
  Future<void> toggleDoNotDisturb(bool enabled) async {
    await updateSettings(_settings.copyWith(doNotDisturbEnabled: enabled));
  }

  /// 设置免打扰时间
  Future<void> setDoNotDisturbTime(TimeOfDay? start, TimeOfDay? end) async {
    await updateSettings(_settings.copyWith(
      doNotDisturbStart: start,
      doNotDisturbEnd: end,
    ));
  }

  /// 设置通知铃声
  Future<void> setNotificationSound(String sound) async {
    await updateSettings(_settings.copyWith(notificationSound: sound));
  }

  /// 订阅主题
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
      _logger.info('已订阅主题: $topic');
    } catch (e) {
      _setError('订阅主题失败: $e');
    }
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
      _logger.info('已取消订阅主题: $topic');
    } catch (e) {
      _setError('取消订阅主题失败: $e');
    }
  }

  /// 检查通知权限
  Future<bool> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      _setError('检查通知权限失败: $e');
      return false;
    }
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        _logger.info('通知权限已授予');
        return true;
      } else if (status.isDenied) {
        _setError('通知权限被拒绝');
        return false;
      } else if (status.isPermanentlyDenied) {
        _setError('通知权限被永久拒绝，请在设置中手动开启');
        return false;
      }
      return false;
    } catch (e) {
      _setError('请求通知权限失败: $e');
      return false;
    }
  }

  /// 获取通知统计
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{
      'total': _notifications.length,
      'unread': _unreadCount,
      'message': 0,
      'friendRequest': 0,
      'groupInvite': 0,
      'system': 0,
      'other': 0,
    };

    for (final notification in _notifications) {
      switch (notification.type) {
        case NotificationType.message:
          stats['message'] = (stats['message'] ?? 0) + 1;
          break;
        case NotificationType.friendRequest:
          stats['friendRequest'] = (stats['friendRequest'] ?? 0) + 1;
          break;
        case NotificationType.groupInvite:
          stats['groupInvite'] = (stats['groupInvite'] ?? 0) + 1;
          break;
        case NotificationType.system:
          stats['system'] = (stats['system'] ?? 0) + 1;
          break;
        case NotificationType.other:
          stats['other'] = (stats['other'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadNotifications();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}