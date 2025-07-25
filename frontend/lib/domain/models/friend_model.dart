class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String friendName;
  final String? friendAvatar;
  final String? friendEmail;
  final String? friendPhone;
  final String status; // pending, accepted, blocked
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? nickname; // 备注名
  final List<String> tags; // 标签
  final bool isFavorite; // 是否收藏
  final bool isBlocked; // 是否屏蔽
  final String? groupId; // 分组ID

  const Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
    this.friendEmail,
    this.friendPhone,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isOnline = false,
    this.lastSeen,
    this.nickname,
    this.tags = const [],
    this.isFavorite = false,
    this.isBlocked = false,
    this.groupId,
  });

  /// 获取显示名称（优先使用备注名）
  String get displayName => nickname?.isNotEmpty == true ? nickname! : friendName;

  /// 检查是否在线
  bool get isCurrentlyOnline => isOnline;

  /// 获取在线状态文本
  String get onlineStatusText {
    if (isOnline) {
      return '在线';
    } else if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inMinutes < 5) {
        return '刚刚在线';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}分钟前在线';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}小时前在线';
      } else {
        return '${difference.inDays}天前在线';
      }
    }
    return '离线';
  }

  /// 从JSON创建Friend对象
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      friendName: json['friendName'] as String,
      friendAvatar: json['friendAvatar'] as String?,
      friendEmail: json['friendEmail'] as String?,
      friendPhone: json['friendPhone'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String) 
          : null,
      nickname: json['nickname'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      groupId: json['groupId'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'friendName': friendName,
      'friendAvatar': friendAvatar,
      'friendEmail': friendEmail,
      'friendPhone': friendPhone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'nickname': nickname,
      'tags': tags,
      'isFavorite': isFavorite,
      'isBlocked': isBlocked,
      'groupId': groupId,
    };
  }

  /// 复制并修改部分属性
  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendName,
    String? friendAvatar,
    String? friendEmail,
    String? friendPhone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    DateTime? lastSeen,
    String? nickname,
    List<String>? tags,
    bool? isFavorite,
    bool? isBlocked,
    String? groupId,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendAvatar: friendAvatar ?? this.friendAvatar,
      friendEmail: friendEmail ?? this.friendEmail,
      friendPhone: friendPhone ?? this.friendPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      nickname: nickname ?? this.nickname,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friend && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Friend(id: $id, friendName: $friendName, status: $status)';
  }
}

/// 好友状态枚举
class FriendStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String blocked = 'blocked';
  static const String rejected = 'rejected';
}