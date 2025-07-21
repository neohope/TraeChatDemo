import 'dart:convert';

import 'message.dart';
import 'user.dart';
import 'group.dart';

/// 会话类型枚举
enum ConversationType {
  direct,  // 单聊
  group    // 群聊
}

/// 会话模型类，用于表示用户的聊天会话
class Conversation {
  /// 会话ID
  final String id;
  
  /// 会话类型
  final ConversationType type;
  
  /// 会话标题（单聊为对方用户名，群聊为群组名称）
  final String title;
  
  /// 会话头像URL
  final String? avatarUrl;
  
  /// 最后一条消息
  final Message? lastMessage;
  
  /// 未读消息数量
  final int unreadCount;
  
  /// 是否置顶
  final bool isPinned;
  
  /// 是否静音
  final bool isMuted;
  
  /// 是否已归档
  final bool isArchived;
  
  /// 对方用户ID（单聊）
  final String? userId;
  
  /// 对方用户信息（单聊）
  final User? user;
  
  /// 群组ID（群聊）
  final String? groupId;
  
  /// 群组信息（群聊）
  final Group? group;
  
  /// 最后活跃时间
  final DateTime lastActiveTime;
  
  /// 自定义数据
  final Map<String, dynamic>? customData;
  
  /// 构造函数
  Conversation({
    required this.id,
    required this.type,
    required this.title,
    this.avatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.userId,
    this.user,
    this.groupId,
    this.group,
    required this.lastActiveTime,
    this.customData,
  }) : assert(
         (type == ConversationType.direct && userId != null) ||
         (type == ConversationType.group && groupId != null),
         '单聊必须提供用户ID，群聊必须提供群组ID'
       );
  
  /// 从JSON映射创建实例
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      type: _parseConversationType(json['type']),
      title: json['title'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : (json['lastMessage'] != null
              ? Message.fromJson(json['lastMessage'])
              : null),
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      isPinned: json['is_pinned'] ?? json['isPinned'] ?? false,
      isMuted: json['is_muted'] ?? json['isMuted'] ?? false,
      isArchived: json['is_archived'] ?? json['isArchived'] ?? false,
      userId: json['user_id'] ?? json['userId'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      groupId: json['group_id'] ?? json['groupId'],
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      lastActiveTime: json['last_active_time'] != null
          ? DateTime.parse(json['last_active_time'])
          : (json['lastActiveTime'] != null
              ? DateTime.parse(json['lastActiveTime'])
              : DateTime.now()),
      customData: json['custom_data'] ?? json['customData'],
    );
  }
  
  /// 转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'avatar_url': avatarUrl,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_pinned': isPinned,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'user_id': userId,
      'user': user?.toJson(),
      'group_id': groupId,
      'group': group?.toJson(),
      'last_active_time': lastActiveTime.toIso8601String(),
      'custom_data': customData,
    };
  }
  
  /// 创建新实例并更新数据
  Conversation copyWith({
    String? id,
    ConversationType? type,
    String? title,
    String? avatarUrl,
    Message? lastMessage,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    String? userId,
    User? user,
    String? groupId,
    Group? group,
    DateTime? lastActiveTime,
    Map<String, dynamic>? customData,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      groupId: groupId ?? this.groupId,
      group: group ?? this.group,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      customData: customData ?? this.customData,
    );
  }
  
  /// 解析会话类型
  static ConversationType _parseConversationType(dynamic type) {
    if (type == null) return ConversationType.direct;
    
    if (type is ConversationType) return type;
    
    if (type is String) {
      final String typeStr = type.toLowerCase();
      
      switch (typeStr) {
        case 'group':
          return ConversationType.group;
        case 'direct':
        default:
          return ConversationType.direct;
      }
    }
    
    return ConversationType.direct;
  }
  
  /// 是否是单聊会话
  bool get isDirectConversation => type == ConversationType.direct;
  
  /// 是否是群聊会话
  bool get isGroupConversation => type == ConversationType.group;
  
  /// 从JSON字符串创建实例
  factory Conversation.fromJsonString(String jsonString) {
    return Conversation.fromJson(json.decode(jsonString));
  }
  
  /// 转换为JSON字符串
  String toJsonString() {
    return json.encode(toJson());
  }
  
  @override
  String toString() {
    return 'Conversation{id: $id, type: $type, title: $title, unreadCount: $unreadCount}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Conversation && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}