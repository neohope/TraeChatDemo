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
  final bool isRecalled;
  final DateTime? recalledAt;
  final String? originalContent; // 撤回前的原始内容
  final String? replyToId; // 引用的消息ID
  final MessageModel? replyToMessage; // 引用的消息对象
  final String? forwardFromId; // 转发来源消息ID
  final MessageModel? forwardFromMessage; // 转发来源消息对象
  final bool isForwarded; // 是否为转发消息
  
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
    this.isRecalled = false,
    this.recalledAt,
    this.originalContent,
    this.replyToId,
    this.replyToMessage,
    this.forwardFromId,
    this.forwardFromMessage,
    this.isForwarded = false,
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
  
  /// 创建撤回消息
  factory MessageModel.recalled({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String originalContent,
    DateTime? timestamp,
    DateTime? recalledAt,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: MessageType.recalled,
      text: '撤回了一条消息',
      timestamp: timestamp ?? DateTime.now(),
      status: MessageStatus.sent,
      isRead: false,
      isRecalled: true,
      recalledAt: recalledAt ?? DateTime.now(),
      originalContent: originalContent,
    );
  }
  
  /// 撤回当前消息
  MessageModel recall() {
    return copyWith(
      type: MessageType.recalled,
      isRecalled: true,
      recalledAt: DateTime.now(),
      originalContent: text ?? mediaUrl ?? '消息内容',
      text: '撤回了一条消息',
      mediaUrl: null,
      metadata: null,
    );
  }
  
  /// 检查消息是否可以撤回
  bool canRecall({Duration timeLimit = const Duration(minutes: 2)}) {
    if (isRecalled || isDeleted) return false;
    final now = DateTime.now();
    return now.difference(timestamp) <= timeLimit;
  }
  
  /// 创建引用回复消息
  factory MessageModel.reply({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required String text,
    required MessageModel replyToMessage,
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
      replyToId: replyToMessage.id,
      replyToMessage: replyToMessage,
    );
  }
  
  /// 检查消息是否为引用回复
  bool get isReply => replyToId != null;
  
  /// 获取引用消息的预览文本
  String getReplyPreviewText() {
    if (replyToMessage == null) return '';
    
    switch (replyToMessage!.type) {
      case MessageType.text:
        return replyToMessage!.text ?? '';
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
        return '[系统消息]';
      case MessageType.recalled:
        return '[已撤回的消息]';
      default:
        return '[消息]';
    }
  }
  
  /// 创建转发消息
  factory MessageModel.forward({
    required String id,
    required String senderId,
    required String receiverId,
    String? conversationId,
    required MessageModel forwardFromMessage,
    DateTime? timestamp,
    MessageStatus status = MessageStatus.sent,
    bool isRead = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      conversationId: conversationId,
      type: forwardFromMessage.type,
      text: forwardFromMessage.text,
      mediaUrl: forwardFromMessage.mediaUrl,
      metadata: forwardFromMessage.metadata,
      timestamp: timestamp ?? DateTime.now(),
      status: status,
      isRead: isRead,
      forwardFromId: forwardFromMessage.id,
      forwardFromMessage: forwardFromMessage,
      isForwarded: true,
    );
  }
  
  /// 获取转发消息的预览文本
  String getForwardPreviewText() {
    if (forwardFromMessage == null) return '';
    
    switch (forwardFromMessage!.type) {
      case MessageType.text:
        return forwardFromMessage!.text ?? '';
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
        return '[系统消息]';
      case MessageType.recalled:
        return '[已撤回的消息]';
      default:
        return '[消息]';
    }
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
      isRecalled: json['isRecalled'] ?? false,
      recalledAt: json['recalledAt'] != null ? DateTime.parse(json['recalledAt']) : null,
      originalContent: json['originalContent'],
      replyToId: json['replyToId'],
      replyToMessage: json['replyToMessage'] != null ? MessageModel.fromJson(json['replyToMessage']) : null,
      forwardFromId: json['forwardFromId'],
      forwardFromMessage: json['forwardFromMessage'] != null ? MessageModel.fromJson(json['forwardFromMessage']) : null,
      isForwarded: json['isForwarded'] ?? false,
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
      'isRecalled': isRecalled,
      'recalledAt': recalledAt?.toIso8601String(),
      'originalContent': originalContent,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage?.toJson(),
      'forwardFromId': forwardFromId,
      'forwardFromMessage': forwardFromMessage?.toJson(),
      'isForwarded': isForwarded,
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
    bool? isRecalled,
    DateTime? recalledAt,
    String? originalContent,
    String? replyToId,
    MessageModel? replyToMessage,
    String? forwardFromId,
    MessageModel? forwardFromMessage,
    bool? isForwarded,
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
      isRecalled: isRecalled ?? this.isRecalled,
      recalledAt: recalledAt ?? this.recalledAt,
      originalContent: originalContent ?? this.originalContent,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      forwardFromId: forwardFromId ?? this.forwardFromId,
      forwardFromMessage: forwardFromMessage ?? this.forwardFromMessage,
      isForwarded: isForwarded ?? this.isForwarded,
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
    case 'recalled':
      return MessageType.recalled;
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