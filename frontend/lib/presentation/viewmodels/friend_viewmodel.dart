import 'package:flutter/foundation.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/friend_request_model.dart';
import '../../domain/repositories/friend_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/conversation_model.dart'; // For UserStatus enum

/// 好友管理ViewModel
class FriendViewModel extends ChangeNotifier {
  final FriendRepository _friendRepository;
  final NotificationService _notificationService;
  final AppLogger _logger = AppLogger.instance;

  // 状态变量
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  
  // 好友相关数据
  List<UserModel> _friends = [];
  List<FriendRequest> _pendingFriendRequests = [];
  List<FriendRequest> _sentFriendRequests = [];
  List<UserModel> _blockedUsers = [];
  Map<String, String> _friendRemarks = {};
  
  // 统计数据
  int _totalFriends = 0;
  int _onlineFriends = 0;
  int _pendingRequestsCount = 0;

  FriendViewModel({
    required FriendRepository friendRepository,
    required NotificationService notificationService,
  }) : _friendRepository = friendRepository,
       _notificationService = notificationService;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserModel> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get pendingFriendRequests => List.unmodifiable(_pendingFriendRequests);
  List<FriendRequest> get sentFriendRequests => List.unmodifiable(_sentFriendRequests);
  List<UserModel> get blockedUsers => List.unmodifiable(_blockedUsers);
  Map<String, String> get friendRemarks => Map.unmodifiable(_friendRemarks);
  int get totalFriends => _totalFriends;
  int get onlineFriends => _onlineFriends;
  int get pendingRequestsCount => _pendingRequestsCount;

  /// 初始化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _clearError();
      
      await Future.wait([
        loadFriends(),
        loadFriendRequests(),
        loadBlockedUsers(),
        loadFriendRemarks(),
      ]);
      
