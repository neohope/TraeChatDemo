import 'package:flutter/foundation.dart';
import 'message_model.dart';
import 'conversation_model.dart';

/// 聊天类型枚举
enum ChatType {
  private,  // 私聊
  group,    // 群聊
}

/// 聊天状态枚举
enum ChatStatus {
  active,   // 活跃
  archived, // 已归档
  deleted,  // 已删除
}

/// 聊天模型
class Chat {
  final String id;
  final ChatType type;
  final String name;
  final String? description;
  final String? avatarUrl;
  final List<String> participants;
  final MessageModel? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final ChatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Chat({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.status = ChatStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// 从JSON创建Chat对象
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.private,
      ),
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      status: ChatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'participants': participants,
      'last_message': lastMessage?.toJson(),
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'is_pinned': isPinned,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 创建副本
  Chat copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? description,
    String? avatarUrl,
    List<String>? participants,
    MessageModel? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    ChatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 是否为群聊
  bool get isGroup => type == ChatType.group;

  /// 是否为私聊
  bool get isPrivate => type == ChatType.private;

  /// 获取显示名称
  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return name;
    }
    // 对于私聊，返回对方的名称
    return name;
  }

  /// 获取头像URL
  String? getAvatarUrl(String currentUserId) {
    return avatarUrl;
  }

  /// 是否有未读消息
  bool get hasUnreadMessages => unreadCount > 0;

  /// 获取最后消息预览文本
  String getLastMessagePreview() {
    if (lastMessage == null) {
      return '暂无消息';
    }
    
    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.text ?? '';
      case MessageType.image:
        return '[图片]';
      case MessageType.voice:
        return '[语音]';
      case MessageType.video:
        return '[视频]';
      case MessageType.file:
        return '[文件]';
      case MessageType.location:
        return '[位置]';
      case MessageType.system:
        return lastMessage!.text ?? '';
      default:
        return '[未知消息]';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.type == type &&
        other.name == name &&
        other.description == description &&
        other.avatarUrl == avatarUrl &&
        listEquals(other.participants, participants) &&
        other.lastMessage == lastMessage &&
        other.lastMessageTime == lastMessageTime &&
        other.unreadCount == unreadCount &&
        other.isPinned == isPinned &&
        other.isMuted == isMuted &&
        other.isArchived == isArchived &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      name,
      description,
      avatarUrl,
      Object.hashAll(participants),
      lastMessage,
      lastMessageTime,
      unreadCount,
      isPinned,
      isMuted,
      isArchived,
      status,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, type: $type, name: $name, participants: $participants, unreadCount: $unreadCount)';
  }
}