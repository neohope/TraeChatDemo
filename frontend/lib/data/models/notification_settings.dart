// 移除不必要的导入

/// 通知设置模型类
class NotificationSettings {
  /// 是否启用推送通知
  final bool enablePush;
  /// 是否启用邮件通知
  final bool enableEmailNotifications;
  /// 是否启用消息通知
  final bool enableMessageNotifications;
  /// 是否启用群组通知
  final bool enableGroupNotifications;
  /// 是否启用声音
  final bool enableSound;
  /// 是否启用振动
  final bool enableVibration;
  
  /// 构造函数
  NotificationSettings({
    this.enablePush = true,
    this.enableEmailNotifications = true,
    this.enableMessageNotifications = true,
    this.enableGroupNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
  });
  
  /// 从JSON创建通知设置对象
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enablePush: json['enable_push'] as bool? ?? true,
      enableEmailNotifications: json['enable_email_notifications'] as bool? ?? true,
      enableMessageNotifications: json['enable_message_notifications'] as bool? ?? true,
      enableGroupNotifications: json['enable_group_notifications'] as bool? ?? true,
      enableSound: json['enable_sound'] as bool? ?? true,
      enableVibration: json['enable_vibration'] as bool? ?? true,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'enable_push': enablePush,
      'enable_email_notifications': enableEmailNotifications,
      'enable_message_notifications': enableMessageNotifications,
      'enable_group_notifications': enableGroupNotifications,
      'enable_sound': enableSound,
      'enable_vibration': enableVibration,
    };
  }
  
  /// 创建通知设置副本
  NotificationSettings copyWith({
    bool? enablePush,
    bool? enableEmailNotifications,
    bool? enableMessageNotifications,
    bool? enableGroupNotifications,
    bool? enableSound,
    bool? enableVibration,
  }) {
    return NotificationSettings(
      enablePush: enablePush ?? this.enablePush,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableMessageNotifications: enableMessageNotifications ?? this.enableMessageNotifications,
      enableGroupNotifications: enableGroupNotifications ?? this.enableGroupNotifications,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationSettings &&
      other.enablePush == enablePush &&
      other.enableEmailNotifications == enableEmailNotifications &&
      other.enableMessageNotifications == enableMessageNotifications &&
      other.enableGroupNotifications == enableGroupNotifications &&
      other.enableSound == enableSound &&
      other.enableVibration == enableVibration;
  }
  
  @override
  int get hashCode {
    return enablePush.hashCode ^
      enableEmailNotifications.hashCode ^
      enableMessageNotifications.hashCode ^
      enableGroupNotifications.hashCode ^
      enableSound.hashCode ^
      enableVibration.hashCode;
  }
}