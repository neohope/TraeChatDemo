import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/data/repositories/friend_repository_impl.dart';
import 'package:chat_app/domain/models/friend_request_model.dart';
import 'package:chat_app/domain/models/user_model.dart';
import 'package:chat_app/domain/repositories/friend_repository.dart';
import 'package:chat_app/core/services/api_service.dart';
import 'package:chat_app/core/config/app_config.dart';
import 'package:chat_app/presentation/viewmodels/friend_viewmodel.dart';
import 'package:chat_app/core/services/notification_service.dart';

// Mock API Service for testing
class MockApiService {
  final Map<String, dynamic> _mockData = {};
  bool _shouldReturnError = false;
  String? _errorMessage;

  void setMockData(String endpoint, dynamic data) {
    _mockData[endpoint] = data;
  }

  void setShouldReturnError(bool shouldError, [String? message]) {
    _shouldReturnError = shouldError;
    _errorMessage = message;
  }

  Future<dynamic> get(String endpoint) async {
    if (_shouldReturnError) {
      throw Exception(_errorMessage ?? 'Network error');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _mockData[endpoint] ?? [];
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data}) async {
    if (_shouldReturnError) {
      throw Exception(_errorMessage ?? 'Network error');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 模拟成功响应
    return {
      'success': true,
      'message': '操作成功',
      'data': data,
    };
  }
}

// Mock Friend Repository for testing
class MockFriendRepository implements FriendRepository {
  final MockApiService _mockApiService;
  
  MockFriendRepository(this._mockApiService);

  @override
  Future<List<UserModel>> getFriends() async {
    return [];
  }

  @override
  Future<List<UserModel>> getBlockedUsers() async {
    return [];
  }

  @override
  Future<Map<String, String>> getFriendRemarks() async {
    return {};
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
    return [];
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
    return {};
  }

  @override
  Future<List<UserModel>> getRecommendedFriends() async {
    return [];
  }

  @override
  Future<List<UserModel>> getMutualFriends(String userId) async {
    return [];
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
    return {};
  }

