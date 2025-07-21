import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../models/notification_settings.dart';
import '../services/api_service.dart';

/// 通知类型枚举
enum NotificationType {
  /// 消息通知
  message,
  /// 好友请求
  friendRequest,
  /// 群组邀请
  groupInvite,
  /// 系统通知
  system,
  /// 其他通知
  other
}

/// 通知模型类
class Notification {
  /// 通知ID
  final String id;
  /// 通知标题
  final String title;
  /// 通知内容
  final String content;
  /// 通知类型
  final NotificationType type;
  /// 是否已读
  final bool isRead;
  /// 相关数据（如消息ID、用户ID等）
  final Map<String, dynamic>? data;
  /// 创建时间
  final DateTime createdAt;
  
  /// 创建一个空的通知对象
  factory Notification.empty() {
    return Notification(
      id: '',
      title: '',
      content: '',
      type: NotificationType.other,
      isRead: false,
      data: {},
      createdAt: DateTime.now(),
    );
  }
  
  Notification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.isRead = false,
    this.data,
    required this.createdAt,
  });
  
  /// 从JSON创建通知对象
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: _parseNotificationType(json['type'] as String),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'is_read': isRead,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// 创建指定已读状态的通知副本
  Notification copyWithRead(bool read) {
    return Notification(
      id: id,
      title: title,
      content: content,
      type: type,
      isRead: read,
      data: data,
      createdAt: createdAt,
    );
  }
  
  /// 解析通知类型
  static NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr) {
      case 'message':
        return NotificationType.message;
      case 'friend_request':
        return NotificationType.friendRequest;
      case 'group_invite':
        return NotificationType.groupInvite;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.other;
    }
  }
}

/// 通知仓库类，用于管理推送通知和应用内通知
class NotificationRepository {
  // 单例模式
  static final NotificationRepository _instance = NotificationRepository._internal();
  static NotificationRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  NotificationRepository._internal();
  
  /// 获取通知列表
  Future<ApiResponse<List<Notification>>> getNotifications({
    int page = 1,
    int pageSize = 20,
    NotificationType? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (type != null) {
        queryParams['type'] = type.toString().split('.').last;
      }
      
      final response = await _apiService.get<List<dynamic>>(
        '/notifications',
        queryParameters: queryParams,
      );
      
      if (response.success && response.data != null) {
        final notifications = response.data!.map(
          (json) => Notification.fromJson(json as Map<String, dynamic>)
        ).toList();
        
        // 保存到本地存储
        await _saveNotificationsToLocal(notifications);
        
        return ApiResponse<List<Notification>>.success(notifications);
      } else {
        return ApiResponse<List<Notification>>.error(response.message ?? '获取通知列表失败');
      }
    } catch (e) {
      _logger.e('获取通知列表失败: $e');
      
      // 尝试从本地获取
      try {
        final notificationsJson = await LocalStorage.getNotifications();
        if (notificationsJson.isNotEmpty) {
          final localNotifications = notificationsJson.map(
            (json) => Notification.fromJson(json as Map<String, dynamic>)
          ).toList();
          return ApiResponse<List<Notification>>.success(
            localNotifications,
            message: '从本地存储获取的通知',
          );
        }
      } catch (localError) {
        _logger.e('从本地获取通知失败: $localError');
      }
      
      return ApiResponse<List<Notification>>.error('获取通知列表失败: $e');
    }
  }
  
