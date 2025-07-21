import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/models/api_response.dart';
import '../../data/models/group.dart';
import '../../data/repositories/group_repository.dart';

/// 群组视图模型，用于管理群组相关的UI状态和业务逻辑
class GroupViewModel extends ChangeNotifier {
  // 群组仓库实例
  final _groupRepository = GroupRepository.instance;
  
  // 用户的群组列表
  List<Group> _groups = [];
  // 当前选中的群组
  Group? _selectedGroup;
  // 当前群组的成员列表
  List<GroupMember> _groupMembers = [];
  // 搜索结果
  List<Group> _searchResults = [];
  
  // 加载状态
  bool _isLoading = false;
  // 是否正在创建群组
  bool _isCreating = false;
  // 是否正在更新群组
  bool _isUpdating = false;
  // 错误信息
  String? _errorMessage;
  
  /// 获取用户的群组列表
  List<Group> get groups => _groups;
  
  /// 获取当前选中的群组
  Group? get selectedGroup => _selectedGroup;
  
  /// 获取当前群组的成员列表
  List<GroupMember> get groupMembers => _groupMembers;
  
  /// 获取搜索结果
  List<Group> get searchResults => _searchResults;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 是否正在创建群组
  bool get isCreating => _isCreating;
  
  /// 是否正在更新群组
  bool get isUpdating => _isUpdating;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 构造函数
  GroupViewModel() {
    // 初始化加载群组列表
    loadGroups();
  }
  
  /// 加载用户的群组列表
  Future<void> loadGroups() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.getUserGroups();
      
