import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// 通知类型枚举
enum NotificationType {
  message,      // 聊天消息
  friendRequest, // 好友请求
  groupInvite,  // 群组邀请
  system,       // 系统通知
  other,        // 其他
}

/// 通知优先级枚举
enum NotificationPriority {
  low,      // 低优先级
  normal,   // 普通优先级
  high,     // 高优先级
  urgent,   // 紧急优先级
}

/// 通知模型
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
  });

  /// 从Firebase RemoteMessage创建
  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    return NotificationModel(
      id: message.hashCode,
      title: notification?.title ?? '新消息',
      body: notification?.body ?? '',
      type: _parseNotificationType(data['type']),
      data: data,
      timestamp: DateTime.now(),
    );
  }

  /// 从JSON创建
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseNotificationType(json['type']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// 解析通知类型
  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString?.toLowerCase()) {
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

  /// 复制并修改
  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// 标记为已读
  NotificationModel markAsRead() {
    return copyWith(isRead: true);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, body: $body, type: $type, isRead: $isRead)';
  }
}

/// 通知设置模型
class NotificationSettings {
  final bool enabled;
  final bool enablePushNotifications;
  final bool enableSoundNotifications;
  final bool enableVibrationNotifications;
  final bool enableMessageNotifications;
  final bool enableFriendRequestNotifications;
  final bool enableGroupInviteNotifications;
  final bool enableSystemNotifications;
  final String notificationSound;
  final bool doNotDisturbEnabled;
  final TimeOfDay? doNotDisturbStart;
  final TimeOfDay? doNotDisturbEnd;
  final int duration;
  final NotificationPriority priority;
  final double volume;
  final bool soundEnabled;
  final bool securityEnabled;
  final bool quietHoursEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final bool systemEnabled;
  final bool groupEnabled;
  final bool friendEnabled;
  final bool vibrationEnabled;
  final bool showPreview;
  final bool messageEnabled;

  const NotificationSettings({
    this.enabled = true,
    this.enablePushNotifications = true,
    this.enableSoundNotifications = true,
    this.enableVibrationNotifications = true,
    this.enableMessageNotifications = true,
    this.enableFriendRequestNotifications = true,
    this.enableGroupInviteNotifications = true,
    this.enableSystemNotifications = true,
    this.notificationSound = 'default',
    this.doNotDisturbEnabled = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
    this.duration = 5,
    this.priority = NotificationPriority.normal,
    this.volume = 0.8,
    this.soundEnabled = true,
    this.securityEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.systemEnabled = true,
    this.groupEnabled = true,
    this.friendEnabled = true,
    this.vibrationEnabled = true,
    this.showPreview = true,
    this.messageEnabled = true,
  });

  /// 从JSON创建
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableSoundNotifications: json['enableSoundNotifications'] ?? true,
      enableVibrationNotifications: json['enableVibrationNotifications'] ?? true,
      enableMessageNotifications: json['enableMessageNotifications'] ?? true,
      enableFriendRequestNotifications: json['enableFriendRequestNotifications'] ?? true,
      enableGroupInviteNotifications: json['enableGroupInviteNotifications'] ?? true,
      enableSystemNotifications: json['enableSystemNotifications'] ?? true,
      notificationSound: json['notificationSound'] ?? 'default',
      doNotDisturbEnabled: json['doNotDisturbEnabled'] ?? false,
      doNotDisturbStart: json['doNotDisturbStart'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(json['doNotDisturbStart']))
          : null,
      doNotDisturbEnd: json['doNotDisturbEnd'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(json['doNotDisturbEnd']))
          : null,
      duration: json['duration'] ?? 5,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      securityEnabled: json['securityEnabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(json['quietHoursStart']))
          : null,
      quietHoursEnd: json['quietHoursEnd'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(json['quietHoursEnd']))
          : null,
      systemEnabled: json['systemEnabled'] as bool? ?? true,
      groupEnabled: json['groupEnabled'] as bool? ?? true,
      friendEnabled: json['friendEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      showPreview: json['showPreview'] as bool? ?? true,
      messageEnabled: json['messageEnabled'] as bool? ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'enablePushNotifications': enablePushNotifications,
      'enableSoundNotifications': enableSoundNotifications,
      'enableVibrationNotifications': enableVibrationNotifications,
      'enableMessageNotifications': enableMessageNotifications,
      'enableFriendRequestNotifications': enableFriendRequestNotifications,
      'enableGroupInviteNotifications': enableGroupInviteNotifications,
      'enableSystemNotifications': enableSystemNotifications,
      'notificationSound': notificationSound,
      'doNotDisturbEnabled': doNotDisturbEnabled,
      'doNotDisturbStart': doNotDisturbStart?.format24Hour(),
      'doNotDisturbEnd': doNotDisturbEnd?.format24Hour(),
      'duration': duration,
      'priority': priority.name,
      'volume': volume,
      'soundEnabled': soundEnabled,
      'securityEnabled': securityEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart?.format24Hour(),
      'quietHoursEnd': quietHoursEnd?.format24Hour(),
      'systemEnabled': systemEnabled,
      'groupEnabled': groupEnabled,
      'friendEnabled': friendEnabled,
      'vibrationEnabled': vibrationEnabled,
      'showPreview': showPreview,
      'messageEnabled': messageEnabled,
    };
  }

