import 'conversation_model.dart'; // 导入 UserStatus 枚举

/// 解析用户状态
UserStatus _parseStatus(String? status) {
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


/// 用户模型类
/// 
/// 用于表示用户的数据结构，包括基本信息和状态
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? nickname;
  final UserStatus? status;
  final DateTime? lastSeen;
  final DateTime? lastSeenAt;
  final bool isFavorite;
  final bool isBlocked;
  final bool isVerified;
  final Map<String, dynamic>? metadata;
  
  /// 检查用户是否在线
  bool get isOnline => status == UserStatus.online;
  
  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.nickname,
    this.status,
    this.lastSeen,
    this.lastSeenAt,
    this.isFavorite = false,
    this.isBlocked = false,
    this.isVerified = false,
    this.metadata,
  });
  
  /// 从JSON创建用户模型
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      nickname: json['nickname'],
      status: json['status'] != null
          ? _parseStatus(json['status'])
          : null,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      isVerified: json['isVerified'] ?? false,
      metadata: json['metadata'],
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'nickname': nickname,
      'status': status?.toString().split('.').last,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'isBlocked': isBlocked,
      'isVerified': isVerified,
      'metadata': metadata,
    };
  }
  
  /// 创建用户的副本并更新属性
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? nickname,
    UserStatus? status,
    DateTime? lastSeen,
    DateTime? lastSeenAt,
    bool? isFavorite,
    bool? isBlocked,
    bool? isVerified,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      nickname: nickname ?? this.nickname,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        other.status == status &&
        other.lastSeen == lastSeen &&
        other.isFavorite == isFavorite &&
        other.isBlocked == isBlocked &&
        other.isVerified == isVerified;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        avatarUrl.hashCode ^
        bio.hashCode ^
        status.hashCode ^
        lastSeen.hashCode ^
        isFavorite.hashCode ^
        isBlocked.hashCode ^
        isVerified.hashCode;
  }
}