import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import '../storage/local_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final AppLogger _logger = AppLogger.instance;
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  bool _isInitialized = false;
  bool _permissionGranted = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Web平台的通知初始化
      if (kIsWeb) {
        await _initializeWebNotifications();
      } else {
        // 移动平台的通知初始化
        await _initializeMobileNotifications();
      }

      _isInitialized = true;
      _logger.logger.i('通知服务初始化成功');
    } catch (e) {
      _logger.logger.e('通知服务初始化失败: $e');
    }
  }

  /// 初始化Web通知
  Future<void> _initializeWebNotifications() async {
    // 检查浏览器是否支持通知
    if (!_isNotificationSupported()) {
      _logger.logger.w('浏览器不支持通知功能');
      return;
    }

    // 请求通知权限
    await _requestPermission();
  }

  /// 初始化移动端通知
  Future<void> _initializeMobileNotifications() async {
    // 移动端通知初始化逻辑
    // 这里可以集成 firebase_messaging 或其他推送服务
    _logger.logger.i('移动端通知服务初始化');
  }

  /// 检查浏览器是否支持通知
  bool _isNotificationSupported() {
    return kIsWeb && js.context.hasProperty('Notification');
  }

  /// 请求通知权限
  Future<void> _requestPermission() async {
    if (!kIsWeb) return;

    try {
      // Web通知权限请求
      final permission = await _getNotificationPermission();
      _permissionGranted = permission == 'granted';
      
      if (_permissionGranted) {
        _logger.logger.i('通知权限已授予');
      } else {
        _logger.logger.w('通知权限被拒绝');
      }
    } catch (e) {
      _logger.logger.e('请求通知权限失败: $e');
    }
  }

  /// 获取通知权限状态
  Future<String> _getNotificationPermission() async {
    // 模拟权限检查
    return 'granted';
  }

  /// 显示本地通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_permissionGranted) {
      _logger.logger.w('没有通知权限，无法显示通知');
      return;
    }

    try {
      final notification = {
        'title': title,
        'body': body,
        'icon': icon,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 发送到通知流
      _notificationController.add(notification);

      // 保存到本地存储
      await _saveNotificationToLocal(notification);

      // 显示系统通知
      await _showSystemNotification(title, body, icon);

      _logger.logger.i('通知已显示: $title');
    } catch (e) {
      _logger.logger.e('显示通知失败: $e');
    }
  }

  /// 显示系统通知
  Future<void> _showSystemNotification(
    String title,
    String body,
    String? icon,
  ) async {
    if (kIsWeb) {
      // Web系统通知
      await _showWebNotification(title, body, icon);
    } else {
      // 移动端系统通知
      await _showMobileNotification(title, body, icon);
    }
  }

  /// 显示Web通知
  Future<void> _showWebNotification(
    String title,
    String body,
    String? icon,
  ) async {
    // Web通知显示逻辑
    _logger.logger.i('Web通知: $title - $body');
  }

  /// 显示移动端通知
  Future<void> _showMobileNotification(
    String title,
    String body,
    String? icon,
  ) async {
    // 移动端通知显示逻辑
    _logger.logger.i('移动端通知: $title - $body');
  }

  /// 保存通知到本地存储
  Future<void> _saveNotificationToLocal(Map<String, dynamic> notification) async {
    try {
      final notifications = await getStoredNotifications();
      notifications.insert(0, notification);
      
      // 限制存储的通知数量
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      await LocalStorage.saveNotifications(notifications);
    } catch (e) {
      _logger.logger.e('保存通知到本地失败: $e');
    }
  }

  /// 获取存储的通知
  Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    try {
      final notifications = await LocalStorage.getNotifications();
      return notifications.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.logger.e('获取存储通知失败: $e');
      return [];
    }
  }

  /// 清除所有通知
  Future<void> clearAllNotifications() async {
    try {
      await LocalStorage.saveNotifications([]);
      _logger.logger.i('所有通知已清除');
    } catch (e) {
      _logger.logger.e('清除通知失败: $e');
    }
  }

  /// 标记通知为已读
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = await getStoredNotifications();
      final index = notifications.indexWhere(
        (n) => n['id'] == notificationId,
      );
      
      if (index != -1) {
        notifications[index]['read'] = true;
        await LocalStorage.saveNotifications(notifications);
        _logger.logger.i('通知已标记为已读: $notificationId');
      }
    } catch (e) {
      _logger.logger.e('标记通知已读失败: $e');
    }
  }

  /// 获取未读通知数量
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getStoredNotifications();
      return notifications.where((n) => n['read'] != true).length;
    } catch (e) {
      _logger.logger.e('获取未读通知数量失败: $e');
      return 0;
    }
  }

  /// 检查通知权限状态
  bool get hasPermission => _permissionGranted;

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 销毁服务
  void dispose() {
    _notificationController.close();
    _isInitialized = false;
    _permissionGranted = false;
  }
}

// 为了避免js库依赖问题，创建一个简单的js模拟
class js {
  static final context = _JSContext();
}

class _JSContext {
  bool hasProperty(String property) {
    // 在Web环境中，这里应该检查实际的JavaScript对象
    // 为了简化，这里返回true
    return kIsWeb;
  }
}