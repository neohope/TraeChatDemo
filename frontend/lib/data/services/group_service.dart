import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/models/group_model.dart';
import '../../core/utils/app_logger.dart';
import 'websocket_service.dart';
import 'local_storage.dart';

/// 群组服务
class GroupService {
  final Dio _dio;
  final WebSocketService _webSocketService;
  final AppLogger _logger;

  // 群组数据缓存
  final Map<String, Group> _groupsCache = {};
  final Map<String, List<GroupMember>> _membersCache = {};
  final Map<String, List<GroupInvitation>> _invitationsCache = {};

  // 流控制器
  final StreamController<Group> _groupUpdatedController = StreamController.broadcast();
  final StreamController<GroupMember> _memberUpdatedController = StreamController.broadcast();
  final StreamController<GroupInvitation> _invitationUpdatedController = StreamController.broadcast();
  final StreamController<String> _groupDeletedController = StreamController.broadcast();

  GroupService({
    Dio? dio,
    WebSocketService? webSocketService,
    LocalStorage? localStorage,
    AppLogger? logger,
  })  : _dio = dio ?? Dio(),
        _webSocketService = webSocketService ?? WebSocketService.instance,
        _logger = logger ?? AppLogger.instance {
    _setupWebSocketListeners();
  }

  // 流
  Stream<Group> get groupUpdatedStream => _groupUpdatedController.stream;
  Stream<GroupMember> get memberUpdatedStream => _memberUpdatedController.stream;
  Stream<GroupInvitation> get invitationUpdatedStream => _invitationUpdatedController.stream;
  Stream<String> get groupDeletedStream => _groupDeletedController.stream;

  /// 销毁服务
  void dispose() {
    _groupUpdatedController.close();
    _memberUpdatedController.close();
    _invitationUpdatedController.close();
    _groupDeletedController.close();
  }

  /// 创建群组
  Future<Group> createGroup({
    required String name,
    String? description,
    String? avatar,
    GroupType type = GroupType.normal,
    GroupSettings? settings,
    List<String>? initialMembers,
  }) async {
    try {
      final response = await _dio.post('/api/groups', data: {
        'name': name,
        'description': description,
        'avatar': avatar,
        'type': type.name,
        'settings': settings?.toJson() ?? const GroupSettings().toJson(),
        'initial_members': initialMembers ?? [],
      });

      final group = Group.fromJson(response.data['group']);
      _groupsCache[group.id] = group;
      _groupUpdatedController.add(group);

      _logger.info('创建群组成功: ${group.name}');
      return group;
    } catch (e) {
      _logger.error('创建群组失败: $e');
      rethrow;
    }
  }

  /// 获取群组列表
  Future<List<Group>> getGroups({
    int page = 1,
    int limit = 20,
    GroupType? type,
    GroupStatus? status,
  }) async {
    try {
      final response = await _dio.get('/api/groups', queryParameters: {
        'page': page,
        'limit': limit,
        if (type != null) 'type': type.name,
        if (status != null) 'status': status.name,
      });

      final groups = (response.data['groups'] as List)
          .map((json) => Group.fromJson(json))
          .toList();

      // 更新缓存
      for (final group in groups) {
        _groupsCache[group.id] = group;
      }

      _logger.info('获取群组列表成功: ${groups.length}个群组');
      return groups;
    } catch (e) {
      _logger.error('获取群组列表失败: $e');
      rethrow;
    }
  }

  /// 获取群组详情
  Future<Group> getGroup(String groupId) async {
    try {
      // 先从缓存获取
      if (_groupsCache.containsKey(groupId)) {
        return _groupsCache[groupId]!;
      }

      final response = await _dio.get('/api/groups/$groupId');
      final group = Group.fromJson(response.data['group']);
      
      _groupsCache[groupId] = group;
      _logger.info('获取群组详情成功: ${group.name}');
      return group;
    } catch (e) {
      _logger.error('获取群组详情失败: $e');
      rethrow;
    }
  }

  /// 更新群组信息
  Future<Group> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatar,
    GroupSettings? settings,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (avatar != null) data['avatar'] = avatar;
      if (settings != null) data['settings'] = settings.toJson();

