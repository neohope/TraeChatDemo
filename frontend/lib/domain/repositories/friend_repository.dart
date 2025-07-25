import '../models/user_model.dart';
import '../models/friend_request_model.dart';

/// 好友仓库接口
abstract class FriendRepository {
  /// 获取好友列表
  Future<List<UserModel>> getFriends();

  /// 获取待处理的好友请求
  Future<List<FriendRequest>> getPendingFriendRequests();

  /// 获取已发送的好友请求
  Future<List<FriendRequest>> getSentFriendRequests();

  /// 获取黑名单用户
  Future<List<UserModel>> getBlockedUsers();

  /// 获取好友备注
  Future<Map<String, String>> getFriendRemarks();

  /// 发送好友请求
  Future<void> sendFriendRequest(String userId, {String? message});

  /// 接受好友请求
  Future<void> acceptFriendRequest(String requestId);

  /// 拒绝好友请求
  Future<void> rejectFriendRequest(String requestId);

  /// 取消好友请求
  Future<void> cancelFriendRequest(String requestId);

  /// 删除好友
  Future<void> removeFriend(String userId);

  /// 拉黑用户
  Future<void> blockUser(String userId);

  /// 解除拉黑
  Future<void> unblockUser(String userId);

  /// 更新好友备注
  Future<void> updateFriendRemark(String userId, String remark);

  /// 搜索用户
  Future<List<UserModel>> searchUsers(String query);

  /// 获取用户详情
  Future<UserModel?> getUserById(String userId);

  /// 检查是否为好友
  Future<bool> isFriend(String userId);

  /// 检查是否有待处理的好友请求
  Future<bool> hasPendingFriendRequest(String userId);

  /// 检查用户是否被拉黑
  Future<bool> isUserBlocked(String userId);

  /// 获取好友请求详情
  Future<FriendRequest?> getFriendRequestById(String requestId);

  /// 获取好友统计信息
  Future<Map<String, int>> getFriendStats();

  /// 获取推荐好友
  Future<List<UserModel>> getRecommendedFriends();

  /// 获取共同好友
  Future<List<UserModel>> getMutualFriends(String userId);

  /// 批量操作好友请求
  Future<void> batchProcessFriendRequests(
    List<String> requestIds,
    FriendRequestStatus action,
  );

  /// 设置好友分组
  Future<void> setFriendGroup(String userId, String groupName);

  /// 获取好友分组
  Future<Map<String, List<UserModel>>> getFriendGroups();

  /// 同步好友数据
  Future<void> syncFriends();

  /// 清除缓存
  Future<void> clearCache();
}