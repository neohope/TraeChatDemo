import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/group_model.dart';
import '../../domain/services/auth_service.dart';
import '../../data/services/auth_service_impl.dart';
import '../../data/services/group_service.dart';
import '../../data/services/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/services/api_service.dart';

/// 群组ViewModel
class GroupViewModel extends ChangeNotifier {
  final GroupService _groupService;
  final AppLogger _logger;

  GroupViewModel({
    GroupService? groupService,
    LocalStorage? localStorage,
    AppLogger? logger,
    AuthService? authService,
  })  : _groupService = groupService ?? GroupService(
          dio: ApiService.instance.dio,
          authService: authService ?? AuthServiceImpl.instance,
        ),
        _logger = logger ?? AppLogger.instance;

  // 状态管理
  bool _isLoading = false;
  String? _error;
  
  // 群组数据
  List<Group> _groups = [];
  Group? _currentGroup;
  List<GroupMember> _currentMembers = [];
  List<GroupInvitation> _pendingInvitations = [];
  List<GroupInvitation> _myInvitations = [];
  List<GroupInvitation> _receivedInvitations = [];
  List<GroupInvitation> _sentInvitations = [];
  
  // 搜索和过滤
  String _searchQuery = '';
  GroupType? _filterType;
  GroupStatus? _filterStatus;
  
  // 分页
  int _currentPage = 1;
  bool _hasMoreData = true;
  
  // 订阅
  StreamSubscription? _groupUpdatedSubscription;
  StreamSubscription? _memberUpdatedSubscription;
  StreamSubscription? _invitationUpdatedSubscription;
  StreamSubscription? _groupDeletedSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;
  List<GroupMember> get currentMembers => _currentMembers;
  List<GroupInvitation> get pendingInvitations => _pendingInvitations;
  List<GroupInvitation> get myInvitations => _myInvitations;
  List<GroupInvitation> get receivedInvitations => _receivedInvitations;
  List<GroupInvitation> get sentInvitations => _sentInvitations;
  String get searchQuery => _searchQuery;
  GroupType? get filterType => _filterType;
  GroupStatus? get filterStatus => _filterStatus;
  bool get hasMoreData => _hasMoreData;
  
  // 计算属性
  List<Group> get filteredGroups {
    var filtered = _groups.where((group) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!group.name.toLowerCase().contains(query) &&
            !(group.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      // 类型过滤
      if (_filterType != null && group.type != _filterType) {
        return false;
      }
      
      // 状态过滤
      if (_filterStatus != null && group.status != _filterStatus) {
        return false;
      }
      
      return true;
    }).toList();
    
    // 按更新时间排序
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }
  
  List<GroupMember> get activeMembers {
    return _currentMembers.where((member) => member.isActive).toList();
  }
  
  List<GroupMember> get adminMembers {
    return _currentMembers.where((member) => member.hasAdminPermission).toList();
  }
  
  int get pendingInvitationCount {
    return _myInvitations.where((inv) => inv.isPending).length;
  }

  /// 初始化
  Future<void> initialize() async {
    try {
      _setupSubscriptions();
      await loadGroups();
      await loadMyInvitations();
      _logger.info('群组ViewModel初始化完成');
    } catch (e) {
      _logger.error('群组ViewModel初始化失败: $e');
      _setError('初始化失败: $e');
    }
  }

  /// 销毁
  @override
  void dispose() {
    _groupUpdatedSubscription?.cancel();
    _memberUpdatedSubscription?.cancel();
    _invitationUpdatedSubscription?.cancel();
    _groupDeletedSubscription?.cancel();
    _groupService.dispose();
    super.dispose();
  }