      final response = await _dio.put('/api/groups/$groupId', data: data);
      final group = Group.fromJson(response.data['group']);
      
      _groupsCache[groupId] = group;
      _groupUpdatedController.add(group);
      
      _logger.info('更新群组信息成功: ${group.name}');
      return group;
    } catch (e) {
      _logger.error('更新群组信息失败: $e');
      rethrow;
    }
  }

  /// 解散群组
  Future<void> dissolveGroup(String groupId) async {
    try {
      await _dio.delete('/api/groups/$groupId');
      
      _groupsCache.remove(groupId);
      _membersCache.remove(groupId);
      _invitationsCache.remove(groupId);
      _groupDeletedController.add(groupId);
      
      _logger.info('解散群组成功: $groupId');
    } catch (e) {
      _logger.error('解散群组失败: $e');
      rethrow;
    }
  }

  /// 退出群组
  Future<void> leaveGroup(String groupId) async {
    try {
      await _dio.post('/api/groups/$groupId/leave');
      
      _groupsCache.remove(groupId);
      _membersCache.remove(groupId);
      _groupDeletedController.add(groupId);
      
      _logger.info('退出群组成功: $groupId');
    } catch (e) {
      _logger.error('退出群组失败: $e');
      rethrow;
    }
  }

  /// 获取群组成员列表
  Future<List<GroupMember>> getGroupMembers(
    String groupId, {
    int page = 1,
    int limit = 50,
    GroupMemberRole? role,
    GroupMemberStatus? status,
  }) async {
    try {
      final response = await _dio.get('/api/groups/$groupId/members', queryParameters: {
        'page': page,
        'limit': limit,
        if (role != null) 'role': role.name,
        if (status != null) 'status': status.name,
      });

      final members = (response.data['members'] as List)
          .map((json) => GroupMember.fromJson(json))
          .toList();

      // 更新缓存
      _membersCache[groupId] = members;

      _logger.info('获取群组成员列表成功: ${members.length}个成员');
      return members;
    } catch (e) {
      _logger.error('获取群组成员列表失败: $e');
      rethrow;
    }
  }

  /// 邀请用户加入群组
  Future<GroupInvitation> inviteToGroup(
    String groupId,
    String userId, {
    String? message,
  }) async {
    try {
      final response = await _dio.post('/api/groups/$groupId/invite', data: {
        'user_id': userId,
        'message': message,
      });

      final invitation = GroupInvitation.fromJson(response.data['invitation']);
      
      // 更新缓存
      if (_invitationsCache.containsKey(groupId)) {
        _invitationsCache[groupId]!.add(invitation);
      }
      
      _invitationUpdatedController.add(invitation);
      _logger.info('邀请用户加入群组成功: $userId');
      return invitation;
    } catch (e) {
      _logger.error('邀请用户加入群组失败: $e');
      rethrow;
    }
  }

  /// 处理群组邀请
  Future<void> respondToInvitation(
    String invitationId,
    bool accept, {
    String? message,
  }) async {
    try {
      await _dio.post('/api/group-invitations/$invitationId/respond', data: {
        'accept': accept,
        'message': message,
      });

      _logger.info('处理群组邀请成功: $invitationId, accept: $accept');
    } catch (e) {
      _logger.error('处理群组邀请失败: $e');
      rethrow;
    }
  }

  /// 移除群组成员
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _dio.delete('/api/groups/$groupId/members/$userId');
      
      // 更新缓存
      if (_membersCache.containsKey(groupId)) {
        _membersCache[groupId]!.removeWhere((member) => member.userId == userId);
      }
      
      _logger.info('移除群组成员成功: $userId');
    } catch (e) {
      _logger.error('移除群组成员失败: $e');
      rethrow;
    }
  }

  /// 设置成员角色
  Future<GroupMember> setMemberRole(
    String groupId,
    String userId,
    GroupMemberRole role,
  ) async {
    try {
      final response = await _dio.put('/api/groups/$groupId/members/$userId/role', data: {
        'role': role.name,
      });

      final member = GroupMember.fromJson(response.data['member']);
      
      // 更新缓存
      if (_membersCache.containsKey(groupId)) {
        final index = _membersCache[groupId]!.indexWhere((m) => m.userId == userId);
        if (index != -1) {
          _membersCache[groupId]![index] = member;
        }
      }
      
      _memberUpdatedController.add(member);
      _logger.info('设置成员角色成功: $userId -> ${role.name}');
      return member;
    } catch (e) {
      _logger.error('设置成员角色失败: $e');
      rethrow;
    }
  }

  /// 禁言成员
  Future<GroupMember> muteMember(
    String groupId,
    String userId, {
    Duration? duration,
  }) async {
    try {
      final response = await _dio.post('/api/groups/$groupId/members/$userId/mute', data: {
        if (duration != null) 'duration_seconds': duration.inSeconds,
      });

      final member = GroupMember.fromJson(response.data['member']);
      
      // 更新缓存
      if (_membersCache.containsKey(groupId)) {
        final index = _membersCache[groupId]!.indexWhere((m) => m.userId == userId);
        if (index != -1) {
          _membersCache[groupId]![index] = member;
        }
      }
      
      _memberUpdatedController.add(member);
      _logger.info('禁言成员成功: $userId');
      return member;
    } catch (e) {
      _logger.error('禁言成员失败: $e');
      rethrow;
    }
  }

  /// 解除禁言
  Future<GroupMember> unmuteMember(String groupId, String userId) async {
    try {
      final response = await _dio.post('/api/groups/$groupId/members/$userId/unmute');

      final member = GroupMember.fromJson(response.data['member']);
      
      // 更新缓存
      if (_membersCache.containsKey(groupId)) {
        final index = _membersCache[groupId]!.indexWhere((m) => m.userId == userId);
        if (index != -1) {
          _membersCache[groupId]![index] = member;
        }
      }
      
      _memberUpdatedController.add(member);
      _logger.info('解除禁言成功: $userId');
      return member;
    } catch (e) {
      _logger.error('解除禁言失败: $e');
      rethrow;
    }
  }

  /// 转让群主
  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    try {
      await _dio.post('/api/groups/$groupId/transfer-ownership', data: {
        'new_owner_id': newOwnerId,
      });
      
      // 清除缓存，强制重新获取
      _groupsCache.remove(groupId);
      _membersCache.remove(groupId);
      
      _logger.info('转让群主成功: $newOwnerId');
    } catch (e) {
      _logger.error('转让群主失败: $e');
      rethrow;
    }
  }

  /// 搜索群组
  Future<List<Group>> searchGroups(
    String query, {
    int page = 1,
    int limit = 20,
    GroupType? type,
  }) async {
    try {
      final response = await _dio.get('/api/groups/search', queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
        if (type != null) 'type': type.name,
      });

      final groups = (response.data['groups'] as List)
          .map((json) => Group.fromJson(json))
          .toList();

      _logger.info('搜索群组成功: ${groups.length}个结果');
      return groups;
    } catch (e) {
      _logger.error('搜索群组失败: $e');
      rethrow;
    }
  }

  /// 获取群组邀请列表
  Future<List<GroupInvitation>> getGroupInvitations(
    String groupId, {
    int page = 1,
    int limit = 20,
    GroupInvitationStatus? status,
  }) async {
    try {
      final response = await _dio.get('/api/groups/$groupId/invitations', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.name,
      });

      final invitations = (response.data['invitations'] as List)
          .map((json) => GroupInvitation.fromJson(json))
          .toList();

      // 更新缓存
      _invitationsCache[groupId] = invitations;

      _logger.info('获取群组邀请列表成功: ${invitations.length}个邀请');
      return invitations;
    } catch (e) {
      _logger.error('获取群组邀请列表失败: $e');
      rethrow;
    }
  }

  /// 获取我的群组邀请
  Future<List<GroupInvitation>> getMyInvitations({
    int page = 1,
    int limit = 20,
    GroupInvitationStatus? status,
  }) async {
    try {
      final response = await _dio.get('/api/my-group-invitations', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.name,
      });

      final invitations = (response.data['invitations'] as List)
          .map((json) => GroupInvitation.fromJson(json))
          .toList();

      _logger.info('获取我的群组邀请成功: ${invitations.length}个邀请');
      return invitations;
    } catch (e) {
      _logger.error('获取我的群组邀请失败: $e');
      rethrow;
    }
  }

  /// 获取收到的邀请
  Future<List<GroupInvitation>> getReceivedInvitations({
    int page = 1,
    int limit = 20,
    GroupInvitationStatus? status,
  }) async {
    try {
      final response = await _dio.get('/api/group-invitations/received', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.name,
      });

      final invitations = (response.data['invitations'] as List)
          .map((json) => GroupInvitation.fromJson(json))
          .toList();

      _logger.info('获取收到的邀请成功: ${invitations.length}个邀请');
      return invitations;
    } catch (e) {
      _logger.error('获取收到的邀请失败: $e');
      rethrow;
    }
  }

  /// 获取发出的邀请
  Future<List<GroupInvitation>> getSentInvitations(
    String groupId, {
    int page = 1,
    int limit = 20,
    GroupInvitationStatus? status,
  }) async {
    try {
      final response = await _dio.get('/api/groups/$groupId/invitations/sent', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.name,
      });

      final invitations = (response.data['invitations'] as List)
          .map((json) => GroupInvitation.fromJson(json))
          .toList();

      _logger.info('获取发出的邀请成功: ${invitations.length}个邀请');
      return invitations;
    } catch (e) {
      _logger.error('获取发出的邀请失败: $e');
      rethrow;
    }
  }

  /// 标记所有邀请为已读
  Future<void> markAllInvitationsAsRead() async {
    try {
      await _dio.post('/api/group-invitations/mark-all-read');
      _logger.info('标记所有邀请为已读成功');
    } catch (e) {
      _logger.error('标记所有邀请为已读失败: $e');
      rethrow;
    }
  }

  /// 从缓存获取群组
  Group? getCachedGroup(String groupId) {
    return _groupsCache[groupId];
  }

  /// 从缓存获取群组成员
  List<GroupMember>? getCachedMembers(String groupId) {
    return _membersCache[groupId];
  }

  /// 清除缓存
  void clearCache() {
    _groupsCache.clear();
    _membersCache.clear();
    _invitationsCache.clear();
    _logger.info('清除群组缓存');
  }

  /// 设置WebSocket监听器
  void _setupWebSocketListeners() {
    _webSocketService.messageStream.listen((message) {
      try {
        final data = jsonDecode(message.content);
        final type = data['type'] as String;

        switch (type) {
          case 'group_updated':
            final group = Group.fromJson(data['group']);
            _groupsCache[group.id] = group;
            _groupUpdatedController.add(group);
            break;

          case 'group_deleted':
            final groupId = data['group_id'] as String;
            _groupsCache.remove(groupId);
            _membersCache.remove(groupId);
            _invitationsCache.remove(groupId);
            _groupDeletedController.add(groupId);
            break;

          case 'group_member_updated':
            final member = GroupMember.fromJson(data['member']);
            if (_membersCache.containsKey(member.groupId)) {
              final index = _membersCache[member.groupId]!
                  .indexWhere((m) => m.userId == member.userId);
              if (index != -1) {
                _membersCache[member.groupId]![index] = member;
              } else {
                _membersCache[member.groupId]!.add(member);
              }
            }
            _memberUpdatedController.add(member);
            break;

          case 'group_invitation_updated':
            final invitation = GroupInvitation.fromJson(data['invitation']);
            if (_invitationsCache.containsKey(invitation.groupId)) {
              final index = _invitationsCache[invitation.groupId]!
                  .indexWhere((i) => i.id == invitation.id);
              if (index != -1) {
                _invitationsCache[invitation.groupId]![index] = invitation;
              } else {
                _invitationsCache[invitation.groupId]!.add(invitation);
              }
            }
            _invitationUpdatedController.add(invitation);
            break;
        }
      } catch (e) {
        _logger.error('处理群组WebSocket消息失败: $e');
      }
    });
  }
}