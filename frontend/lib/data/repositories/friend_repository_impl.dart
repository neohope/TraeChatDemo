import '../../../domain/repositories/friend_repository.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/friend_request_model.dart';
import '../../core/services/api_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/storage/local_storage.dart';

/// 好友仓库实现类
class FriendRepositoryImpl implements FriendRepository {
  static FriendRepositoryImpl? _instance;
  static FriendRepositoryImpl get instance {
    if (_instance == null) {
      throw Exception('FriendRepositoryImpl not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  // ignore: unused_field
  final ApiService _apiService;
  final AppLogger _logger = AppLogger.instance;

  FriendRepositoryImpl._internal(this._apiService);
  
  /// 初始化仓库实例
  static void initialize(ApiService apiService) {
    _instance = FriendRepositoryImpl._internal(apiService);
  }
  
  @override
  Future<List<UserModel>> getFriends() async {
    try {
      final response = await _apiService.get('/api/v1/friends');
      
      // 处理 null 响应
      if (response == null) {
        _logger.logger.i('好友列表为空');
        return [];
      }
      
      List<dynamic> dataList = [];
      if (response is List) {
        dataList = response as List<dynamic>;
      } else if (response is Map && response['data'] is List) {
        dataList = response['data'] as List<dynamic>;
      }
      
      return dataList.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.logger.e('获取好友列表失败: $e');
      return [];
    }
  }
  
  @override
  Future<List<FriendRequest>> getPendingFriendRequests() async {
    try {
      final response = await _apiService.get('/api/v1/friends/pending');
      
      // 处理 null 响应
      if (response == null) {
        _logger.logger.i('待处理好友请求为空');
        return [];
      }
      
      List<dynamic> dataList = [];
      if (response is List) {
        dataList = response as List<dynamic>;
      } else if (response is Map && response['data'] is List) {
        dataList = response['data'] as List<dynamic>;
      }
      
      return dataList.map((json) => FriendRequest.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.logger.e('获取待处理好友请求失败: $e');
      return [];
    }
  }
  
  @override
  Future<List<FriendRequest>> getSentFriendRequests() async {
    try {
      final response = await _apiService.get('/api/v1/friends/sent');
      
      // 处理 null 响应
      if (response == null) {
        _logger.logger.i('已发送好友请求为空');
        return [];
      }
      
      List<dynamic> dataList = [];
      if (response is List) {
        dataList = response as List<dynamic>;
      } else if (response is Map && response['data'] is List) {
        dataList = response['data'] as List<dynamic>;
      }
      
      return dataList.map((json) => FriendRequest.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.logger.e('获取已发送好友请求失败: $e');
      return [];
    }
  }
  
  @override
  Future<List<UserModel>> getBlockedUsers() async {
    try {
      // 暂时返回空列表
      return [];
    } catch (e) {
      _logger.logger.e('获取黑名单用户失败: $e');
      return [];
    }
  }
  
  @override
  Future<void> sendFriendRequest(String userId, {String? message}) async {
    try {
      final response = await _apiService.post('/api/v1/friends/request', data: {
        'userId': userId,
        'message': message,
      });
      
      if (response['success'] != true) {
        // 直接抛出API返回的错误信息，不添加额外前缀
        final errorMessage = response['message'] ?? response['error'] ?? '发送好友请求失败';
        throw Exception(errorMessage);
      }
      
      _logger.logger.i('发送好友请求成功: $userId');
    } catch (e) {
      _logger.logger.e('发送好友请求失败: $e');
      // 如果是我们自己抛出的异常，直接重新抛出
      if (e is Exception) {
        rethrow;
      }
      // 如果是其他类型的错误，包装后抛出
      throw Exception('发送好友请求失败: $e');
    }
  }
  
  @override
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final response = await _apiService.post('/api/v1/friends/accept', data: {
        'requestId': requestId,
      });
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '接受好友请求失败');
      }
      
      _logger.logger.i('接受好友请求成功: $requestId');
    } catch (e) {
      _logger.logger.e('接受好友请求失败: $e');
      throw Exception('接受好友请求失败: $e');
    }
  }
  
  @override
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      final response = await _apiService.post('/api/v1/friends/reject', data: {
        'requestId': requestId,
      });
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '拒绝好友请求失败');
      }
      
      _logger.logger.i('拒绝好友请求成功: $requestId');
    } catch (e) {
      _logger.logger.e('拒绝好友请求失败: $e');
      throw Exception('拒绝好友请求失败: $e');
    }
  }
  
  @override
  // ignore: override_on_non_overriding_member
  Future<void> deleteFriend(String userId) async {
    try {
      _logger.logger.i('删除好友: $userId');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('删除好友失败: $e');
      throw Exception('删除好友失败: $e');
    }
  }
  
  @override
  Future<void> removeFriend(String userId) async {
    try {
      _logger.logger.i('移除好友: $userId');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('移除好友失败: $e');
      throw Exception('移除好友失败: $e');
    }
  }
  
  @override
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      _logger.logger.i('取消好友请求: $requestId');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('取消好友请求失败: $e');
      throw Exception('取消好友请求失败: $e');
    }
  }
  
  @override
  Future<Map<String, String>> getFriendRemarks() async {
    try {
      // 暂时返回空 Map
      return {};
    } catch (e) {
      _logger.logger.e('获取好友备注失败: $e');
      return {};
    }
  }
  
  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      // 暂时返回 null
      return null;
    } catch (e) {
      _logger.logger.e('获取用户详情失败: $e');
      return null;
    }
  }
  
  @override
  Future<bool> isFriend(String userId) async {
    try {
      // 暂时返回 false
      return false;
    } catch (e) {
      _logger.logger.e('检查好友关系失败: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasPendingFriendRequest(String userId) async {
    try {
      // 暂时返回 false
      return false;
    } catch (e) {
      _logger.logger.e('检查待处理好友请求失败: $e');
      return false;
    }
  }
  
  @override
  Future<void> updateFriendRemark(String userId, String remark) async {
    try {
      _logger.logger.i('更新好友备注: $userId -> $remark');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('更新好友备注失败: $e');
      throw Exception('更新好友备注失败: $e');
    }
  }
  
  @override
  Future<void> blockUser(String userId) async {
    try {
      _logger.logger.i('拉黑用户: $userId');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('拉黑用户失败: $e');
      throw Exception('拉黑用户失败: $e');
    }
  }
  
  @override
  Future<void> unblockUser(String userId) async {
    try {
      _logger.logger.i('取消拉黑用户: $userId');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('取消拉黑用户失败: $e');
      throw Exception('取消拉黑用户失败: $e');
    }
  }
  
  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // 暂时返回空列表
      return [];
    } catch (e) {
      _logger.logger.e('搜索用户失败: $e');
      return [];
    }
  }
  
  @override
  // ignore: override_on_non_overriding_member
  Future<void> setFriendRemark(String userId, String remark) async {
    try {
      _logger.logger.i('设置好友备注: $userId -> $remark');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('设置好友备注失败: $e');
      throw Exception('设置好友备注失败: $e');
    }
  }
  
  @override
  // ignore: override_on_non_overriding_member
  Future<String?> getFriendRemark(String userId) async {
    try {
      // 暂时返回 null
      return null;
    } catch (e) {
      _logger.logger.e('获取好友备注失败: $e');
      return null;
    }
  }
  
  @override
  // ignore: override_on_non_overriding_member
  Future<Map<String, String>> getAllFriendRemarks() async {
    try {
      // 暂时返回空 Map
      return {};
    } catch (e) {
      _logger.logger.e('获取所有好友备注失败: $e');
      return {};
    }
  }
  
  @override
  Future<bool> isUserBlocked(String userId) async {
    try {
      // 暂时返回 false
      return false;
    } catch (e) {
      _logger.logger.e('检查用户拉黑状态失败: $e');
      return false;
    }
  }
  
  @override
  Future<FriendRequest?> getFriendRequestById(String requestId) async {
    try {
      // 暂时返回 null
      return null;
    } catch (e) {
      _logger.logger.e('获取好友请求详情失败: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, int>> getFriendStats() async {
    try {
      // 返回默认统计数据
      return {
        'total_friends': 0,
        'online_friends': 0,
        'pending_requests': 0,
      };
    } catch (e) {
      _logger.logger.e('获取好友统计信息失败: $e');
      return {};
    }
  }
  
  @override
  Future<List<UserModel>> getRecommendedFriends() async {
    try {
      // 暂时返回空列表
      return [];
    } catch (e) {
      _logger.logger.e('获取推荐好友失败: $e');
      return [];
    }
  }
  
  @override
  Future<List<UserModel>> getMutualFriends(String userId) async {
    try {
      // 暂时返回空列表
      return [];
    } catch (e) {
      _logger.logger.e('获取共同好友失败: $e');
      return [];
    }
  }
  
  @override
  Future<void> batchProcessFriendRequests(
    List<String> requestIds,
    FriendRequestStatus action,
  ) async {
    try {
      _logger.logger.i('批量处理好友请求: $requestIds -> ${action.name}');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('批量处理好友请求失败: $e');
      throw Exception('批量处理好友请求失败: $e');
    }
  }
  
  @override
  Future<void> setFriendGroup(String userId, String groupName) async {
    try {
      _logger.logger.i('设置好友分组: $userId -> $groupName');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('设置好友分组失败: $e');
      throw Exception('设置好友分组失败: $e');
    }
  }
  
  @override
  Future<Map<String, List<UserModel>>> getFriendGroups() async {
    try {
      // 暂时返回空 Map
      return {};
    } catch (e) {
      _logger.logger.e('获取好友分组失败: $e');
      return {};
    }
  }
  
  @override
  Future<void> syncFriends() async {
    try {
      _logger.logger.i('同步好友数据');
      // 暂时只记录日志
    } catch (e) {
      _logger.logger.e('同步好友数据失败: $e');
      throw Exception('同步好友数据失败: $e');
    }
  }
  
  @override
  Future<void> clearCache() async {
    try {
      await LocalStorage.saveChatData('friends', []);
      await LocalStorage.saveChatData('friend_remarks', {});
      _logger.logger.i('清除好友缓存成功');
    } catch (e) {
      _logger.logger.e('清除好友缓存失败: $e');
    }
  }
}