import 'dart:convert';

import 'user.dart';

// 使用 domain/models/conversation_model.dart 中定义的 MessageType 枚举
import '../../domain/models/conversation_model.dart';



/// 消息模型类，用于表示聊天消息数据
class Message {
  /// 消息ID
  final String id;
  
  /// 发送者ID
  final String senderId;
  
  /// 发送者信息（可选）
  final User? sender;
  
  /// 接收者ID（单聊）
  final String? receiverId;
  
  /// 群组ID（群聊）
  final String? groupId;
  
  /// 消息内容
  final String content;
  
  /// 消息类型
  final MessageType type;
  
  /// 消息状态
  final MessageStatus status;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime? updatedAt;
  
  /// 是否已删除
  final bool isDeleted;
  
  /// 回复的消息ID
  final String? replyToMessageId;
  
  /// 媒体URL（图片、视频、音频、文件）
  final String? mediaUrl;
  
  /// 媒体缩略图URL
  final String? thumbnailUrl;
  
  /// 媒体文件名
  final String? fileName;
  
  /// 媒体文件大小（字节）
  final int? fileSize;
  
  /// 媒体时长（音频、视频，秒）
  final int? duration;
  
  /// 位置信息（纬度）
  final double? latitude;
  
  /// 位置信息（经度）
  final double? longitude;
  
  /// 自定义数据
  final Map<String, dynamic>? customData;
  
  /// 构造函数
  Message({
    required this.id,
    required this.senderId,
    this.sender,
    this.receiverId,
    this.groupId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.replyToMessageId,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.latitude,
    this.longitude,
    this.customData,
  }) : assert(receiverId != null || groupId != null, '接收者ID或群组ID必须提供一个');
  
  /// 从JSON映射创建实例
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      receiverId: json['receiver_id'] ?? json['receiverId'],
      groupId: json['group_id'] ?? json['groupId'],
      content: json['content'] ?? '',
      type: _parseMessageType(json['type']),
      status: _parseMessageStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null),
      isDeleted: json['is_deleted'] ?? json['isDeleted'] ?? false,
      replyToMessageId: json['reply_to_message_id'] ?? json['replyToMessageId'],
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      fileName: json['file_name'] ?? json['fileName'],
      fileSize: json['file_size'] ?? json['fileSize'],
      duration: json['duration'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      customData: json['custom_data'] ?? json['customData'],
    );
  }
  
  /// 转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender': sender?.toJson(),
      'receiver_id': receiverId,
      'group_id': groupId,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'reply_to_message_id': replyToMessageId,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'duration': duration,
      'latitude': latitude,
      'longitude': longitude,
      'custom_data': customData,
    };
  }
  
  /// 创建新实例并更新数据
  Message copyWith({
    String? id,
    String? senderId,
    User? sender,
    String? receiverId,
    String? groupId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? replyToMessageId,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? customData,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      receiverId: receiverId ?? this.receiverId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      customData: customData ?? this.customData,
    );
  }
  
  /// 解析消息类型
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    
    if (type is MessageType) return type;
    
    if (type is String) {
      final String typeStr = type.toLowerCase();
      
      switch (typeStr) {
        case 'image':
          return MessageType.image;
        case 'video':
          return MessageType.video;
        case 'audio':
        case 'voice':
          return MessageType.voice;
        case 'file':
          return MessageType.file;
        case 'location':
          return MessageType.location;
        case 'system':
          return MessageType.system;
        case 'custom':
          return MessageType.custom;
        case 'text':
        default:
          return MessageType.text;
      }
    }
    
    return MessageType.text;
  }
  
  /// 解析消息状态
  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    
    if (status is MessageStatus) return status;
    
    if (status is String) {
      final String statusStr = status.toLowerCase();
      
      switch (statusStr) {
        case 'sending':
          return MessageStatus.sending;
        case 'delivered':
          return MessageStatus.delivered;
        case 'read':
          return MessageStatus.read;
        case 'failed':
          return MessageStatus.failed;
        case 'sent':
        default:
          return MessageStatus.sent;
      }
    }
    
    return MessageStatus.sent;
  }
  
  /// 是否是单聊消息
  bool get isDirectMessage => receiverId != null;
  
  /// 是否是群聊消息
  bool get isGroupMessage => groupId != null;
  
  /// 是否是媒体消息
  bool get isMediaMessage => type == MessageType.image || 
                            type == MessageType.video || 
                            type == MessageType.voice || 
                            type == MessageType.file;
  
  /// 从JSON字符串创建实例
  factory Message.fromJsonString(String jsonString) {
    return Message.fromJson(json.decode(jsonString));
  }
  
  /// 转换为JSON字符串
  String toJsonString() {
    return json.encode(toJson());
  }
  
  @override
  String toString() {
    return 'Message{id: $id, senderId: $senderId, type: $type, status: $status, content: $content}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Message && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}