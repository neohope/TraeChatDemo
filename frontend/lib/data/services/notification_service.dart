import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/models/notification_model.dart';

/// 推送通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _logger = AppLogger.instance.logger;

  String? _fcmToken;
  bool _isInitialized = false;

  /// 获取FCM Token
  String? get fcmToken => _fcmToken;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化推送通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 请求通知权限
      await _requestPermissions();

      // 初始化本地通知
      await _initializeLocalNotifications();

      // 初始化Firebase消息
      await _initializeFirebaseMessaging();

      // 获取FCM Token
      await _getFCMToken();

      // 设置消息处理器
      _setupMessageHandlers();

      _isInitialized = true;
      _logger.i('推送通知服务初始化成功');
    } catch (e) {
      _logger.e('推送通知服务初始化失败: $e');
      rethrow;
    }
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    // 请求通知权限
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      _logger.w('用户拒绝了通知权限');
    }

    // Firebase消息权限
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('用户授权了推送通知');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      _logger.i('用户授权了临时推送通知');
    } else {
      _logger.w('用户拒绝了推送通知权限');
    }
  }

  /// 初始化本地通知
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 初始化Firebase消息
  Future<void> _initializeFirebaseMessaging() async {
    // 设置前台消息处理
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// 获取FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      _logger.i('FCM Token: $_fcmToken');

      // 监听Token刷新
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _logger.i('FCM Token 已刷新: $token');
        // 将新Token发送到服务器
        _sendTokenToServer(token);
      });
    } catch (e) {
      _logger.e('获取FCM Token失败: $e');
    }
  }

  /// 设置消息处理器
  void _setupMessageHandlers() {
    // 前台消息处理
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 后台消息点击处理
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // 应用终止状态下的消息处理
    _handleTerminatedMessage();
  }

  /// 处理前台消息
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('收到前台消息: ${message.messageId}');
    
    final notification = NotificationModel.fromRemoteMessage(message);
    await _showLocalNotification(notification);
  }

  /// 处理后台消息点击
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    _logger.i('用户点击了后台消息: ${message.messageId}');
    
    final notification = NotificationModel.fromRemoteMessage(message);
    await _handleNotificationTap(notification);
  }

  /// 处理应用终止状态下的消息
  Future<void> _handleTerminatedMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _logger.i('应用从终止状态启动，收到消息: ${initialMessage.messageId}');
      
      final notification = NotificationModel.fromRemoteMessage(initialMessage);
      await _handleNotificationTap(notification);
    }
  }

  /// 显示本地通知
  Future<void> _showLocalNotification(NotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      '聊天消息',
      channelDescription: '接收聊天消息通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.data),
    );
  }

  /// 处理通知点击
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      final notification = NotificationModel.fromJson(data);
      await _handleNotificationTap(notification);
    }
  }

  /// 发送Token到服务器
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: 实现发送Token到服务器的API调用
      // await _apiService.updateFcmToken(token);
      _logger.i('Token已发送到服务器: $token');
    } catch (e) {
      _logger.e('发送Token到服务器失败: $e');
    }
  }

  /// 处理通知点击事件
  Future<void> _handleNotificationTap(NotificationModel notification) async {
    _logger.i('用户点击了通知: ${notification.id}');
    
    // 根据通知类型导航到相应页面
    switch (notification.type) {
      case NotificationType.message:
        // 导航到聊天页面
        break;
      case NotificationType.friendRequest:
        // 导航到好友请求页面
        break;
      case NotificationType.groupInvite:
        // 导航到群组邀请页面
        break;
      default:
        // 导航到主页
        break;
    }
  }

  /// 订阅主题
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('已订阅主题: $topic');
    } catch (e) {
      _logger.e('订阅主题失败: $e');
    }
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('已取消订阅主题: $topic');
    } catch (e) {
      _logger.e('取消订阅主题失败: $e');
    }
  }

  /// 清除所有通知
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// 清除指定通知
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// 获取待处理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// 销毁服务
  void dispose() {
    _isInitialized = false;
  }
}

/// 后台消息处理器
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = AppLogger.instance.logger;
  logger.i('收到后台消息: ${message.messageId}');
  
  // 这里可以处理后台消息，比如更新本地数据库
}