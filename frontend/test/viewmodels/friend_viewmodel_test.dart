import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/presentation/viewmodels/friend_viewmodel.dart';
import 'package:chat_app/domain/repositories/friend_repository.dart';
import 'package:chat_app/core/services/notification_service.dart';
import 'package:chat_app/domain/models/user_model.dart';
import 'package:chat_app/domain/models/friend_request_model.dart';

// 手动Mock实现
class TestFriendRepository implements FriendRepository {
  bool shouldThrowError = false;
  String? errorMessage;
  
  @override
  Future<void> sendFriendRequest(String userId, {String? message}) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '网络错误');
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '请求已过期');
    }
  }

  @override
  Future<List<FriendRequest>> getPendingFriendRequests() async {
    return <FriendRequest>[];
  }

  @override
  Future<List<FriendRequest>> getSentFriendRequests() async {
    return <FriendRequest>[];
  }

  @override
  Future<List<UserModel>> getFriends() async {
    return <UserModel>[];
  }

  @override
  Future<List<UserModel>> getBlockedUsers() async {
    return <UserModel>[];
  }

  @override
  Future<Map<String, String>> getFriendRemarks() async {
    return <String, String>{};
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {}

  @override
  Future<void> cancelFriendRequest(String requestId) async {}

  @override
  Future<void> removeFriend(String userId) async {}

  @override
  Future<void> blockUser(String userId) async {}

  @override
  Future<void> unblockUser(String userId) async {}

  @override
  Future<void> updateFriendRemark(String userId, String remark) async {}

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    return <UserModel>[];
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    return null;
  }

  @override
  Future<bool> isFriend(String userId) async {
    return false;
  }

  @override
  Future<bool> hasPendingFriendRequest(String userId) async {
    return false;
  }

  @override
  Future<bool> isUserBlocked(String userId) async {
    return false;
  }

  @override
  Future<FriendRequest?> getFriendRequestById(String requestId) async {
    return null;
  }

  @override
  Future<Map<String, int>> getFriendStats() async {
    return <String, int>{};
  }

  @override
  Future<List<UserModel>> getRecommendedFriends() async {
    return <UserModel>[];
  }

  @override
  Future<List<UserModel>> getMutualFriends(String userId) async {
    return <UserModel>[];
  }

  @override
  Future<void> batchProcessFriendRequests(
    List<String> requestIds,
    FriendRequestStatus action,
  ) async {}

  @override
  Future<void> setFriendGroup(String userId, String groupName) async {}

  @override
  Future<Map<String, List<UserModel>>> getFriendGroups() async {
    return <String, List<UserModel>>{};
  }

  @override
  Future<void> syncFriends() async {}

  @override
  Future<void> clearCache() async {}
}

// 使用真实的NotificationService实例进行测试

void main() {
  group('FriendViewModel 添加好友功能测试', () {
    test('发送好友请求成功 - 带消息', () async {
      final testRepository = TestFriendRepository();
      final testNotificationService = NotificationService();
      
      final friendViewModel = FriendViewModel(
        friendRepository: testRepository,
        notificationService: testNotificationService,
      );
      
      // 执行
      await friendViewModel.sendFriendRequest('test-user-123', message: '你好，我想加你为好友');

      // 验证状态
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('发送好友请求成功 - 不带消息', () async {
      final testRepository = TestFriendRepository();
      final testNotificationService = NotificationService();
      
      final friendViewModel = FriendViewModel(
        friendRepository: testRepository,
        notificationService: testNotificationService,
      );
      
      // 执行
      await friendViewModel.sendFriendRequest('test-user-123');

      // 验证状态
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('发送好友请求失败处理', () async {
      final testRepository = TestFriendRepository();
      testRepository.shouldThrowError = true;
      testRepository.errorMessage = '网络错误';
      final testNotificationService = NotificationService();
      
      final friendViewModel = FriendViewModel(
        friendRepository: testRepository,
        notificationService: testNotificationService,
      );

      // 执行和验证
      try {
        await friendViewModel.sendFriendRequest('user789');
        fail('应该抛出异常');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(friendViewModel.isLoading, isFalse);
      }
    });

    test('接受好友请求成功', () async {
      final testRepository = TestFriendRepository();
      final testNotificationService = NotificationService();
      
      final friendViewModel = FriendViewModel(
        friendRepository: testRepository,
        notificationService: testNotificationService,
      );

      // 执行
      await friendViewModel.acceptFriendRequest('request123');

      // 验证
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('接受好友请求失败处理', () async {
      final testRepository = TestFriendRepository();
      testRepository.shouldThrowError = true;
      testRepository.errorMessage = '请求已过期';
      final testNotificationService = NotificationService();
      
      final friendViewModel = FriendViewModel(
        friendRepository: testRepository,
        notificationService: testNotificationService,
      );

      // 执行和验证
      try {
        await friendViewModel.acceptFriendRequest('expired-request');
        fail('应该抛出异常');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(friendViewModel.isLoading, isFalse);
      }
    });

    test('初始状态检查', () {
      final testRepository = TestFriendRepository();
      final testNotificationService = NotificationService();
      
      final friendViewModel = FriendViewModel(
        friendRepository: testRepository,
        notificationService: testNotificationService,
      );
      
      expect(friendViewModel.friends, isEmpty);
      expect(friendViewModel.pendingFriendRequests, isEmpty);
      expect(friendViewModel.sentFriendRequests, isEmpty);
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });
  });
}