  /// 加载群组列表
  Future<void> loadGroups({
    bool refresh = false,
    int? page,
  }) async {
    if (_isLoading && !refresh) return;
    
    try {
      print('🔍 GroupViewModel.loadGroups - 开始加载群组列表，refresh: $refresh, page: $page');
      _setLoading(true);
      _clearError();
      
      final targetPage = page ?? (refresh ? 1 : _currentPage);
      print('🔍 GroupViewModel.loadGroups - 目标页码: $targetPage');
      
      print('🔍 GroupViewModel.loadGroups - 调用GroupService.getGroups');
      final groups = await _groupService.getGroups(
        page: targetPage,
        type: _filterType,
        status: _filterStatus,
      );
      
      print('🔍 GroupViewModel.loadGroups - GroupService返回${groups.length}个群组');
      
      if (refresh || targetPage == 1) {
        _groups = groups;
        _currentPage = 1;
        print('🔍 GroupViewModel.loadGroups - 刷新模式，重置群组列表');
      } else {
        _groups.addAll(groups);
        print('🔍 GroupViewModel.loadGroups - 追加模式，当前总数: ${_groups.length}');
      }
      
      _hasMoreData = groups.length >= 20; // 假设每页20条
      _currentPage = targetPage;
      
      print('🔍 GroupViewModel.loadGroups - 更新分页信息，当前页: $_currentPage，是否有更多: $_hasMoreData');
      notifyListeners();
      _logger.info('加载群组列表成功: ${groups.length}个群组');
    } catch (e, stackTrace) {
      print('❌ GroupViewModel.loadGroups - 异常: $e');
      print('❌ 错误堆栈: $stackTrace');
      _logger.error('加载群组列表失败: $e');
      _setError('加载群组列表失败: $e');
    } finally {
      _setLoading(false);
      print('🔍 GroupViewModel.loadGroups - 加载完成，通知监听器');
    }
  }

  /// 加载更多群组
  Future<void> loadMoreGroups() async {
    if (!_hasMoreData || _isLoading) return;
    await loadGroups(page: _currentPage + 1);
  }

  /// 刷新群组列表
  Future<void> refreshGroups() async {
    await loadGroups(refresh: true);
  }

