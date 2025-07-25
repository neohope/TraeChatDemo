import 'package:flutter/foundation.dart';

/// 会话模型类
/// 
/// 用于表示聊天会话的数据结构，包括单聊和群聊
class ConversationModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isGroup;
  final String? participantId; // 单聊时的参与者ID
  final List<String>? participantIds; // 群聊时的参与者ID列表
  final String? lastMessage;
  final MessageType lastMessageType;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final bool isOnline; // 单聊时对方是否在线
  final UserStatus? participantStatus; // 单聊时对方的状态
  final String? lastMessageSenderId; // 最后一条消息的发送者ID
  
  /// 头像URL的别名getter
  String? get avatar => avatarUrl;
  
  ConversationModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isGroup,
    this.participantId,
    this.participantIds,
    this.lastMessage,
    this.lastMessageType = MessageType.text,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.isOnline = false,
    this.participantStatus,
    this.lastMessageSenderId,
  });
  
  /// 创建单聊会话
  factory ConversationModel.createSingleChat({
    required String id,
    required String participantId,
    required String participantName,
    String? participantAvatarUrl,
    String? lastMessage,
    MessageType lastMessageType = MessageType.text,
    required DateTime lastMessageTime,
    int unreadCount = 0,
    bool isPinned = false,
    bool isMuted = false,
    bool isArchived = false,
    bool isOnline = false,
    UserStatus? participantStatus,
    String? lastMessageSenderId,
  }) {
    return ConversationModel(
      id: id,
      name: participantName,
      avatarUrl: participantAvatarUrl,
      isGroup: false,
      participantId: participantId,
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isPinned: isPinned,
      isMuted: isMuted,
      isArchived: isArchived,
      isOnline: isOnline,
      participantStatus: participantStatus,
      lastMessageSenderId: lastMessageSenderId,
    );
  }
  
  /// 创建群聊会话
  factory ConversationModel.createGroupChat({
    required String id,
    required String groupName,
    String? groupAvatarUrl,
    required List<String> participantIds,
    String? lastMessage,
    MessageType lastMessageType = MessageType.text,
    required DateTime lastMessageTime,
    int unreadCount = 0,
    bool isPinned = false,
    bool isMuted = false,
    bool isArchived = false,
  }) {
    return ConversationModel(
      id: id,
      name: groupName,
      avatarUrl: groupAvatarUrl,
      isGroup: true,
      participantIds: participantIds,
      lastMessage: lastMessage,
      lastMessageType: lastMessageType,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isPinned: isPinned,
      isMuted: isMuted,
      isArchived: isArchived,
    );
  }
  
  /// 从JSON创建会话模型
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      isGroup: json['isGroup'] ?? false,
      participantId: json['participantId'],
      participantIds: json['participantIds'] != null
          ? List<String>.from(json['participantIds'])
          : null,
      lastMessage: json['lastMessage'],
      lastMessageType: _parseMessageType(json['lastMessageType']),
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isOnline: json['isOnline'] ?? false,
      participantStatus: json['participantStatus'] != null
          ? _parseUserStatus(json['participantStatus'])
          : null,
      lastMessageSenderId: json['lastMessageSenderId'],
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isGroup': isGroup,
      'participantId': participantId,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType.toString().split('.').last,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'isArchived': isArchived,
      'isOnline': isOnline,
      'participantStatus': participantStatus?.toString().split('.').last,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }
  
  /// 创建会话的副本并更新属性
  ConversationModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isGroup,
    String? participantId,
    List<String>? participantIds,
    String? lastMessage,
    MessageType? lastMessageType,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    bool? isOnline,
    UserStatus? participantStatus,
    String? lastMessageSenderId,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGroup: isGroup ?? this.isGroup,
      participantId: participantId ?? this.participantId,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isOnline: isOnline ?? this.isOnline,
      participantStatus: participantStatus ?? this.participantStatus,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ConversationModel &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.isGroup == isGroup &&
        other.participantId == participantId &&
        listEquals(other.participantIds, participantIds) &&
        other.lastMessage == lastMessage &&
        other.lastMessageType == lastMessageType &&
        other.lastMessageTime == lastMessageTime &&
        other.unreadCount == unreadCount &&
        other.isPinned == isPinned &&
        other.isMuted == isMuted &&
        other.isArchived == isArchived &&
        other.isOnline == isOnline &&
        other.participantStatus == participantStatus;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        avatarUrl.hashCode ^
        isGroup.hashCode ^
        participantId.hashCode ^
        participantIds.hashCode ^
        lastMessage.hashCode ^
        lastMessageType.hashCode ^
        lastMessageTime.hashCode ^
        unreadCount.hashCode ^
        isPinned.hashCode ^
        isMuted.hashCode ^
        isArchived.hashCode ^
        isOnline.hashCode ^
        participantStatus.hashCode;
  }
}

/// 消息类型枚举
enum MessageType {
  text,
  image,
  voice,
  video,
  file,
  location,
  system,
  custom,
  recalled, // 撤回消息
}

/// 用户状态枚举
enum UserStatus {
  online,
  offline,
  away,
  busy,
}

/// 消息状态枚举
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed
}

/// 解析消息类型
MessageType _parseMessageType(String? type) {
  if (type == null) return MessageType.text;
  
  switch (type) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'voice':
      return MessageType.voice;
    case 'audio': // 兼容 audio 类型
      return MessageType.voice;
    case 'video':
      return MessageType.video;
    case 'file':
      return MessageType.file;
    case 'location':
      return MessageType.location;
    case 'system':
      return MessageType.system;
    case 'custom':
      return MessageType.custom;
    case 'recalled':
      return MessageType.recalled;
    default:
      return MessageType.text;
  }
}

/// 解析用户状态
UserStatus _parseUserStatus(String? status) {
  if (status == null) return UserStatus.offline;
  
  switch (status) {
    case 'online':
      return UserStatus.online;
    case 'offline':
      return UserStatus.offline;
    case 'away':
      return UserStatus.away;
    case 'busy':
      return UserStatus.busy;
    default:
      return UserStatus.offline;
  }
}