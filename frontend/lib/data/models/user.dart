import 'dart:convert';

// 使用 domain/models/conversation_model.dart 中定义的 UserStatus 枚举
import '../../domain/models/conversation_model.dart';

/// 用户模型类，用于表示用户数据
class User {
  /// 用户ID
  final String id;
  
  /// 用户名
  final String username;
  
  /// 显示名称
  final String displayName;
  
  /// 电子邮件
  final String email;
  
  /// 头像URL
  final String? avatarUrl;
  
  /// 用户状态
  final UserStatus status;
  
  /// 个人简介
  final String? bio;
  
  /// 电话号码
  final String? phoneNumber;
  
  /// 是否已验证
  final bool isVerified;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后活跃时间
  final DateTime? lastActive;
  
  /// 是否收藏
  final bool isFavorite;
  
  /// 是否被拉黑
  final bool isBlocked;
  
  /// 获取用户名称（优先显示名称，否则显示用户名）
  String get name => displayName.isNotEmpty ? displayName : username;
  
  /// 构造函数
  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.status,
    this.bio,
    this.phoneNumber,
    required this.isVerified,
    required this.createdAt,
    this.lastActive,
    this.isFavorite = false,
    this.isBlocked = false,
  });
  
  /// 从JSON映射创建实例
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? json['full_name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      status: _parseUserStatus(json['status']),
      bio: json['bio'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : (json['lastActive'] != null
              ? DateTime.parse(json['lastActive'])
              : null),
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      isBlocked: json['is_blocked'] ?? json['isBlocked'] ?? false,
    );
  }
  
  /// 转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'status': status.toString().split('.').last,
      'bio': bio,
      'phone_number': phoneNumber,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'is_favorite': isFavorite,
      'is_blocked': isBlocked,
    };
  }
  
  /// 创建新实例并更新数据
  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? avatarUrl,
    UserStatus? status,
    String? bio,
    String? phoneNumber,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isFavorite,
    bool? isBlocked,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
  
  /// 解析用户状态
  static UserStatus _parseUserStatus(dynamic status) {
    if (status == null) return UserStatus.offline;
    
    if (status is UserStatus) return status;
    
    if (status is String) {
      final String statusStr = status.toLowerCase();
      
      switch (statusStr) {
        case 'online':
          return UserStatus.online;
        case 'away':
          return UserStatus.away;
        case 'busy':
          return UserStatus.busy;
        case 'offline':
        default:
          return UserStatus.offline;
      }
    }
    
    return UserStatus.offline;
  }
  
  /// 获取用户状态的显示名称
  String get statusDisplayName {
    switch (status) {
      case UserStatus.online:
        return '在线';
      case UserStatus.offline:
        return '离线';
      case UserStatus.away:
        return '离开';
      case UserStatus.busy:
        return '忙碌';
      // ignore: unreachable_switch_default
      default:
        return '未知';
    }
  }
  
  /// 从JSON字符串创建实例
  factory User.fromJsonString(String jsonString) {
    return User.fromJson(json.decode(jsonString));
  }
  
  /// 转换为JSON字符串
  String toJsonString() {
    return json.encode(toJson());
  }
  
  /// 创建空用户实例
  factory User.empty() {
    return User(
      id: '',
      username: '',
      displayName: '',
      email: '',
      status: UserStatus.offline,
      isVerified: false,
      createdAt: DateTime.now(),
    );
  }
  
  @override
  String toString() {
    return 'User{id: $id, username: $username, displayName: $displayName, email: $email, status: $status}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}