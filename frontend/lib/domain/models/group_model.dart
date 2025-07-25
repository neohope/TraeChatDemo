import 'package:flutter/foundation.dart';

/// 群组类型
enum GroupType {
  normal, // 普通群组
  broadcast, // 广播群组
  channel, // 频道
}

/// 群组成员角色
enum GroupMemberRole {
  owner, // 群主
  admin, // 管理员
  member, // 普通成员
}

/// 群组成员状态
enum GroupMemberStatus {
  active, // 活跃
  muted, // 被禁言
  banned, // 被踢出
  left, // 已退出
}

/// 群组状态
enum GroupStatus {
  active, // 活跃
  archived, // 已归档
  dissolved, // 已解散
}

/// 群组成员模型
class GroupMember {
  final String id;
  final String userId;
  final String groupId;
  final String nickname;
  final String? avatar;
  final GroupMemberRole role;
  final GroupMemberStatus status;
  final DateTime joinedAt;
  final DateTime? mutedUntil;
  final Map<String, dynamic> customData;

  const GroupMember({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.nickname,
    this.avatar,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.mutedUntil,
    this.customData = const {},
  });

  /// 从JSON创建实例
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      role: GroupMemberRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => GroupMemberRole.member,
      ),
      status: GroupMemberStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GroupMemberStatus.active,
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      mutedUntil: json['muted_until'] != null
          ? DateTime.parse(json['muted_until'] as String)
          : null,
      customData: Map<String, dynamic>.from(json['custom_data'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'nickname': nickname,
      'avatar': avatar,
      'role': role.name,
      'status': status.name,
      'joined_at': joinedAt.toIso8601String(),
      'muted_until': mutedUntil?.toIso8601String(),
      'custom_data': customData,
    };
  }

  /// 复制并修改
  GroupMember copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? nickname,
    String? avatar,
    GroupMemberRole? role,
    GroupMemberStatus? status,
    DateTime? joinedAt,
    DateTime? mutedUntil,
    Map<String, dynamic>? customData,
  }) {
    return GroupMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      customData: customData ?? this.customData,
    );
  }

  /// 是否是群主
  bool get isOwner => role == GroupMemberRole.owner;

  /// 是否是管理员
  bool get isAdmin => role == GroupMemberRole.admin;

  /// 是否有管理权限
  bool get hasAdminPermission => isOwner || isAdmin;

  /// 是否被禁言
  bool get isMuted {
    if (status == GroupMemberStatus.muted) return true;
    if (mutedUntil != null && mutedUntil!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  /// 是否活跃
  bool get isActive => status == GroupMemberStatus.active;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupMember(id: $id, userId: $userId, nickname: $nickname, role: $role)';
  }
}

/// 群组设置模型
class GroupSettings {
  final bool allowMemberInvite; // 允许成员邀请
  final bool allowMemberModifyInfo; // 允许成员修改群信息
  final bool muteAll; // 全员禁言
  final bool requireApprovalToJoin; // 加群需要审批
  final bool allowSearchByGroupId; // 允许通过群号搜索
  final int maxMembers; // 最大成员数
  final Map<String, dynamic> customSettings; // 自定义设置

  const GroupSettings({
    this.allowMemberInvite = true,
    this.allowMemberModifyInfo = false,
    this.muteAll = false,
    this.requireApprovalToJoin = false,
    this.allowSearchByGroupId = true,
    this.maxMembers = 500,
    this.customSettings = const {},
  });

  /// 从JSON创建实例
  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      allowMemberInvite: json['allow_member_invite'] as bool? ?? true,
      allowMemberModifyInfo: json['allow_member_modify_info'] as bool? ?? false,
      muteAll: json['mute_all'] as bool? ?? false,
      requireApprovalToJoin: json['require_approval_to_join'] as bool? ?? false,
      allowSearchByGroupId: json['allow_search_by_group_id'] as bool? ?? true,
      maxMembers: json['max_members'] as int? ?? 500,
      customSettings: Map<String, dynamic>.from(json['custom_settings'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'allow_member_invite': allowMemberInvite,
      'allow_member_modify_info': allowMemberModifyInfo,
      'mute_all': muteAll,
      'require_approval_to_join': requireApprovalToJoin,
      'allow_search_by_group_id': allowSearchByGroupId,
      'max_members': maxMembers,
      'custom_settings': customSettings,
    };
  }

