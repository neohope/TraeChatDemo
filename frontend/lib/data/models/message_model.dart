import 'package:flutter/foundation.dart';

/// 消息模型类
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDelivered;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToId;
  final bool isEdited;
  final DateTime? editedAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.metadata,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.isDelivered = false,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
    this.replyToId,
    this.isEdited = false,
    this.editedAt,
  });

  /// 从JSON创建消息模型
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDelivered: json['isDelivered'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      replyToId: json['replyToId'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'metadata': metadata,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDelivered': isDelivered,
      'isRead': isRead,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'replyToId': replyToId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  /// 复制并修改消息
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? type,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDelivered,
    bool? isRead,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? replyToId,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      replyToId: replyToId ?? this.replyToId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.content == content &&
        other.type == type &&
        mapEquals(other.metadata, metadata) &&
        listEquals(other.attachments, attachments) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDelivered == isDelivered &&
        other.isRead == isRead &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt &&
        other.replyToId == replyToId &&
        other.isEdited == isEdited &&
        other.editedAt == editedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      chatId,
      senderId,
      content,
      type,
      metadata,
      attachments,
      createdAt,
      updatedAt,
      isDelivered,
      isRead,
      deliveredAt,
      readAt,
      replyToId,
      isEdited,
      editedAt,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, chatId: $chatId, senderId: $senderId, content: $content, type: $type, createdAt: $createdAt)';
  }
}

/// 消息类型枚举
class MessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String video = 'video';
  static const String audio = 'audio';
  static const String file = 'file';
  static const String location = 'location';
  static const String system = 'system';
  static const String notification = 'notification';
}