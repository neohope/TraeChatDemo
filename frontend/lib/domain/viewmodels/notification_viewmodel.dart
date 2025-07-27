import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/api_response.dart';
import '../../data/models/notification_settings.dart';
import '../../data/repositories/notification_repository.dart';

/// 通知视图模型，用于管理通知相关的UI状态和业务逻辑
class NotificationViewModel extends ChangeNotifier {
  // 通知仓库实例
  final _notificationRepository = NotificationRepository.instance;
  final _logger = AppLogger.instance.logger;
  
  // 通知列表
  List<Notification> _notifications = [];
  // 未读通知数量
  int _unreadCount = 0;
  // 通知设置
  NotificationSettings? _notificationSettings;
  
  // 加载状态
  bool _isLoading = false;
  // 错误信息
  String? _errorMessage;
  
  /// 获取通知列表
  List<Notification> get notifications => _notifications;
  
  /// 获取未读通知数量
  int get unreadCount => _unreadCount;
  
  /// 获取通知设置
  NotificationSettings? get notificationSettings => _notificationSettings;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 构造函数
  NotificationViewModel() {
    // 初始化加载通知列表和未读数量
    loadNotifications();
    getUnreadCount();
    getNotificationSettings();
  }
  
  /// 加载通知列表
  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _notificationRepository.getNotifications();
      
      if (response.success && response.data != null) {
        _notifications = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载通知列表失败');
      }
    } catch (e) {
      _setError('加载通知列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 获取未读通知数量
  Future<void> getUnreadCount() async {
    try {
      final response = await _notificationRepository.getUnreadNotificationCount();
      
      if (response.success && response.data != null) {
        _unreadCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      // 获取未读数量失败不显示错误，静默处理
      _logger.w('获取未读通知数量失败: $e');
    }
  }
  
  /// 标记通知为已读
  Future<ApiResponse<bool>> markAsRead(String notificationId) async {
    try {
      final response = await _notificationRepository.markNotificationAsRead(notificationId);
      
      if (response.success) {
        // 更新本地通知状态
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWithRead(true);
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      } else {
        _setError(response.message ?? '标记通知为已读失败');
      }
      
      return response;
    } catch (e) {
      _setError('标记通知为已读失败: $e');
      return ApiResponse<bool>.error('标记通知为已读失败: $e');
    }
  }
  
  /// 标记所有通知为已读
  Future<ApiResponse<bool>> markAllAsRead() async {
    try {
      final response = await _notificationRepository.markAllNotificationsAsRead();
      
      if (response.success) {
        // 更新所有本地通知状态
        _notifications = _notifications.map((notification) => 
          notification.copyWithRead(true)
        ).toList();
        _unreadCount = 0;
        notifyListeners();
      } else {
        _setError(response.message ?? '标记所有通知为已读失败');
      }
      
      return response;
    } catch (e) {
      _setError('标记所有通知为已读失败: $e');
      return ApiResponse<bool>.error('标记所有通知为已读失败: $e');
    }
  }
  
  /// 删除通知
  Future<ApiResponse<bool>> deleteNotification(String notificationId) async {
    try {
      final response = await _notificationRepository.deleteNotification(notificationId);
      
      if (response.success) {
        // 从本地列表中删除
        final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
          orElse: () => Notification.empty(),
        );
        
        _notifications.removeWhere((n) => n.id == notificationId);
        
        // 如果删除的是未读通知，减少未读计数
        if (!notification.isRead) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '删除通知失败');
      }
      
      return response;
    } catch (e) {
      _setError('删除通知失败: $e');
      return ApiResponse<bool>.error('删除通知失败: $e');
    }
  }
  
  /// 清空所有通知
  Future<ApiResponse<bool>> clearAllNotifications() async {
    try {
      final response = await _notificationRepository.clearAllNotifications();
      
      if (response.success) {
        // 清空本地通知列表
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      } else {
        _setError(response.message ?? '清空通知失败');
      }
      
      return response;
    } catch (e) {
      _setError('清空通知失败: $e');
      return ApiResponse<bool>.error('清空通知失败: $e');
    }
  }
  
  /// 更新设备推送令牌
  Future<ApiResponse<bool>> updatePushToken(String token, String deviceType) async {
    try {
      return await _notificationRepository.updatePushToken(token, deviceType);
    } catch (e) {
      _setError('更新推送令牌失败: $e');
      return ApiResponse<bool>.error('更新推送令牌失败: $e');
    }
  }
  
  /// 获取通知设置
  Future<void> getNotificationSettings() async {
    try {
      final response = await _notificationRepository.getNotificationSettings();
      
      if (response.success && response.data != null) {
        _notificationSettings = response.data!;
        notifyListeners();
      }
    } catch (e) {
      _logger.e('获取通知设置失败: $e');
    }
  }
  
  /// 更新通知设置
  Future<ApiResponse<NotificationSettings>> updateNotificationSettings({
    bool? enablePush,
    bool? enableEmailNotifications,
    bool? enableMessageNotifications,
    bool? enableGroupNotifications,
    bool? enableSound,
    bool? enableVibration,
  }) async {
    try {
      final response = await _notificationRepository.updateNotificationSettings(
        enablePush: enablePush,
        enableEmailNotifications: enableEmailNotifications,
        enableMessageNotifications: enableMessageNotifications,
        enableGroupNotifications: enableGroupNotifications,
        enableSound: enableSound,
        enableVibration: enableVibration,
      );
      
      if (response.success && response.data != null) {
        _notificationSettings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新通知设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新通知设置失败: $e');
      return ApiResponse<NotificationSettings>.error('更新通知设置失败: $e');
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}