  /// 复制并修改
  GroupSettings copyWith({
    bool? allowMemberInvite,
    bool? allowMemberModifyInfo,
    bool? muteAll,
    bool? requireApprovalToJoin,
    bool? allowSearchByGroupId,
    int? maxMembers,
    Map<String, dynamic>? customSettings,
  }) {
    return GroupSettings(
      allowMemberInvite: allowMemberInvite ?? this.allowMemberInvite,
      allowMemberModifyInfo: allowMemberModifyInfo ?? this.allowMemberModifyInfo,
      muteAll: muteAll ?? this.muteAll,
      requireApprovalToJoin: requireApprovalToJoin ?? this.requireApprovalToJoin,
      allowSearchByGroupId: allowSearchByGroupId ?? this.allowSearchByGroupId,
      maxMembers: maxMembers ?? this.maxMembers,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupSettings &&
        other.allowMemberInvite == allowMemberInvite &&
        other.allowMemberModifyInfo == allowMemberModifyInfo &&
        other.muteAll == muteAll &&
        other.requireApprovalToJoin == requireApprovalToJoin &&
        other.allowSearchByGroupId == allowSearchByGroupId &&
        other.maxMembers == maxMembers &&
        mapEquals(other.customSettings, customSettings);
  }

  @override
  int get hashCode {
    return Object.hash(
      allowMemberInvite,
      allowMemberModifyInfo,
      muteAll,
      requireApprovalToJoin,
      allowSearchByGroupId,
      maxMembers,
      customSettings,
    );
  }

  @override
  String toString() {
    return 'GroupSettings(allowMemberInvite: $allowMemberInvite, muteAll: $muteAll)';
  }
}

/// 群组模型
class Group {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String ownerId;
  final GroupType type;
  final GroupStatus status;
  final GroupSettings settings;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> customData;

  const Group({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.ownerId,
    required this.type,
    required this.status,
    required this.settings,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
    this.customData = const {},
  });

  /// 从JSON创建实例
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatar: json['avatar'] as String?,
      ownerId: json['owner_id'] as String,
      type: GroupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GroupType.normal,
      ),
      status: GroupStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GroupStatus.active,
      ),
      settings: GroupSettings.fromJson(json['settings'] ?? {}),
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customData: Map<String, dynamic>.from(json['custom_data'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'owner_id': ownerId,
      'type': type.name,
      'status': status.name,
      'settings': settings.toJson(),
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'custom_data': customData,
    };
  }

  /// 复制并修改
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    String? ownerId,
    GroupType? type,
    GroupStatus? status,
    GroupSettings? settings,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customData,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customData: customData ?? this.customData,
    );
  }

  /// 是否是普通群组
  bool get isNormalGroup => type == GroupType.normal;

  /// 是否是广播群组
  bool get isBroadcastGroup => type == GroupType.broadcast;

  /// 是否是频道
  bool get isChannel => type == GroupType.channel;

  /// 是否活跃
  bool get isActive => status == GroupStatus.active;

  /// 是否已归档
  bool get isArchived => status == GroupStatus.archived;

  /// 是否已解散
  bool get isDissolved => status == GroupStatus.dissolved;

  /// 是否已满员
  bool get isFull => memberCount >= settings.maxMembers;

  /// 获取群组显示名称
  String get displayName {
    if (name.isNotEmpty) return name;
    return 'Group $id';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Group(id: $id, name: $name, memberCount: $memberCount, status: $status)';
  }
}

/// 群组邀请模型
class GroupInvitation {
  final String id;
  final String groupId;
  final String inviterId;
  final String inviteeId;
  final String? message;
  final GroupInvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final bool isRead;
  final Map<String, dynamic> customData;

  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeId,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.isRead = false,
    this.customData = const {},
  });

  /// 从JSON创建实例
  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      message: json['message'] as String?,
      status: GroupInvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GroupInvitationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      customData: Map<String, dynamic>.from(json['custom_data'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'message': message,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'is_read': isRead,
      'custom_data': customData,
    };
  }

  /// 复制并修改
  GroupInvitation copyWith({
    String? id,
    String? groupId,
    String? inviterId,
    String? inviteeId,
    String? message,
    GroupInvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    bool? isRead,
    Map<String, dynamic>? customData,
  }) {
    return GroupInvitation(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      isRead: isRead ?? this.isRead,
      customData: customData ?? this.customData,
    );
  }

  /// 是否待处理
  bool get isPending => status == GroupInvitationStatus.pending;

  /// 是否已接受
  bool get isAccepted => status == GroupInvitationStatus.accepted;

  /// 是否已拒绝
  bool get isRejected => status == GroupInvitationStatus.rejected;

  /// 是否已过期
  bool get isExpired => status == GroupInvitationStatus.expired;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupInvitation(id: $id, groupId: $groupId, status: $status)';
  }
}

/// 群组邀请状态
enum GroupInvitationStatus {
  pending, // 待处理
  accepted, // 已接受
  rejected, // 已拒绝
  expired, // 已过期
}