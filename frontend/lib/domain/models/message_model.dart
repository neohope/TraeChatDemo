import 'package:flutter/foundation.dart';
import 'conversation_model.dart';

/// 消息模型类
/// 
/// 用于表示聊天消息的数据结构，包括文本、图片、语音等多种类型
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? conversationId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  
  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.conversationId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.metadata,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.readAt,
    this.deliveredAt,
  });
  
  /// 创建文本消息
  factory MessageModel.text({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String text,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.text,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
    );
  }
  
  /// 创建图片消息
  factory MessageModel.image({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.image,
      mediaUrl: imageUrl,
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
    );
  }
  
  /// 创建语音消息
  factory MessageModel.voice({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String audioUrl,
    required int durationInSeconds,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.voice,
      mediaUrl: audioUrl,
      metadata: {
        'duration': durationInSeconds,
      },
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
    );
  }
  
  /// 创建视频消息
  factory MessageModel.video({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String videoUrl,
    required String thumbnailUrl,
    required int durationInSeconds,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.video,
      mediaUrl: videoUrl,
      metadata: {
        'thumbnail': thumbnailUrl,
        'duration': durationInSeconds,
      },
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
    );
  }
  
  /// 创建文件消息
  factory MessageModel.file({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? fileType,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.file,
      mediaUrl: fileUrl,
      metadata: {
        'fileName': fileName,
        'fileSize': fileSize,
        'fileType': fileType,
      },
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
    );
  }
  
  /// 创建位置消息
  factory MessageModel.location({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required double latitude,
    required double longitude,
    String? address,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.location,
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
    );
  }
  
  /// 创建系统消息
  factory MessageModel.system({
    required String id,
    required String text,
    String? conversationId,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      senderId: 'system',
      receiverId: conversationId ?? '',
      conversationId: conversationId,
      type: MessageType.system,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      status: MessageStatus.sent,
      isRead: true,
    );
  }
  
  /// 从JSON创建消息模型
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      conversationId: json['conversationId'],
      type: _parseMessageType(json['type']),
      text: json['text'],
      mediaUrl: json['mediaUrl'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
      status: _parseMessageStatus(json['status']),
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'type': type.toString().split('.').last,
      'text': text,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'readAt': readAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }
  
  /// 创建消息的副本并更新属性
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    MessageType? type,
    String? text,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isRead,
    bool? isDeleted,
    bool? isEdited,
    DateTime? readAt,
    DateTime? deliveredAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MessageModel &&
        other.id == id &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.conversationId == conversationId &&
        other.type == type &&
        other.text == text &&
        other.mediaUrl == mediaUrl &&
        mapEquals(other.metadata, metadata) &&
        other.timestamp == timestamp &&
        other.status == status &&
        other.isRead == isRead &&
        other.isDeleted == isDeleted &&
        other.isEdited == isEdited &&
        other.readAt == readAt &&
        other.deliveredAt == deliveredAt;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        conversationId.hashCode ^
        type.hashCode ^
        text.hashCode ^
        mediaUrl.hashCode ^
        metadata.hashCode ^
        timestamp.hashCode ^
        status.hashCode ^
        isRead.hashCode ^
        isDeleted.hashCode ^
        isEdited.hashCode ^
        readAt.hashCode ^
        deliveredAt.hashCode;
  }
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
    case 'video':
      return MessageType.video;
    case 'file':
      return MessageType.file;
    case 'location':
      return MessageType.location;
    case 'system':
      return MessageType.system;
    default:
      return MessageType.text;
  }
}

/// 解析消息状态
MessageStatus _parseMessageStatus(String? status) {
  if (status == null) return MessageStatus.sent;
  
  switch (status) {
    case 'sending':
      return MessageStatus.sending;
    case 'sent':
      return MessageStatus.sent;
    case 'delivered':
      return MessageStatus.delivered;
    case 'read':
      return MessageStatus.read;
    case 'failed':
      return MessageStatus.failed;
    default:
      return MessageStatus.sent;
  }
}