import 'dart:convert';

import 'user.dart';

/// 群组类型枚举
enum GroupType {
  public,  // 公开群组，任何人可以加入
  private, // 私有群组，需要邀请或申请加入
  secret   // 秘密群组，只有通过邀请才能加入，不可被搜索到
}

/// 群组成员角色枚举
enum GroupMemberRole {
  owner,    // 群主
  admin,    // 管理员
  member    // 普通成员
}

/// 群组模型类，用于表示聊天群组数据
class Group {
  /// 群组ID
  final String id;
  
  /// 群组名称
  final String name;
  
  /// 群组描述
  final String? description;
  
  /// 群组头像URL
  final String? avatarUrl;
  
  /// 创建者ID
  final String creatorId;
  
  /// 群组类型
  final GroupType type;
  
  /// 成员数量
  final int memberCount;
  
  /// 最大成员数量
  final int maxMemberCount;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime? updatedAt;
  
  /// 是否已解散
  final bool isDissolved;
  
  /// 群组成员列表
  final List<GroupMember>? members;
  
  /// 自定义数据
  final Map<String, dynamic>? customData;
  
  /// 构造函数
  Group({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.creatorId,
    required this.type,
    required this.memberCount,
    this.maxMemberCount = 200,
    required this.createdAt,
    this.updatedAt,
    this.isDissolved = false,
    this.members,
    this.customData,
  });
  
  /// 从JSON映射创建实例
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      creatorId: json['creator_id'] ?? json['creatorId'],
      type: _parseGroupType(json['type']),
      memberCount: json['member_count'] ?? json['memberCount'] ?? 0,
      maxMemberCount: json['max_member_count'] ?? json['maxMemberCount'] ?? 200,
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
      isDissolved: json['is_dissolved'] ?? json['isDissolved'] ?? false,
      members: json['members'] != null
          ? (json['members'] as List).map((m) => GroupMember.fromJson(m)).toList()
          : null,
      customData: json['custom_data'] ?? json['customData'],
    );
  }
  
  /// 转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'creator_id': creatorId,
      'type': type.toString().split('.').last,
      'member_count': memberCount,
      'max_member_count': maxMemberCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_dissolved': isDissolved,
      'members': members?.map((m) => m.toJson()).toList(),
      'custom_data': customData,
    };
  }
  
  /// 创建新实例并更新数据
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? creatorId,
    GroupType? type,
    int? memberCount,
    int? maxMemberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDissolved,
    List<GroupMember>? members,
    Map<String, dynamic>? customData,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      creatorId: creatorId ?? this.creatorId,
      type: type ?? this.type,
      memberCount: memberCount ?? this.memberCount,
      maxMemberCount: maxMemberCount ?? this.maxMemberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDissolved: isDissolved ?? this.isDissolved,
      members: members ?? this.members,
      customData: customData ?? this.customData,
    );
  }
  
  /// 解析群组类型
  static GroupType _parseGroupType(dynamic type) {
    if (type == null) return GroupType.private;
    
    if (type is GroupType) return type;
    
    if (type is String) {
      final String typeStr = type.toLowerCase();
      
      switch (typeStr) {
        case 'public':
          return GroupType.public;
        case 'secret':
          return GroupType.secret;
        case 'private':
        default:
          return GroupType.private;
      }
    }
    
    return GroupType.private;
  }
  
  /// 从JSON字符串创建实例
  factory Group.fromJsonString(String jsonString) {
    return Group.fromJson(json.decode(jsonString));
  }
  
  /// 转换为JSON字符串
  String toJsonString() {
    return json.encode(toJson());
  }
  
  @override
  String toString() {
    return 'Group{id: $id, name: $name, type: $type, memberCount: $memberCount}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Group && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// 群组成员模型类
class GroupMember {
  /// 用户ID
  final String userId;
  
  /// 用户信息
  final User? user;
  
  /// 群组ID
  final String groupId;
  
  /// 成员角色
  final GroupMemberRole role;
  
  /// 加入时间
  final DateTime joinedAt;
  
  /// 邀请者ID
  final String? invitedBy;
  
  /// 自定义昵称
  final String? nickname;
  
  /// 构造函数
  GroupMember({
    required this.userId,
    this.user,
    required this.groupId,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
    this.nickname,
  });
  
  /// 从JSON映射创建实例
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] ?? json['userId'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      groupId: json['group_id'] ?? json['groupId'],
      role: _parseGroupMemberRole(json['role']),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : (json['joinedAt'] != null
              ? DateTime.parse(json['joinedAt'])
              : DateTime.now()),
      invitedBy: json['invited_by'] ?? json['invitedBy'],
      nickname: json['nickname'],
    );
  }
  
  /// 转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user': user?.toJson(),
      'group_id': groupId,
      'role': role.toString().split('.').last,
      'joined_at': joinedAt.toIso8601String(),
      'invited_by': invitedBy,
      'nickname': nickname,
    };
  }
  
  /// 创建新实例并更新数据
  GroupMember copyWith({
    String? userId,
    User? user,
    String? groupId,
    GroupMemberRole? role,
    DateTime? joinedAt,
    String? invitedBy,
    String? nickname,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      user: user ?? this.user,
      groupId: groupId ?? this.groupId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      nickname: nickname ?? this.nickname,
    );
  }
  
  /// 解析群组成员角色
  static GroupMemberRole _parseGroupMemberRole(dynamic role) {
    if (role == null) return GroupMemberRole.member;
    
    if (role is GroupMemberRole) return role;
    
    if (role is String) {
      final String roleStr = role.toLowerCase();
      
      switch (roleStr) {
        case 'owner':
          return GroupMemberRole.owner;
        case 'admin':
          return GroupMemberRole.admin;
        case 'member':
        default:
          return GroupMemberRole.member;
      }
    }
    
    return GroupMemberRole.member;
  }
  
  /// 是否是群主
  bool get isOwner => role == GroupMemberRole.owner;
  
  /// 是否是管理员
  bool get isAdmin => role == GroupMemberRole.admin;
  
  /// 是否有管理权限（群主或管理员）
  bool get hasManagePermission => isOwner || isAdmin;
  
  @override
  String toString() {
    return 'GroupMember{userId: $userId, groupId: $groupId, role: $role}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GroupMember && other.userId == userId && other.groupId == groupId;
  }
  
  @override
  int get hashCode => userId.hashCode ^ groupId.hashCode;
  
  /// 创建一个空的群组成员实例
  factory GroupMember.empty() {
    return GroupMember(
      userId: '',
      groupId: '',
      role: GroupMemberRole.member,
      joinedAt: DateTime.now(),
    );
  }
}