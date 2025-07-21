import 'dart:io';

import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../models/group.dart';
import '../services/api_service.dart';

/// 群组仓库类，用于管理群组数据的存取
class GroupRepository {
  // 单例模式
  static final GroupRepository _instance = GroupRepository._internal();
  static GroupRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  GroupRepository._internal();
  
  /// 获取用户的群组列表
  Future<ApiResponse<List<Group>>> getUserGroups() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/groups');
      
      if (response.success && response.data != null) {
        final groups = response.data!.map((json) => Group.fromJson(json)).toList();
        // 保存到本地存储
        await _saveGroupsToLocal(groups);
        return ApiResponse<List<Group>>.success(groups);
      } else {
        return ApiResponse<List<Group>>.error(response.message ?? '获取群组列表失败');
      }
    } catch (e) {
      _logger.e('获取用户群组列表失败: $e');
      
      // 尝试从本地获取
      try {
        final localGroupsData = await LocalStorage.getGroups();
        if (localGroupsData.isNotEmpty) {
          final localGroups = localGroupsData
              .map((data) => Group.fromJson(Map<String, dynamic>.from(data)))
              .toList();
          return ApiResponse<List<Group>>.success(localGroups, message: '从本地存储获取的群组');
        }
      } catch (localError) {
        _logger.e('从本地获取群组失败: $localError');
      }
      
      return ApiResponse<List<Group>>.error('获取群组列表失败: $e');
    }
  }
  
  /// 获取群组详情
  Future<ApiResponse<Group>> getGroupById(String groupId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/groups/$groupId');
      
      if (response.success && response.data != null) {
        final group = Group.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveGroup(group);
        return ApiResponse<Group>.success(group);
      } else {
        return ApiResponse<Group>.error(response.message ?? '获取群组详情失败');
      }
    } catch (e) {
      _logger.e('获取群组详情失败: $e');
      
      // 尝试从本地获取
      try {
        final localGroupData = await LocalStorage.getGroup(groupId);
        if (localGroupData != null) {
          final localGroup = Group.fromJson(Map<String, dynamic>.from(localGroupData));
          return ApiResponse<Group>.success(localGroup, message: '从本地存储获取的群组');
        }
      } catch (localError) {
        _logger.e('从本地获取群组失败: $localError');
      }
      
      return ApiResponse<Group>.error('获取群组详情失败: $e');
    }
  }
  
  /// 创建群组
  Future<ApiResponse<Group>> createGroup({
    required String name,
    String? description,
    GroupType type = GroupType.private,
    List<String>? memberIds,
    File? avatarFile,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'type': type.toString().split('.').last,
      };
      
      if (description != null) data['description'] = description;
      if (memberIds != null && memberIds.isNotEmpty) data['member_ids'] = memberIds;
      
      // 如果有头像文件，先上传头像
      if (avatarFile != null) {
        final uploadResponse = await _apiService.uploadFile<Map<String, dynamic>>(
          '/upload/group-avatar',
          avatarFile,
        );
        
        if (uploadResponse.success && uploadResponse.data != null) {
          data['avatar_url'] = uploadResponse.data!['url'];
        } else {
          _logger.w('上传群组头像失败: ${uploadResponse.message}');
        }
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/groups',
        data: data,
      );
      
      if (response.success && response.data != null) {
        final group = Group.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveGroup(group);
        return ApiResponse<Group>.success(group);
      } else {
        return ApiResponse<Group>.error(response.message ?? '创建群组失败');
      }
    } catch (e) {
      _logger.e('创建群组失败: $e');
      return ApiResponse<Group>.error('创建群组失败: $e');
    }
  }
  
  /// 更新群组信息
  Future<ApiResponse<Group>> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? type,
    File? avatarFile,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (type != null) data['type'] = type.toString().split('.').last;
      
      // 如果有头像文件，先上传头像
      if (avatarFile != null) {
        final uploadResponse = await _apiService.uploadFile<Map<String, dynamic>>(
          '/upload/group-avatar',
          avatarFile,
        );
        
        if (uploadResponse.success && uploadResponse.data != null) {
          data['avatar_url'] = uploadResponse.data!['url'];
        } else {
          _logger.w('上传群组头像失败: ${uploadResponse.message}');
        }
      }
      
      final response = await _apiService.put<Map<String, dynamic>>(
        '/groups/$groupId',
        data: data,
      );
      
      if (response.success && response.data != null) {
        final group = Group.fromJson(response.data!);
        // 更新本地存储
        await LocalStorage.saveGroup(group);
        return ApiResponse<Group>.success(group);
      } else {
        return ApiResponse<Group>.error(response.message ?? '更新群组信息失败');
      }
    } catch (e) {
      _logger.e('更新群组信息失败: $e');
      return ApiResponse<Group>.error('更新群组信息失败: $e');
    }
  }
  
  /// 解散群组
  Future<ApiResponse<bool>> dissolveGroup(String groupId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/groups/$groupId',
      );
      
      if (response.success) {
        // 从本地存储中删除或标记为已解散
        await LocalStorage.markGroupAsDissolved(groupId);
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('解散群组失败: $e');
      return ApiResponse<bool>.error('解散群组失败: $e');
    }
  }
  
  /// 获取群组成员列表
  Future<ApiResponse<List<GroupMember>>> getGroupMembers(String groupId) async {
    try {
      final response = await _apiService.get<List<dynamic>>('/groups/$groupId/members');
      
      if (response.success && response.data != null) {
        final members = response.data!.map((json) => GroupMember.fromJson(json)).toList();
        return ApiResponse<List<GroupMember>>.success(members);
      } else {
        return ApiResponse<List<GroupMember>>.error(response.message ?? '获取群组成员列表失败');
      }
    } catch (e) {
      _logger.e('获取群组成员列表失败: $e');
      return ApiResponse<List<GroupMember>>.error('获取群组成员列表失败: $e');
    }
  }
  
  /// 邀请用户加入群组
  Future<ApiResponse<bool>> inviteUsersToGroup(String groupId, List<String> userIds) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/groups/$groupId/members',
        data: {'user_ids': userIds},
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('邀请用户加入群组失败: $e');
      return ApiResponse<bool>.error('邀请用户加入群组失败: $e');
    }
  }
  
  /// 移除群组成员
  Future<ApiResponse<bool>> removeGroupMember(String groupId, String userId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/groups/$groupId/members/$userId',
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('移除群组成员失败: $e');
      return ApiResponse<bool>.error('移除群组成员失败: $e');
    }
  }
  
  /// 更新群组成员角色
  Future<ApiResponse<bool>> updateMemberRole(String groupId, String userId, GroupMemberRole role) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/groups/$groupId/members/$userId',
        data: {'role': role.toString().split('.').last},
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('更新群组成员角色失败: $e');
      return ApiResponse<bool>.error('更新群组成员角色失败: $e');
    }
  }
  
  /// 退出群组
  Future<ApiResponse<bool>> leaveGroup(String groupId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/groups/$groupId/leave',
      );
      
      if (response.success) {
        // 从本地存储中删除或标记为已退出
        await LocalStorage.removeGroup(groupId);
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('退出群组失败: $e');
      return ApiResponse<bool>.error('退出群组失败: $e');
    }
  }
  
  /// 搜索群组
  Future<ApiResponse<List<Group>>> searchGroups(String keyword) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/groups/search',
        queryParameters: {'keyword': keyword},
      );
      
      if (response.success && response.data != null) {
        final groups = response.data!.map((json) => Group.fromJson(json)).toList();
        return ApiResponse<List<Group>>.success(groups);
      } else {
        return ApiResponse<List<Group>>.error(response.message ?? '搜索群组失败');
      }
    } catch (e) {
      _logger.e('搜索群组失败: $e');
      return ApiResponse<List<Group>>.error('搜索群组失败: $e');
    }
  }
  
  /// 将群组保存到本地存储
  Future<void> _saveGroupsToLocal(List<Group> groups) async {
    for (final group in groups) {
      await LocalStorage.saveGroup(group);
    }
  }
}