      if (response.success && response.data != null) {
        _groups = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载群组列表失败');
      }
    } catch (e) {
      _setError('加载群组列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 获取群组详情
  Future<ApiResponse<Group>> getGroupDetail(String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.getGroupById(groupId);
      
      if (response.success && response.data != null) {
        // 更新本地群组列表
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = response.data!;
        } else {
          _groups.add(response.data!);
        }
        
        // 如果是当前选中的群组，更新选中的群组
        if (_selectedGroup?.id == groupId) {
          _selectedGroup = response.data!;
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '获取群组详情失败');
      }
      
      return response;
    } catch (e) {
      _setError('获取群组详情失败: $e');
      return ApiResponse<Group>.error('获取群组详情失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 创建群组
  Future<ApiResponse<Group>> createGroup({
    required String name,
    String? description,
    File? avatarFile,
    List<String>? memberIds,
  }) async {
    _setCreating(true);
    _clearError();
    
    try {
      final response = await _groupRepository.createGroup(
        name: name,
        description: description,
        avatarFile: avatarFile,
        memberIds: memberIds,
      );
      
      if (response.success && response.data != null) {
        // 添加到本地群组列表
        _groups.add(response.data!);
        notifyListeners();
      } else {
        _setError(response.message ?? '创建群组失败');
      }
      
      return response;
    } catch (e) {
      _setError('创建群组失败: $e');
      return ApiResponse<Group>.error('创建群组失败: $e');
    } finally {
      _setCreating(false);
    }
  }
  
  /// 更新群组信息
  Future<ApiResponse<Group>> updateGroup({
    required String groupId,
    String? name,
    String? description,
    File? avatarFile,
  }) async {
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _groupRepository.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        avatarFile: avatarFile,
      );
      
      if (response.success && response.data != null) {
        // 更新本地群组
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = response.data!;
        }
        
        // 如果是当前选中的群组，更新选中的群组
        if (_selectedGroup?.id == groupId) {
          _selectedGroup = response.data!;
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '更新群组信息失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新群组信息失败: $e');
      return ApiResponse<Group>.error('更新群组信息失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 解散群组
  Future<ApiResponse<bool>> dissolveGroup(String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.dissolveGroup(groupId);
      
      if (response.success) {
        // 从本地列表中删除
        _groups.removeWhere((g) => g.id == groupId);
        
        // 如果是当前选中的群组，清除选中状态
        if (_selectedGroup?.id == groupId) {
          _selectedGroup = null;
          _groupMembers = [];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '解散群组失败');
      }
      
      return response;
    } catch (e) {
      _setError('解散群组失败: $e');
      return ApiResponse<bool>.error('解散群组失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 选择群组
  void selectGroup(Group group) {
    _selectedGroup = group;
    notifyListeners();
    
    // 加载群组成员
    loadGroupMembers(group.id);
  }
  
  /// 加载群组成员列表
  Future<void> loadGroupMembers(String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.getGroupMembers(groupId);
      
      if (response.success && response.data != null) {
        _groupMembers = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载群组成员失败');
      }
    } catch (e) {
      _setError('加载群组成员失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 邀请用户加入群组
  Future<ApiResponse<bool>> inviteToGroup(String groupId, List<String> userIds) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.inviteUsersToGroup(groupId, userIds);
      
      if (response.success) {
        // 重新加载群组成员
        await loadGroupMembers(groupId);
        
        // 更新群组信息中的成员数量
        await getGroupDetail(groupId);
      } else {
        _setError(response.message ?? '邀请用户加入群组失败');
      }
      
      return response;
    } catch (e) {
      _setError('邀请用户加入群组失败: $e');
      return ApiResponse<bool>.error('邀请用户加入群组失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 移除群组成员
  Future<ApiResponse<bool>> removeFromGroup(String groupId, String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.removeGroupMember(groupId, userId);
      
      if (response.success) {
        // 从本地成员列表中删除
        _groupMembers.removeWhere((m) => m.userId == userId);
        
        // 更新群组信息中的成员数量
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = _groups[index].copyWith(
            memberCount: _groups[index].memberCount - 1,
          );
          
          // 如果是当前选中的群组，更新选中的群组
          if (_selectedGroup?.id == groupId) {
            _selectedGroup = _groups[index];
          }
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '移除群组成员失败');
      }
      
      return response;
    } catch (e) {
      _setError('移除群组成员失败: $e');
      return ApiResponse<bool>.error('移除群组成员失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更新群组成员角色
  Future<ApiResponse<bool>> updateMemberRole(String groupId, String userId, GroupMemberRole role) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.updateMemberRole(groupId, userId, role);
      
      if (response.success) {
        // 更新本地成员角色
        final index = _groupMembers.indexWhere((m) => m.userId == userId);
        if (index != -1) {
          _groupMembers[index] = _groupMembers[index].copyWith(role: role);
          notifyListeners();
        }
      } else {
        _setError(response.message ?? '更新成员角色失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新成员角色失败: $e');
      return ApiResponse<bool>.error('更新成员角色失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 退出群组
  Future<ApiResponse<bool>> leaveGroup(String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.leaveGroup(groupId);
      
      if (response.success) {
        // 从本地列表中删除
        _groups.removeWhere((g) => g.id == groupId);
        
        // 如果是当前选中的群组，清除选中状态
        if (_selectedGroup?.id == groupId) {
          _selectedGroup = null;
          _groupMembers = [];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '退出群组失败');
      }
      
      return response;
    } catch (e) {
      _setError('退出群组失败: $e');
      return ApiResponse<bool>.error('退出群组失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 搜索群组
  Future<void> searchGroups(String keyword) async {
    if (keyword.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _groupRepository.searchGroups(keyword);
      
      if (response.success && response.data != null) {
        _searchResults = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '搜索群组失败');
      }
    } catch (e) {
      _setError('搜索群组失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 清除搜索结果
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
  
  /// 检查用户是否是群组成员
  bool isGroupMember(String userId) {
    return _groupMembers.any((member) => member.userId == userId);
  }
  
  /// 检查用户是否是群组管理员
  bool isGroupAdmin(String userId) {
    final member = _groupMembers.firstWhere(
      (member) => member.userId == userId,
      orElse: () => GroupMember.empty(),
    );
    return member.role == GroupMemberRole.admin || member.role == GroupMemberRole.owner;
  }
  
  /// 检查用户是否是群组所有者
  bool isGroupOwner(String userId) {
    final member = _groupMembers.firstWhere(
      (member) => member.userId == userId,
      orElse: () => GroupMember.empty(),
    );
    return member.role == GroupMemberRole.owner;
  }
  
  /// 获取群组成员信息
  GroupMember? getGroupMember(String userId) {
    try {
      return _groupMembers.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置创建状态
  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }
  
  /// 设置更新状态
  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}