  /// 复制并修改
  NotificationSettings copyWith({
    bool? enabled,
    bool? enablePushNotifications,
    bool? enableSoundNotifications,
    bool? enableVibrationNotifications,
    bool? enableMessageNotifications,
    bool? enableFriendRequestNotifications,
    bool? enableGroupInviteNotifications,
    bool? enableSystemNotifications,
    String? notificationSound,
    bool? doNotDisturbEnabled,
    TimeOfDay? doNotDisturbStart,
    TimeOfDay? doNotDisturbEnd,
    int? duration,
    NotificationPriority? priority,
    double? volume,
    bool? soundEnabled,
    bool? securityEnabled,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? systemEnabled,
    bool? groupEnabled,
    bool? friendEnabled,
    bool? vibrationEnabled,
    bool? showPreview,
    bool? messageEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableSoundNotifications: enableSoundNotifications ?? this.enableSoundNotifications,
      enableVibrationNotifications: enableVibrationNotifications ?? this.enableVibrationNotifications,
      enableMessageNotifications: enableMessageNotifications ?? this.enableMessageNotifications,
      enableFriendRequestNotifications: enableFriendRequestNotifications ?? this.enableFriendRequestNotifications,
      enableGroupInviteNotifications: enableGroupInviteNotifications ?? this.enableGroupInviteNotifications,
      enableSystemNotifications: enableSystemNotifications ?? this.enableSystemNotifications,
      notificationSound: notificationSound ?? this.notificationSound,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      volume: volume ?? this.volume,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      securityEnabled: securityEnabled ?? this.securityEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      systemEnabled: systemEnabled ?? this.systemEnabled,
      groupEnabled: groupEnabled ?? this.groupEnabled,
      friendEnabled: friendEnabled ?? this.friendEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showPreview: showPreview ?? this.showPreview,
      messageEnabled: messageEnabled ?? this.messageEnabled,
    );
  }

  /// 检查是否在免打扰时间内
  bool get isInDoNotDisturbTime {
    if (!doNotDisturbEnabled || doNotDisturbStart == null || doNotDisturbEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = doNotDisturbStart!;
    final end = doNotDisturbEnd!;

    // 处理跨天的情况
    if (start.hour > end.hour || (start.hour == end.hour && start.minute > end.minute)) {
      // 跨天：例如 22:00 到 08:00
      return (now.hour > start.hour || (now.hour == start.hour && now.minute >= start.minute)) ||
             (now.hour < end.hour || (now.hour == end.hour && now.minute <= end.minute));
    } else {
      // 同一天：例如 08:00 到 22:00
      return (now.hour > start.hour || (now.hour == start.hour && now.minute >= start.minute)) &&
             (now.hour < end.hour || (now.hour == end.hour && now.minute <= end.minute));
    }
  }

  @override
  String toString() {
    return 'NotificationSettings(enablePushNotifications: $enablePushNotifications, doNotDisturbEnabled: $doNotDisturbEnabled)';
  }
}

/// TimeOfDay 扩展
extension TimeOfDayExtension on TimeOfDay {
  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}