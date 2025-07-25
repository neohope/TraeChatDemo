import 'user_model.dart';

/// 好友请求状态枚举
enum FriendRequestStatus {
  pending,   // 待处理
  accepted,  // 已接受
  rejected,  // 已拒绝
  cancelled, // 已取消
  expired,   // 已过期
}

/// 好友请求类型枚举
enum FriendRequestType {
  normal,    // 普通请求
  mutual,    // 互相添加
  recommended, // 推荐添加
}

/// 好友请求模型
class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String? message;
  final FriendRequestStatus status;
  final FriendRequestType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;
  
  // 关联的用户信息（可选，用于显示）
  final UserModel? sender;
  final UserModel? receiver;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.message,
    required this.status,
    this.type = FriendRequestType.normal,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.metadata,
    this.sender,
    this.receiver,
  });

  /// 从JSON创建FriendRequest对象
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String?,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      type: FriendRequestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FriendRequestType.normal,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'])
          : null,
      receiver: json['receiver'] != null
          ? UserModel.fromJson(json['receiver'])
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'status': status.name,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
    };
  }

  /// 创建副本
  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    FriendRequestStatus? status,
    FriendRequestType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    UserModel? sender,
    UserModel? receiver,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
    );
  }

  /// 是否为待处理状态
  bool get isPending => status == FriendRequestStatus.pending;

  /// 是否已接受
  bool get isAccepted => status == FriendRequestStatus.accepted;

  /// 是否已拒绝
  bool get isRejected => status == FriendRequestStatus.rejected;

  /// 是否已取消
  bool get isCancelled => status == FriendRequestStatus.cancelled;

  /// 是否已过期
  bool get isExpired {
    if (status == FriendRequestStatus.expired) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否为发送的请求
  bool isSentBy(String userId) => senderId == userId;

  /// 是否为接收的请求
  bool isReceivedBy(String userId) => receiverId == userId;

  /// 获取对方用户ID
  String getOtherUserId(String currentUserId) {
    return senderId == currentUserId ? receiverId : senderId;
  }

  /// 获取对方用户信息
  UserModel? getOtherUser(String currentUserId) {
    if (senderId == currentUserId) {
      return receiver;
    } else {
      return sender;
    }
  }

  /// 获取显示的消息内容
  String getDisplayMessage() {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    
    switch (type) {
      case FriendRequestType.mutual:
        return '互相添加为好友';
      case FriendRequestType.recommended:
        return '推荐添加为好友';
      default:
        return '请求添加为好友';
    }
  }

  /// 获取状态显示文本
  String getStatusText() {
    switch (status) {
      case FriendRequestStatus.pending:
        return '待处理';
      case FriendRequestStatus.accepted:
        return '已接受';
      case FriendRequestStatus.rejected:
        return '已拒绝';
      case FriendRequestStatus.cancelled:
        return '已取消';
      case FriendRequestStatus.expired:
        return '已过期';
    }
  }

  /// 获取类型显示文本
  String getTypeText() {
    switch (type) {
      case FriendRequestType.normal:
        return '普通请求';
      case FriendRequestType.mutual:
        return '互相添加';
      case FriendRequestType.recommended:
        return '推荐添加';
    }
  }

  /// 是否可以接受
  bool get canAccept => isPending && !isExpired;

  /// 是否可以拒绝
  bool get canReject => isPending && !isExpired;

  /// 是否可以取消
  bool get canCancel => isPending && !isExpired;

  /// 获取剩余有效时间（小时）
  int? getRemainingHours() {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inHours;
  }

  /// 获取剩余有效时间描述
  String? getRemainingTimeText() {
    final hours = getRemainingHours();
    if (hours == null) return null;
    
    if (hours <= 0) {
      return '已过期';
    } else if (hours < 24) {
      return '${hours}小时后过期';
    } else {
      final days = (hours / 24).floor();
      return '${days}天后过期';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest &&
        other.id == id &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.message == message &&
        other.status == status &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      senderId,
      receiverId,
      message,
      status,
      type,
      createdAt,
      updatedAt,
      expiresAt,
    );
  }

  @override
  String toString() {
    return 'FriendRequest(id: $id, senderId: $senderId, receiverId: $receiverId, status: $status, type: $type)';
  }
}

/// 好友请求统计信息
class FriendRequestStats {
  final int totalRequests;
  final int pendingRequests;
  final int acceptedRequests;
  final int rejectedRequests;
  final int cancelledRequests;
  final int expiredRequests;
  final int sentRequests;
  final int receivedRequests;

  const FriendRequestStats({
    required this.totalRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.rejectedRequests,
    required this.cancelledRequests,
    required this.expiredRequests,
    required this.sentRequests,
    required this.receivedRequests,
  });

  /// 从好友请求列表计算统计信息
  factory FriendRequestStats.fromRequests(
    List<FriendRequest> requests,
    String currentUserId,
  ) {
    int pending = 0;
    int accepted = 0;
    int rejected = 0;
    int cancelled = 0;
    int expired = 0;
    int sent = 0;
    int received = 0;

    for (final request in requests) {
      // 统计状态
      switch (request.status) {
        case FriendRequestStatus.pending:
          pending++;
          break;
        case FriendRequestStatus.accepted:
          accepted++;
          break;
        case FriendRequestStatus.rejected:
          rejected++;
          break;
        case FriendRequestStatus.cancelled:
          cancelled++;
          break;
        case FriendRequestStatus.expired:
          expired++;
          break;
      }

      // 统计发送/接收
      if (request.senderId == currentUserId) {
        sent++;
      } else {
        received++;
      }
    }

    return FriendRequestStats(
      totalRequests: requests.length,
      pendingRequests: pending,
      acceptedRequests: accepted,
      rejectedRequests: rejected,
      cancelledRequests: cancelled,
      expiredRequests: expired,
      sentRequests: sent,
      receivedRequests: received,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'pending_requests': pendingRequests,
      'accepted_requests': acceptedRequests,
      'rejected_requests': rejectedRequests,
      'cancelled_requests': cancelledRequests,
      'expired_requests': expiredRequests,
      'sent_requests': sentRequests,
      'received_requests': receivedRequests,
    };
  }

  @override
  String toString() {
    return 'FriendRequestStats(total: $totalRequests, pending: $pendingRequests, sent: $sentRequests, received: $receivedRequests)';
  }
}