  /// 创建群组
  Future<Group?> createGroup({
    required String name,
    String? description,
    String? avatar,
    GroupType type = GroupType.normal,
    GroupSettings? settings,
    List<String>? initialMembers,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        avatar: avatar,
        type: type,
        settings: settings,
        initialMembers: initialMembers,
      );
      
      _groups.insert(0, group);
      notifyListeners();
      
      _logger.info('创建群组成功: ${group.name}');
      return group;
    } catch (e) {
      _logger.error('创建群组失败: $e');
      _setError('创建群组失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 选择群组
  Future<void> selectGroup(String groupId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final group = await _groupService.getGroup(groupId);
      _currentGroup = group;
      
      // 加载群组成员
      await loadGroupMembers(groupId);
      
      // 加载待处理邀请
      await loadGroupInvitations(groupId);
      
      notifyListeners();
      _logger.info('选择群组成功: ${group.name}');
    } catch (e) {
      _logger.error('选择群组失败: $e');
      _setError('选择群组失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 更新群组信息
  Future<bool> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatar,
    GroupSettings? settings,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updatedGroup = await _groupService.updateGroup(
        groupId,
        name: name,
        description: description,
        avatar: avatar,
        settings: settings,
      );
      
      // 更新列表中的群组
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
      }
      
      // 更新当前群组
      if (_currentGroup?.id == groupId) {
        _currentGroup = updatedGroup;
      }
      
      notifyListeners();
      _logger.info('更新群组信息成功: ${updatedGroup.name}');
      return true;
    } catch (e) {
      _logger.error('更新群组信息失败: $e');
      _setError('更新群组信息失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 解散群组
  Future<bool> dissolveGroup(String groupId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _groupService.dissolveGroup(groupId);
      
      // 从列表中移除
      _groups.removeWhere((g) => g.id == groupId);
      
      // 清除当前群组
      if (_currentGroup?.id == groupId) {
        _currentGroup = null;
        _currentMembers.clear();
        _pendingInvitations.clear();
      }
      
      notifyListeners();
      _logger.info('解散群组成功: $groupId');
      return true;
    } catch (e) {
      _logger.error('解散群组失败: $e');
      _setError('解散群组失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 退出群组
  Future<bool> leaveGroup(String groupId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _groupService.leaveGroup(groupId);
      
      // 从列表中移除
      _groups.removeWhere((g) => g.id == groupId);
      
      // 清除当前群组
      if (_currentGroup?.id == groupId) {
        _currentGroup = null;
        _currentMembers.clear();
        _pendingInvitations.clear();
      }
      
      notifyListeners();
      _logger.info('退出群组成功: $groupId');
      return true;
    } catch (e) {
      _logger.error('退出群组失败: $e');
      _setError('退出群组失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 加载群组成员
  Future<void> loadGroupMembers(String groupId) async {
    try {
      final members = await _groupService.getGroupMembers(groupId);
      _currentMembers = members;
      notifyListeners();
      _logger.info('加载群组成员成功: ${members.length}个成员');
    } catch (e) {
      _logger.error('加载群组成员失败: $e');
      _setError('加载群组成员失败: $e');
    }
  }

  /// 邀请用户加入群组
  Future<bool> inviteToGroup(
    String groupId,
    String userId, {
    String? message,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final invitation = await _groupService.inviteToGroup(
        groupId,
        userId,
        message: message,
      );
      
      _pendingInvitations.add(invitation);
      notifyListeners();
      
      _logger.info('邀请用户加入群组成功: $userId');
      return true;
    } catch (e) {
      _logger.error('邀请用户加入群组失败: $e');
      _setError('邀请用户加入群组失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 处理群组邀请
  Future<bool> respondToInvitation(
    String invitationId,
    bool accept, {
    String? message,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _groupService.respondToInvitation(
        invitationId,
        accept,
        message: message,
      );
      
      // 更新邀请状态
      final index = _myInvitations.indexWhere((inv) => inv.id == invitationId);
      if (index != -1) {
        final invitation = _myInvitations[index];
        _myInvitations[index] = invitation.copyWith(
          status: accept 
              ? GroupInvitationStatus.accepted 
              : GroupInvitationStatus.rejected,
          respondedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
      _logger.info('处理群组邀请成功: $invitationId, accept: $accept');
      return true;
    } catch (e) {
      _logger.error('处理群组邀请失败: $e');
      _setError('处理群组邀请失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 移除群组成员
  Future<bool> removeMember(String groupId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _groupService.removeMember(groupId, userId);
      
      _currentMembers.removeWhere((member) => member.userId == userId);
      notifyListeners();
      
      _logger.info('移除群组成员成功: $userId');
      return true;
    } catch (e) {
      _logger.error('移除群组成员失败: $e');
      _setError('移除群组成员失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 设置成员角色
  Future<bool> setMemberRole(
    String groupId,
    String userId,
    GroupMemberRole role,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updatedMember = await _groupService.setMemberRole(
        groupId,
        userId,
        role,
      );
      
      final index = _currentMembers.indexWhere((m) => m.userId == userId);
      if (index != -1) {
        _currentMembers[index] = updatedMember;
      }
      
      notifyListeners();
      _logger.info('设置成员角色成功: $userId -> ${role.name}');
      return true;
    } catch (e) {
      _logger.error('设置成员角色失败: $e');
      _setError('设置成员角色失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 禁言成员
  Future<bool> muteMember(
    String groupId,
    String userId, {
    Duration? duration,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updatedMember = await _groupService.muteMember(
        groupId,
        userId,
        duration: duration,
      );
      
      final index = _currentMembers.indexWhere((m) => m.userId == userId);
      if (index != -1) {
        _currentMembers[index] = updatedMember;
      }
      
      notifyListeners();
      _logger.info('禁言成员成功: $userId');
      return true;
    } catch (e) {
      _logger.error('禁言成员失败: $e');
      _setError('禁言成员失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 解除禁言
  Future<bool> unmuteMember(String groupId, String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updatedMember = await _groupService.unmuteMember(groupId, userId);
      
      final index = _currentMembers.indexWhere((m) => m.userId == userId);
      if (index != -1) {
        _currentMembers[index] = updatedMember;
      }
      
      notifyListeners();
      _logger.info('解除禁言成功: $userId');
      return true;
    } catch (e) {
      _logger.error('解除禁言失败: $e');
      _setError('解除禁言失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 转让群主
  Future<bool> transferOwnership(String groupId, String newOwnerId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _groupService.transferOwnership(groupId, newOwnerId);
      
      // 重新加载群组信息
      await selectGroup(groupId);
      
      _logger.info('转让群主成功: $newOwnerId');
      return true;
    } catch (e) {
      _logger.error('转让群主失败: $e');
      _setError('转让群主失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 搜索群组
  Future<void> searchGroups(String query) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (query.isEmpty) {
        await loadGroups(refresh: true);
        return;
      }
      
      final groups = await _groupService.searchGroups(
        query,
        type: _filterType,
      );
      
      _groups = groups;
      notifyListeners();
      
      _logger.info('搜索群组成功: ${groups.length}个结果');
    } catch (e) {
      _logger.error('搜索群组失败: $e');
      _setError('搜索群组失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置搜索查询
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 设置类型过滤
  void setFilterType(GroupType? type) {
    _filterType = type;
    notifyListeners();
    loadGroups(refresh: true);
  }

  /// 设置状态过滤
  void setFilterStatus(GroupStatus? status) {
    _filterStatus = status;
    notifyListeners();
    loadGroups(refresh: true);
  }

  /// 清除过滤
  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterStatus = null;
    notifyListeners();
    loadGroups(refresh: true);
  }

  /// 加载群组邀请
  Future<void> loadGroupInvitations(String groupId) async {
    try {
      final invitations = await _groupService.getGroupInvitations(groupId);
      _pendingInvitations = invitations;
      notifyListeners();
      _logger.info('加载群组邀请成功: ${invitations.length}个邀请');
    } catch (e) {
      _logger.error('加载群组邀请失败: $e');
    }
  }

  /// 加载我的群组邀请
  Future<void> loadMyInvitations() async {
    try {
      final invitations = await _groupService.getMyInvitations();
      _myInvitations = invitations;
      notifyListeners();
      _logger.info('加载我的群组邀请成功: ${invitations.length}个邀请');
    } catch (e) {
      _logger.error('加载我的群组邀请失败: $e');
    }
  }

  /// 加载收到的邀请
  Future<void> loadReceivedInvitations() async {
    try {
      final invitations = await _groupService.getReceivedInvitations();
      _receivedInvitations = invitations;
      notifyListeners();
      _logger.info('加载收到的邀请成功: ${invitations.length}个邀请');
    } catch (e) {
      _logger.error('加载收到的邀请失败: $e');
    }
  }

  /// 加载发出的邀请
  Future<void> loadSentInvitations(String groupId) async {
    try {
      final invitations = await _groupService.getSentInvitations(groupId);
      _sentInvitations = invitations;
      notifyListeners();
      _logger.info('加载发出的邀请成功: ${invitations.length}个邀请');
    } catch (e) {
      _logger.error('加载发出的邀请失败: $e');
    }
  }

  /// 标记所有邀请为已读
  Future<void> markAllInvitationsAsRead() async {
    try {
      await _groupService.markAllInvitationsAsRead();
      // 更新本地状态
      _receivedInvitations = _receivedInvitations.map((invitation) => 
        invitation.copyWith(isRead: true)
      ).toList();
      notifyListeners();
      _logger.info('标记所有邀请为已读成功');
    } catch (e) {
      _logger.error('标记所有邀请为已读失败: $e');
    }
  }

  /// 获取群组统计
  Map<String, int> getGroupStatistics() {
    final stats = {
      'total': _groups.length,
      'normal': 0,
      'broadcast': 0,
      'channel': 0,
      'active': 0,
      'archived': 0,
    };

    for (final group in _groups) {
      switch (group.type) {
        case GroupType.normal:
          stats['normal'] = stats['normal']! + 1;
          break;
        case GroupType.broadcast:
          stats['broadcast'] = stats['broadcast']! + 1;
          break;
        case GroupType.channel:
          stats['channel'] = stats['channel']! + 1;
          break;
      }

      switch (group.status) {
        case GroupStatus.active:
          stats['active'] = stats['active']! + 1;
          break;
        case GroupStatus.archived:
          stats['archived'] = stats['archived']! + 1;
          break;
        default:
          break;
      }
    }

    return stats;
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误
  void _clearError() {
    _error = null;
  }

  /// 设置订阅
  void _setupSubscriptions() {
    _groupUpdatedSubscription = _groupService.groupUpdatedStream.listen((group) {
      final index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _groups[index] = group;
      } else {
        _groups.insert(0, group);
      }
      
      if (_currentGroup?.id == group.id) {
        _currentGroup = group;
      }
      
      notifyListeners();
    });

    _memberUpdatedSubscription = _groupService.memberUpdatedStream.listen((member) {
      if (_currentGroup?.id == member.groupId) {
        final index = _currentMembers.indexWhere((m) => m.userId == member.userId);
        if (index != -1) {
          _currentMembers[index] = member;
        } else {
          _currentMembers.add(member);
        }
        notifyListeners();
      }
    });

    _invitationUpdatedSubscription = _groupService.invitationUpdatedStream.listen((invitation) {
      // 更新待处理邀请
      if (_currentGroup?.id == invitation.groupId) {
        final index = _pendingInvitations.indexWhere((inv) => inv.id == invitation.id);
        if (index != -1) {
          _pendingInvitations[index] = invitation;
        } else {
          _pendingInvitations.add(invitation);
        }
      }
      
      // 更新我的邀请
      final myIndex = _myInvitations.indexWhere((inv) => inv.id == invitation.id);
      if (myIndex != -1) {
        _myInvitations[myIndex] = invitation;
      } else {
        _myInvitations.add(invitation);
      }
      
      notifyListeners();
    });

    _groupDeletedSubscription = _groupService.groupDeletedStream.listen((groupId) {
      _groups.removeWhere((g) => g.id == groupId);
      
      if (_currentGroup?.id == groupId) {
        _currentGroup = null;
        _currentMembers.clear();
        _pendingInvitations.clear();
      }
      
      notifyListeners();
    });
  }
}