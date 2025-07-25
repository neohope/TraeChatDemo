import 'package:flutter/foundation.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/friend_model.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/app_logger.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final AppLogger _logger = AppLogger.instance;

  UserViewModel(this._apiService);

  List<UserModel> _users = [];
  List<UserModel> _searchResults = [];
  List<UserModel> _recentSearches = [];
  List<UserModel> _recommendedUsers = [];
  List<UserModel> _nearbyUsers = [];
  List<Friend> _friends = [];
  bool _isLoading = false;
  String? _error;
  UserModel? _selectedUser;
  UserModel? _currentUser;

  // Getters
  List<UserModel> get users => _users;
  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get recentSearches => _recentSearches;
  List<UserModel> get recommendedUsers => _recommendedUsers;
  List<UserModel> get nearbyUsers => _nearbyUsers;
  List<Friend> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get selectedUser => _selectedUser;
  UserModel? get currentUser => _currentUser;

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _setError(null);
  }

  /// 搜索用户
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('/users/search?q=${Uri.encodeComponent(query)}');
      
      if (response['success'] == true) {
        _searchResults = (response['data'] as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      } else {
        _setError(response['message'] ?? '搜索用户失败');
      }
    } catch (e) {
      _logger.error('搜索用户失败: $e');
      _setError('搜索用户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 获取用户详情
  Future<UserModel?> getUserDetails(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('/users/$userId');
      
      if (response['success'] == true) {
        final user = UserModel.fromJson(response['data']);
        _selectedUser = user;
        notifyListeners();
        return user;
      } else {
        _setError(response['message'] ?? '获取用户详情失败');
        return null;
      }
    } catch (e) {
      _logger.error('获取用户详情失败: $e');
      _setError('获取用户详情失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取好友列表
  Future<void> loadFriends() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('/friends');
      
      if (response['success'] == true) {
        _friends = (response['data'] as List)
            .map((json) => Friend.fromJson(json))
            .toList();
      } else {
        _setError(response['message'] ?? '获取好友列表失败');
      }
    } catch (e) {
      _logger.error('获取好友列表失败: $e');
      _setError('获取好友列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 发送好友请求
  Future<bool> sendFriendRequest(String userId, {String? message}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post('/friends/request', data: {
        'userId': userId,
        'message': message,
      });
      
      if (response['success'] == true) {
        _logger.info('好友请求发送成功');
        return true;
      } else {
        _setError(response['message'] ?? '发送好友请求失败');
        return false;
      }
    } catch (e) {
      _logger.error('发送好友请求失败: $e');
      _setError('发送好友请求失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 接受好友请求
  Future<bool> acceptFriendRequest(String requestId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post('/friends/accept', data: {
        'requestId': requestId,
      });
      
      if (response['success'] == true) {
        _logger.info('好友请求已接受');
        await loadFriends(); // 重新加载好友列表
        return true;
      } else {
        _setError(response['message'] ?? '接受好友请求失败');
        return false;
      }
    } catch (e) {
      _logger.error('接受好友请求失败: $e');
      _setError('接受好友请求失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 拒绝好友请求
  Future<bool> rejectFriendRequest(String requestId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post('/friends/reject', data: {
        'requestId': requestId,
      });
      
      if (response['success'] == true) {
        _logger.info('好友请求已拒绝');
        return true;
      } else {
        _setError(response['message'] ?? '拒绝好友请求失败');
        return false;
      }
    } catch (e) {
      _logger.error('拒绝好友请求失败: $e');
      _setError('拒绝好友请求失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除好友
  Future<bool> removeFriend(String friendId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.delete('/friends/$friendId');
      
      if (response['success'] == true) {
        _friends.removeWhere((friend) => friend.friendId == friendId);
        notifyListeners();
        _logger.info('好友已删除');
        return true;
      } else {
        _setError(response['message'] ?? '删除好友失败');
        return false;
      }
    } catch (e) {
      _logger.error('删除好友失败: $e');
      _setError('删除好友失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新好友备注
  Future<bool> updateFriendNickname(String friendId, String nickname) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.put('/friends/$friendId/nickname', data: {
        'nickname': nickname,
      });
      
      if (response['success'] == true) {
        // 更新本地好友列表
        final index = _friends.indexWhere((friend) => friend.friendId == friendId);
        if (index != -1) {
          _friends[index] = _friends[index].copyWith(nickname: nickname);
          notifyListeners();
        }
        _logger.info('好友备注已更新');
        return true;
      } else {
        _setError(response['message'] ?? '更新好友备注失败');
        return false;
      }
    } catch (e) {
      _logger.error('更新好友备注失败: $e');
      _setError('更新好友备注失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 屏蔽/取消屏蔽好友
  Future<bool> toggleBlockFriend(String friendId, bool block) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post('/friends/$friendId/block', data: {
        'block': block,
      });
      
      if (response['success'] == true) {
        // 更新本地好友列表
        final index = _friends.indexWhere((friend) => friend.friendId == friendId);
        if (index != -1) {
          _friends[index] = _friends[index].copyWith(isBlocked: block);
          notifyListeners();
        }
        _logger.info(block ? '好友已屏蔽' : '好友已取消屏蔽');
        return true;
      } else {
        _setError(response['message'] ?? (block ? '屏蔽好友失败' : '取消屏蔽好友失败'));
        return false;
      }
    } catch (e) {
      _logger.error('${block ? '屏蔽' : '取消屏蔽'}好友失败: $e');
      _setError('${block ? '屏蔽' : '取消屏蔽'}好友失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 清除搜索结果
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// 清除选中的用户
  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  /// 根据ID获取用户
  UserModel? getUserById(String userId) {
    // 首先检查当前用户
    if (_currentUser?.id == userId) {
      return _currentUser;
    }
    
    // 然后检查用户列表
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      // 如果没找到，返回null
      return null;
    }
  }

  /// 设置当前用户
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// 添加到最近搜索
  void addToRecentSearches(UserModel user) {
    // 移除已存在的用户
    _recentSearches.removeWhere((u) => u.id == user.id);
    // 添加到开头
    _recentSearches.insert(0, user);
    // 限制最多10个
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    notifyListeners();
  }

  /// 加载推荐用户
  Future<void> loadRecommendedUsers() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get('/users/recommended');
      if (response['success'] == true) {
        final List<dynamic> usersData = response['data'] ?? [];
        _recommendedUsers = usersData
            .map((json) => UserModel.fromJson(json))
            .toList();
        notifyListeners();
        _logger.info('推荐用户加载成功: ${_recommendedUsers.length}个');
      } else {
        _setError(response['message'] ?? '加载推荐用户失败');
      }
    } catch (e) {
      _logger.error('加载推荐用户失败: $e');
      _setError('加载推荐用户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载附近用户
  Future<void> loadNearbyUsers() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.get('/users/nearby');
      if (response['success'] == true) {
        final List<dynamic> usersData = response['data'] ?? [];
        _nearbyUsers = usersData
            .map((json) => UserModel.fromJson(json))
            .toList();
        notifyListeners();
        _logger.info('附近用户加载成功: ${_nearbyUsers.length}个');
      } else {
        _setError(response['message'] ?? '加载附近用户失败');
      }
    } catch (e) {
      _logger.error('加载附近用户失败: $e');
      _setError('加载附近用户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}