      _isInitialized = true;
      _logger.logger.i('FriendViewModel initialized successfully');
    } catch (e) {
      _setError('初始化失败: $e');
      _logger.logger.e('Failed to initialize FriendViewModel: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载好友列表
  Future<void> loadFriends() async {
    try {
      _setLoading(true);
      _clearError();
      
      final friends = await _friendRepository.getFriends();
      _friends = friends;
      _totalFriends = friends.length;
      _onlineFriends = friends.where((f) => f.status == UserStatus.online).length;
      
      _logger.logger.i('Loaded ${friends.length} friends');
      notifyListeners();
    } catch (e) {
      _setError('加载好友列表失败: $e');
      _logger.logger.e('Failed to load friends: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载好友请求
  Future<void> loadFriendRequests() async {
    try {
      _setLoading(true);
      _clearError();
      
      final pendingRequests = await _friendRepository.getPendingFriendRequests();
      final sentRequests = await _friendRepository.getSentFriendRequests();
      
      _pendingFriendRequests = pendingRequests;
      _sentFriendRequests = sentRequests;
      _pendingRequestsCount = pendingRequests.length;
      
      _logger.logger.i('Loaded ${pendingRequests.length} pending and ${sentRequests.length} sent friend requests');
      notifyListeners();
    } catch (e) {
      _setError('加载好友请求失败: $e');
      _logger.logger.e('Failed to load friend requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载黑名单用户
  Future<void> loadBlockedUsers() async {
    try {
      _setLoading(true);
      _clearError();
      
      final blockedUsers = await _friendRepository.getBlockedUsers();
      _blockedUsers = blockedUsers;
      
      _logger.logger.i('Loaded ${blockedUsers.length} blocked users');
      notifyListeners();
    } catch (e) {
      _setError('加载黑名单失败: $e');
      _logger.logger.e('Failed to load blocked users: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载好友备注
  Future<void> loadFriendRemarks() async {
    try {
      final remarks = await _friendRepository.getFriendRemarks();
      _friendRemarks = remarks;
      
      _logger.logger.i('Loaded ${remarks.length} friend remarks');
      notifyListeners();
    } catch (e) {
      _setError('加载好友备注失败: $e');
      _logger.logger.e('Failed to load friend remarks: $e');
    }
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(String userId, {String? message}) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.sendFriendRequest(userId, message: message);
      
      // 重新加载发送的好友请求
      await loadFriendRequests();
      
      _logger.logger.i('Friend request sent to user: $userId');
      
      // 发送通知
      await _notificationService.showNotification(
        title: '好友请求已发送',
        body: '您的好友请求已成功发送',
      );
    } catch (e) {
      _setError('发送好友请求失败: $e');
      _logger.logger.e('Failed to send friend request to $userId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 接受好友请求
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.acceptFriendRequest(requestId);
      
      // 重新加载数据
      await Future.wait([
        loadFriends(),
        loadFriendRequests(),
      ]);
      
      _logger.logger.i('Friend request accepted: $requestId');
      
      // 发送通知
      await _notificationService.showNotification(
        title: '好友请求已接受',
        body: '您已成功添加新好友',
      );
    } catch (e) {
      _setError('接受好友请求失败: $e');
      _logger.logger.e('Failed to accept friend request $requestId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 拒绝好友请求
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.rejectFriendRequest(requestId);
      
      // 重新加载好友请求
      await loadFriendRequests();
      
      _logger.logger.i('Friend request rejected: $requestId');
    } catch (e) {
      _setError('拒绝好友请求失败: $e');
      _logger.logger.e('Failed to reject friend request $requestId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 取消好友请求
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.cancelFriendRequest(requestId);
      
      // 重新加载发送的好友请求
      await loadFriendRequests();
      
      _logger.logger.i('Friend request cancelled: $requestId');
    } catch (e) {
      _setError('取消好友请求失败: $e');
      _logger.logger.e('Failed to cancel friend request $requestId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除好友
  Future<void> removeFriend(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.removeFriend(userId);
      
      // 重新加载好友列表
      await loadFriends();
      
      _logger.logger.i('Friend removed: $userId');
      
      // 发送通知
      await _notificationService.showNotification(
        title: '好友已删除',
        body: '已成功删除好友',
      );
    } catch (e) {
      _setError('删除好友失败: $e');
      _logger.logger.e('Failed to remove friend $userId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 拉黑用户
  Future<void> blockUser(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.blockUser(userId);
      
      // 重新加载数据
      await Future.wait([
        loadFriends(),
        loadBlockedUsers(),
      ]);
      
      _logger.logger.i('User blocked: $userId');
      
      // 发送通知
      await _notificationService.showNotification(
        title: '用户已拉黑',
        body: '已成功拉黑用户',
      );
    } catch (e) {
      _setError('拉黑用户失败: $e');
      _logger.logger.e('Failed to block user $userId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 解除拉黑
  Future<void> unblockUser(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.unblockUser(userId);
      
      // 重新加载黑名单
      await loadBlockedUsers();
      
      _logger.logger.i('User unblocked: $userId');
      
      // 发送通知
      await _notificationService.showNotification(
        title: '已解除拉黑',
        body: '已成功解除用户拉黑',
      );
    } catch (e) {
      _setError('解除拉黑失败: $e');
      _logger.logger.e('Failed to unblock user $userId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新好友备注
  Future<void> updateFriendRemark(String userId, String remark) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.updateFriendRemark(userId, remark);
      
      // 更新本地备注
      _friendRemarks[userId] = remark;
      
      _logger.logger.i('Friend remark updated for user: $userId');
      notifyListeners();
    } catch (e) {
      _setError('更新好友备注失败: $e');
      _logger.logger.e('Failed to update friend remark for $userId: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 检查是否为好友
  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  /// 检查是否有待处理的好友请求
  bool hasPendingFriendRequest(String userId) {
    return _pendingFriendRequests.any((request) => request.senderId == userId) ||
           _sentFriendRequests.any((request) => request.receiverId == userId);
  }

  /// 检查用户是否被拉黑
  bool isUserBlocked(String userId) {
    return _blockedUsers.any((user) => user.id == userId);
  }

  /// 获取好友备注
  String? getFriendRemark(String userId) {
    return _friendRemarks[userId];
  }

  /// 根据关键词搜索好友
  List<UserModel> searchFriends(String query) {
    if (query.isEmpty) return _friends;
    
    final lowerQuery = query.toLowerCase();
    return _friends.where((UserModel friend) {
      final remark = _friendRemarks[friend.id];
      return friend.name.toLowerCase().contains(lowerQuery) ||
             (friend.nickname?.toLowerCase().contains(lowerQuery) ?? false) ||
             (remark?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 获取在线好友
  List<UserModel> getOnlineFriends() {
    return _friends.where((UserModel friend) => friend.status == UserStatus.online).toList();
  }

  /// 获取好友统计信息
  Map<String, int> getFriendStats() {
    return {
      'total': _totalFriends,
      'online': _onlineFriends,
      'offline': _totalFriends - _onlineFriends,
      'pending_requests': _pendingRequestsCount,
      'blocked': _blockedUsers.length,
    };
  }

  /// 刷新所有数据
  Future<void> refresh() async {
    try {
      _setLoading(true);
      _clearError();
      
      await Future.wait([
        loadFriends(),
        loadFriendRequests(),
        loadBlockedUsers(),
        loadFriendRemarks(),
      ]);
      
      _logger.logger.i('Friend data refreshed successfully');
    } catch (e) {
      _setError('刷新数据失败: $e');
      _logger.logger.e('Failed to refresh friend data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _logger.logger.i('FriendViewModel disposed');
    super.dispose();
  }
}