import 'dart:convert';

import 'user.dart';
import '../../core/utils/app_logger.dart';

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
    final logger = AppLogger.instance.logger;
    try {
      logger.d('🔍 Group.fromJson - 开始解析JSON: $json');
      
      // 解析ID
      final id = json['id']?.toString() ?? '';
      logger.d('🔍 Group.fromJson - ID解析完成: $id');
      
      // 解析名称
      final name = json['name']?.toString() ?? '';
      logger.d('🔍 Group.fromJson - 名称解析完成: $name');
      
      // 解析描述
      final description = json['description']?.toString();
      logger.d('🔍 Group.fromJson - 描述解析完成: $description');
      
      // 解析头像URL
      final avatarUrl = json['avatar_url']?.toString() ?? json['avatarUrl']?.toString();
      logger.d('🔍 Group.fromJson - 头像URL解析完成: $avatarUrl');
      
      // 解析创建者ID
      final creatorId = json['owner_id']?.toString() ?? json['creator_id']?.toString() ?? json['creatorId']?.toString() ?? '';
      logger.d('🔍 Group.fromJson - 创建者ID解析完成: $creatorId');
      
      // 解析群组类型
      final isPrivate = json['is_private'];
      logger.d('🔍 Group.fromJson - is_private原始值: $isPrivate (${isPrivate.runtimeType})');
      final type = _parseGroupType(isPrivate == true ? 'private' : 'public');
      logger.d('🔍 Group.fromJson - 群组类型解析完成: $type');
      
      // 解析成员数量
      final memberCountRaw = json['member_count'] ?? json['memberCount'];
      logger.d('🔍 Group.fromJson - member_count原始值: $memberCountRaw (${memberCountRaw.runtimeType})');
      final memberCount = _parseInt(memberCountRaw) ?? 0;
      logger.d('🔍 Group.fromJson - 成员数量解析完成: $memberCount');
      
      // 解析最大成员数量
      final maxMemberCountRaw = json['max_members'] ?? json['max_member_count'] ?? json['maxMemberCount'];
      logger.d('🔍 Group.fromJson - max_member_count原始值: $maxMemberCountRaw (${maxMemberCountRaw.runtimeType})');
      final maxMemberCount = _parseInt(maxMemberCountRaw) ?? 200;
      logger.d('🔍 Group.fromJson - 最大成员数量解析完成: $maxMemberCount');
      
      // 解析创建时间
      final createdAtRaw = json['created_at'] ?? json['createdAt'];
      logger.d('🔍 Group.fromJson - created_at原始值: $createdAtRaw (${createdAtRaw.runtimeType})');
      final createdAt = createdAtRaw != null
          ? DateTime.parse(createdAtRaw)
          : DateTime.now();
      logger.d('🔍 Group.fromJson - 创建时间解析完成: $createdAt');
      
      // 解析更新时间
      final updatedAtRaw = json['updated_at'] ?? json['updatedAt'];
      logger.d('🔍 Group.fromJson - updated_at原始值: $updatedAtRaw (${updatedAtRaw.runtimeType})');
      final updatedAt = updatedAtRaw != null ? DateTime.parse(updatedAtRaw) : null;
      logger.d('🔍 Group.fromJson - 更新时间解析完成: $updatedAt');
      
      // 解析是否解散
      final isDissolvedRaw = json['is_dissolved'] ?? json['isDissolved'];
      logger.d('🔍 Group.fromJson - is_dissolved原始值: $isDissolvedRaw (${isDissolvedRaw.runtimeType})');
      final isDissolved = _parseBool(isDissolvedRaw) ?? false;
      logger.d('🔍 Group.fromJson - 是否解散解析完成: $isDissolved');
      
      // 解析成员列表
      final membersRaw = json['members'];
      logger.d('🔍 Group.fromJson - members原始值: $membersRaw (${membersRaw.runtimeType})');
      List<GroupMember>? members;
      if (membersRaw != null && membersRaw is List) {
        logger.d('🔍 Group.fromJson - 开始解析成员列表，数量: ${membersRaw.length}');
        members = membersRaw.map((m) {
          logger.d('🔍 Group.fromJson - 解析单个成员: $m');
          return GroupMember.fromJson(m);
        }).toList();
        logger.d('🔍 Group.fromJson - 成员列表解析完成，数量: ${members.length}');
      } else {
        logger.d('🔍 Group.fromJson - 成员列表为空或非List类型');
      }
      
      // 解析自定义数据
      final customDataRaw = json['custom_data'] ?? json['customData'];
      logger.d('🔍 Group.fromJson - custom_data原始值: $customDataRaw (${customDataRaw.runtimeType})');
      final customData = _parseCustomData(customDataRaw);
      logger.d('🔍 Group.fromJson - 自定义数据解析完成: $customData');
      
      logger.d('🔍 Group.fromJson - 开始创建Group对象');
      final group = Group(
        id: id,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        creatorId: creatorId,
        type: type,
        memberCount: memberCount,
        maxMemberCount: maxMemberCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isDissolved: isDissolved,
        members: members,
        customData: customData,
      );
      logger.d('🔍 Group.fromJson - Group对象创建成功: ${group.toString()}');
      return group;
    } catch (e, stackTrace) {
      logger.e('❌ Group.fromJson解析失败: $e');
      logger.e('❌ 错误堆栈: $stackTrace');
      logger.e('❌ JSON数据: $json');
      rethrow;
    }
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
  
  /// 安全解析整数
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // 处理字符串中可能包含数字的情况
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      // 尝试提取字符串中的数字部分
      final numericString = RegExp(r'\d+').stringMatch(value);
      if (numericString != null) {
        return int.tryParse(numericString);
      }
    }
    return null;
  }

  /// 安全解析自定义数据
  static Map<String, dynamic>? _parseCustomData(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    // 如果是其他类型，返回null而不是抛出错误
    return null;
  }

  /// 安全解析布尔值
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true' || lowerValue == '1') return true;
      if (lowerValue == 'false' || lowerValue == '0') return false;
    }
    return null;
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
    final logger = AppLogger.instance.logger;
    try {
      logger.d('🔍 GroupMember.fromJson - 开始解析JSON: $json');
      
      // 解析用户ID
      final userId = json['user_id'] ?? json['userId'];
      logger.d('🔍 GroupMember.fromJson - 用户ID解析完成: $userId');
      
      // 解析用户信息
      final userRaw = json['user'];
      logger.d('🔍 GroupMember.fromJson - user原始值: $userRaw (${userRaw.runtimeType})');
      User? user;
      if (userRaw != null) {
        user = User.fromJson(userRaw);
        logger.d('🔍 GroupMember.fromJson - 用户信息解析完成: ${user.toString()}');
      } else {
        logger.d('🔍 GroupMember.fromJson - 用户信息为空');
      }
      
      // 解析群组ID
      final groupId = json['group_id'] ?? json['groupId'];
      logger.d('🔍 GroupMember.fromJson - 群组ID解析完成: $groupId');
      
      // 解析角色
      final roleRaw = json['role'];
      logger.d('🔍 GroupMember.fromJson - role原始值: $roleRaw (${roleRaw.runtimeType})');
      final role = _parseGroupMemberRole(roleRaw);
      logger.d('🔍 GroupMember.fromJson - 角色解析完成: $role');
      
      // 解析加入时间
      final joinedAtRaw = json['joined_at'] ?? json['joinedAt'];
      logger.d('🔍 GroupMember.fromJson - joined_at原始值: $joinedAtRaw (${joinedAtRaw.runtimeType})');
      final joinedAt = joinedAtRaw != null
          ? DateTime.parse(joinedAtRaw)
          : DateTime.now();
      logger.d('🔍 GroupMember.fromJson - 加入时间解析完成: $joinedAt');
      
      // 解析邀请者
      final invitedBy = json['invited_by'] ?? json['invitedBy'];
      logger.d('🔍 GroupMember.fromJson - 邀请者解析完成: $invitedBy');
      
      // 解析昵称
      final nickname = json['nickname'];
      logger.d('🔍 GroupMember.fromJson - 昵称解析完成: $nickname');
      
      logger.d('🔍 GroupMember.fromJson - 开始创建GroupMember对象');
      final member = GroupMember(
        userId: userId,
        user: user,
        groupId: groupId,
        role: role,
        joinedAt: joinedAt,
        invitedBy: invitedBy,
        nickname: nickname,
      );
      logger.d('🔍 GroupMember.fromJson - GroupMember对象创建成功: ${member.toString()}');
      return member;
    } catch (e, stackTrace) {
      logger.e('❌ GroupMember.fromJson解析失败: $e');
      logger.e('❌ 错误堆栈: $stackTrace');
      logger.e('❌ JSON数据: $json');
      rethrow;
    }
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