  @override
  Future<void> syncFriends() async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<List<FriendRequest>> getPendingFriendRequests() async {
    try {
      final response = await _mockApiService.get('/api/v1/friends/pending');
      
      List<dynamic> dataList = [];
      if (response is List) {
        dataList = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        dataList = response['data'] as List<dynamic>;
      }
      
      return dataList.map((json) => FriendRequest.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<FriendRequest>> getSentFriendRequests() async {
    try {
      final response = await _mockApiService.get('/api/v1/friends/sent');
      
      List<dynamic> dataList = [];
      if (response is List) {
        dataList = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        dataList = response['data'] as List<dynamic>;
      }
      
      return dataList.map((json) => FriendRequest.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> sendFriendRequest(String userId, {String? message}) async {
    try {
      final response = await _mockApiService.post('/api/v1/friends/request', data: {
        'userId': userId,
        'message': message,
      });
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '发送好友请求失败');
      }
    } catch (e) {
      throw Exception('发送好友请求失败: $e');
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final response = await _mockApiService.post('/api/v1/friends/accept', data: {
        'requestId': requestId,
      });
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? '接受好友请求失败');
      }
    } catch (e) {
      throw Exception('接受好友请求失败: $e');
    }
  }
}

void main() {
  group('好友请求集成测试', () {
    late MockApiService mockApiService;
    late MockFriendRepository mockRepository;
    late FriendViewModel friendViewModel;
    late NotificationService notificationService;

    setUp(() {
      mockApiService = MockApiService();
      mockRepository = MockFriendRepository(mockApiService);
      notificationService = NotificationService();
      friendViewModel = FriendViewModel(
        friendRepository: mockRepository,
        notificationService: notificationService,
      );
    });

    test('发送好友请求成功流程', () async {
      // 设置mock数据
      mockApiService.setShouldReturnError(false);
      
      // 执行发送好友请求
      await friendViewModel.sendFriendRequest('target-user-123', message: '你好，我想加你为好友');
      
      // 验证状态
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('发送好友请求失败处理', () async {
      // 设置mock返回错误
      mockApiService.setShouldReturnError(true, '网络连接失败');
      
      // 执行发送好友请求并期望抛出异常
      try {
        await friendViewModel.sendFriendRequest('target-user-123');
        fail('应该抛出异常');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('网络连接失败'));
      }
      
      // 验证状态
      expect(friendViewModel.isLoading, isFalse);
    });

    test('获取待处理好友请求 - 空列表', () async {
      // 设置mock返回空列表
      mockApiService.setMockData('/api/v1/friends/pending', []);
      
      // 执行加载好友请求
      await friendViewModel.loadFriendRequests();
      
      // 验证结果
      expect(friendViewModel.pendingFriendRequests, isEmpty);
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('获取待处理好友请求 - 有数据', () async {
      // 设置mock返回测试数据
      final mockRequests = [
        {
          'id': 'request-1',
          'sender_id': 'user-123',
          'receiver_id': 'current-user',
          'message': '你好，我想加你为好友',
          'status': 'pending',
          'type': 'normal',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
        },
        {
          'id': 'request-2',
          'sender_id': 'user-456',
          'receiver_id': 'current-user',
          'message': '互相添加为好友',
          'status': 'pending',
          'type': 'mutual',
          'created_at': '2023-01-02T00:00:00Z',
          'updated_at': '2023-01-02T00:00:00Z',
        },
      ];
      
      mockApiService.setMockData('/api/v1/friends/pending', mockRequests);
      
      // 执行加载好友请求
      await friendViewModel.loadFriendRequests();
      
      // 验证结果
      expect(friendViewModel.pendingFriendRequests.length, 2);
      expect(friendViewModel.pendingFriendRequests[0].id, 'request-1');
      expect(friendViewModel.pendingFriendRequests[0].senderId, 'user-123');
      expect(friendViewModel.pendingFriendRequests[0].status, FriendRequestStatus.pending);
      expect(friendViewModel.pendingFriendRequests[1].type, FriendRequestType.mutual);
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('获取已发送好友请求', () async {
      // 设置mock返回测试数据
      final mockSentRequests = [
        {
          'id': 'sent-request-1',
          'sender_id': 'current-user',
          'receiver_id': 'user-789',
          'message': '请求添加为好友',
          'status': 'pending',
          'type': 'normal',
          'created_at': '2023-01-03T00:00:00Z',
          'updated_at': '2023-01-03T00:00:00Z',
        },
      ];
      
      mockApiService.setMockData('/api/v1/friends/sent', mockSentRequests);
      
      // 执行加载好友请求
      await friendViewModel.loadFriendRequests();
      
      // 验证结果
      expect(friendViewModel.sentFriendRequests.length, 1);
      expect(friendViewModel.sentFriendRequests[0].id, 'sent-request-1');
      expect(friendViewModel.sentFriendRequests[0].receiverId, 'user-789');
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('接受好友请求成功', () async {
      // 设置mock数据
      mockApiService.setShouldReturnError(false);
      
      // 执行接受好友请求
      await friendViewModel.acceptFriendRequest('request-123');
      
      // 验证状态
      expect(friendViewModel.error, isNull);
      expect(friendViewModel.isLoading, isFalse);
    });

    test('接受好友请求失败处理', () async {
      // 设置mock返回错误
      mockApiService.setShouldReturnError(true, '请求已过期');
      
      // 执行接受好友请求并期望抛出异常
      try {
        await friendViewModel.acceptFriendRequest('expired-request');
        fail('应该抛出异常');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('请求已过期'));
      }
      
      // 验证状态
      expect(friendViewModel.isLoading, isFalse);
    });

    test('好友请求数据格式兼容性测试', () async {
      // 测试包装在data字段中的响应格式
      final wrappedResponse = {
        'data': [
          {
            'id': 'wrapped-request-1',
            'sender_id': 'user-111',
            'receiver_id': 'current-user',
            'status': 'pending',
            'type': 'normal',
            'created_at': '2023-01-04T00:00:00Z',
            'updated_at': '2023-01-04T00:00:00Z',
          },
        ],
      };
      
      mockApiService.setMockData('/api/v1/friends/pending', wrappedResponse);
      
      // 执行加载好友请求
      await friendViewModel.loadFriendRequests();
      
      // 验证结果
      expect(friendViewModel.pendingFriendRequests.length, 1);
      expect(friendViewModel.pendingFriendRequests[0].id, 'wrapped-request-1');
      expect(friendViewModel.error, isNull);
    });

    test('网络错误时的错误处理', () async {
      // 设置网络错误
      mockApiService.setShouldReturnError(true, '网络连接超时');
      
      // 执行加载好友请求
      await friendViewModel.loadFriendRequests();
      
      // 验证错误处理
      expect(friendViewModel.pendingFriendRequests, isEmpty);
      expect(friendViewModel.sentFriendRequests, isEmpty);
      expect(friendViewModel.error, isNotNull);
      expect(friendViewModel.error, contains('加载好友请求失败'));
      expect(friendViewModel.isLoading, isFalse);
    });

    test('好友请求状态统计', () async {
      // 设置包含多种状态的测试数据
      final mixedStatusRequests = [
        {
          'id': 'pending-1',
          'sender_id': 'user-1',
          'receiver_id': 'current-user',
          'status': 'pending',
          'type': 'normal',
          'created_at': '2023-01-01T00:00:00Z',
          'updated_at': '2023-01-01T00:00:00Z',
        },
        {
          'id': 'pending-2',
          'sender_id': 'user-2',
          'receiver_id': 'current-user',
          'status': 'pending',
          'type': 'mutual',
          'created_at': '2023-01-02T00:00:00Z',
          'updated_at': '2023-01-02T00:00:00Z',
        },
      ];
      
      mockApiService.setMockData('/api/v1/friends/pending', mixedStatusRequests);
      
      // 执行加载好友请求
      await friendViewModel.loadFriendRequests();
      
      // 验证统计信息
      expect(friendViewModel.pendingRequestsCount, 2);
      expect(friendViewModel.pendingFriendRequests.where((r) => r.type == FriendRequestType.normal).length, 1);
      expect(friendViewModel.pendingFriendRequests.where((r) => r.type == FriendRequestType.mutual).length, 1);
    });
  });
}