  /// 获取未读通知数量
  Future<ApiResponse<int>> getUnreadNotificationCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      
      if (response.success && response.data != null) {
        final count = response.data!['count'] as int;
        return ApiResponse<int>.success(count);
      } else {
        return ApiResponse<int>.error(response.message ?? '获取未读通知数量失败');
      }
    } catch (e) {
      _logger.e('获取未读通知数量失败: $e');
      
      // 尝试从本地计算
      try {
        final notificationsJson = await LocalStorage.getNotifications();
        if (notificationsJson.isNotEmpty) {
          final localNotifications = notificationsJson.map(
            (json) => Notification.fromJson(json as Map<String, dynamic>)
          ).toList();
          final unreadCount = localNotifications.where((n) => !n.isRead).length;
          return ApiResponse<int>.success(unreadCount, message: '从本地存储计算的未读通知数量');
        }
      } catch (localError) {
        _logger.e('从本地计算未读通知数量失败: $localError');
      }
      
      return ApiResponse<int>.error('获取未读通知数量失败: $e');
    }
  }
  
  /// 标记通知为已读
  Future<ApiResponse<bool>> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/notifications/$notificationId/read',
      );
      
      if (response.success) {
        // 更新本地存储
        await _updateLocalNotificationReadStatus(notificationId, true);
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('标记通知为已读失败: $e');
      
      // 尝试更新本地存储
      try {
        await _updateLocalNotificationReadStatus(notificationId, true);
        return ApiResponse<bool>.success(true, message: '已在本地标记为已读');
      } catch (localError) {
        _logger.e('在本地标记通知为已读失败: $localError');
      }
      
      return ApiResponse<bool>.error('标记通知为已读失败: $e');
    }
  }
  
  /// 标记所有通知为已读
  Future<ApiResponse<bool>> markAllNotificationsAsRead() async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/notifications/read-all',
      );
      
      if (response.success) {
        // 更新本地存储
        await _updateAllLocalNotificationsReadStatus();
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('标记所有通知为已读失败: $e');
      
      // 尝试更新本地存储
      try {
        await _updateAllLocalNotificationsReadStatus();
        return ApiResponse<bool>.success(true, message: '已在本地标记所有通知为已读');
      } catch (localError) {
        _logger.e('在本地标记所有通知为已读失败: $localError');
      }
      
      return ApiResponse<bool>.error('标记所有通知为已读失败: $e');
    }
  }
  
  /// 删除通知
  Future<ApiResponse<bool>> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/notifications/$notificationId',
      );
      
      if (response.success) {
        // 从本地存储中删除
        await _removeNotificationFromLocal(notificationId);
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('删除通知失败: $e');
      
      // 尝试从本地存储中删除
      try {
        await _removeNotificationFromLocal(notificationId);
        return ApiResponse<bool>.success(true, message: '已从本地删除通知');
      } catch (localError) {
        _logger.e('从本地删除通知失败: $localError');
      }
      
      return ApiResponse<bool>.error('删除通知失败: $e');
    }
  }
  
  /// 清空所有通知
  Future<ApiResponse<bool>> clearAllNotifications() async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/notifications/clear-all',
      );
      
      if (response.success) {
        // 清空本地存储
        await LocalStorage.clearNotifications();
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('清空所有通知失败: $e');
      
      // 尝试清空本地存储
      try {
        await LocalStorage.clearNotifications();
        return ApiResponse<bool>.success(true, message: '已清空本地通知');
      } catch (localError) {
        _logger.e('清空本地通知失败: $localError');
      }
      
      return ApiResponse<bool>.error('清空所有通知失败: $e');
    }
  }
  
  /// 更新设备推送令牌
  Future<ApiResponse<bool>> updatePushToken(String token, String deviceType) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/notifications/push-token',
        data: {
          'token': token,
          'device_type': deviceType,
        },
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('更新推送令牌失败: $e');
      return ApiResponse<bool>.error('更新推送令牌失败: $e');
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
      // 获取当前设置
      final currentSettingsResponse = await getNotificationSettings();
      NotificationSettings currentSettings;
      
      if (currentSettingsResponse.success && currentSettingsResponse.data != null) {
        currentSettings = currentSettingsResponse.data!;
      } else {
        currentSettings = NotificationSettings();
      }
      
      // 创建更新后的设置
      final updatedSettings = currentSettings.copyWith(
        enablePush: enablePush,
        enableEmailNotifications: enableEmailNotifications,
        enableMessageNotifications: enableMessageNotifications,
        enableGroupNotifications: enableGroupNotifications,
        enableSound: enableSound,
        enableVibration: enableVibration,
      );
      
      // 发送到服务器
      final response = await _apiService.put<Map<String, dynamic>>(
        '/notifications/settings',
        data: updatedSettings.toJson(),
      );
      
      if (response.success && response.data != null) {
        // 保存到本地存储
        await LocalStorage.saveNotificationSettings(updatedSettings.toJson());
        return ApiResponse<NotificationSettings>.success(updatedSettings);
      } else {
        return ApiResponse<NotificationSettings>.error(response.message ?? '更新通知设置失败');
      }
    } catch (e) {
      _logger.e('更新通知设置失败: $e');
      return ApiResponse<NotificationSettings>.error('更新通知设置失败: $e');
    }
  }
  
  /// 获取通知设置
  Future<ApiResponse<NotificationSettings>> getNotificationSettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/notifications/settings',
      );
      
      if (response.success && response.data != null) {
        // 保存到本地存储
        await LocalStorage.saveNotificationSettings(response.data!);
        final settings = NotificationSettings.fromJson(response.data!);
        return ApiResponse<NotificationSettings>.success(settings);
      } else {
        return ApiResponse<NotificationSettings>.error(response.message ?? '获取通知设置失败');
      }
    } catch (e) {
      _logger.e('获取通知设置失败: $e');
      
      // 尝试从本地获取
      try {
        final settingsJson = await LocalStorage.getNotificationSettings();
        if (settingsJson != null) {
          final settings = NotificationSettings.fromJson(settingsJson);
          return ApiResponse<NotificationSettings>.success(settings, message: '从本地存储获取的通知设置');
        }
      } catch (localError) {
        _logger.e('从本地获取通知设置失败: $localError');
      }
      
      return ApiResponse<NotificationSettings>.error('获取通知设置失败: $e');
    }
  }
  
  /// 将通知保存到本地存储
  Future<void> _saveNotificationsToLocal(List<Notification> notifications) async {
    await LocalStorage.saveNotifications(notifications);
  }
  
  /// 更新本地通知的已读状态
  Future<void> _updateLocalNotificationReadStatus(String notificationId, bool isRead) async {
    final notificationsJson = await LocalStorage.getNotifications();
    final notifications = notificationsJson.map((json) => Notification.fromJson(json)).toList();
    final updatedNotifications = notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWithRead(true);
      }
      return notification;
    }).toList();
    
    await LocalStorage.saveNotifications(updatedNotifications);
  }
  
  /// 更新所有本地通知为已读
  Future<void> _updateAllLocalNotificationsReadStatus() async {
    final notificationsJson = await LocalStorage.getNotifications();
    final notifications = notificationsJson.map((json) => Notification.fromJson(json)).toList();
    final updatedNotifications = notifications.map((notification) {
      return notification.copyWithRead(true);
    }).toList();
    
    await LocalStorage.saveNotifications(updatedNotifications);
  }
  
  /// 从本地存储中删除通知
  Future<void> _removeNotificationFromLocal(String notificationId) async {
    final notificationsJson = await LocalStorage.getNotifications();
    final notifications = notificationsJson.map((json) => Notification.fromJson(json)).toList();
    final updatedNotifications = notifications.where(
      (notification) => notification.id != notificationId
    ).toList();
    
    await LocalStorage.saveNotifications(updatedNotifications);
  }
}