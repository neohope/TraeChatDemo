import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/domain/viewmodels/conversation_viewmodel.dart';
import 'package:chat_app/data/repositories/conversation_repository.dart';
import 'package:chat_app/data/models/conversation.dart';
import 'package:chat_app/data/models/api_response.dart';
import 'package:chat_app/data/models/user.dart';
import 'package:chat_app/data/models/group.dart';
import 'package:chat_app/data/models/message.dart';
import 'package:chat_app/core/config/app_config.dart';

// Mock实现
class MockConversationRepository implements ConversationRepository {
  bool shouldThrowError = false;
  String? errorMessage;
  List<Conversation> mockConversations = [];
  Conversation? mockCreatedConversation;
  
  @override
  Future<ApiResponse<List<Conversation>>> getConversations() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '网络错误');
    }
    return ApiResponse<List<Conversation>>.success(mockConversations);
  }

  @override
  Future<ApiResponse<Conversation>> getConversation(String conversationId) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '网络错误');
    }
    
    final conversation = mockConversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('会话不存在'),
    );
    
    return ApiResponse<Conversation>.success(conversation);
  }

  @override
  Future<ApiResponse<Conversation>> createOrGetDirectConversation(String userId) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '创建会话失败');
    }
    
    if (mockCreatedConversation != null) {
      return ApiResponse<Conversation>.success(mockCreatedConversation!);
    }
    
    // 创建一个新的单聊会话
    final conversation = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      type: ConversationType.direct,
      title: 'Test User',
      userId: userId,
      lastActiveTime: DateTime.now(),
    );
    
    mockConversations.add(conversation);
    return ApiResponse<Conversation>.success(conversation);
  }

  @override
  Future<ApiResponse<Conversation>> createOrGetGroupConversation(String groupId) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '创建群聊失败');
    }
    
    if (mockCreatedConversation != null) {
      return ApiResponse<Conversation>.success(mockCreatedConversation!);
    }
    
    // 创建一个新的群聊会话
    final conversation = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      type: ConversationType.group,
      title: 'Test Group',
      groupId: groupId,
      lastActiveTime: DateTime.now(),
    );
    
    mockConversations.add(conversation);
    return ApiResponse<Conversation>.success(conversation);
  }

  @override
  Future<void> saveConversationsToLocal(List<Conversation> conversations) async {
    // Mock实现，不做实际保存
  }

  @override
  Future<List<Conversation>> getConversationsFromLocal() async {
    return mockConversations;
  }

  @override
  Future<void> saveConversationToLocal(Conversation conversation) async {
    // Mock实现，不做实际保存
  }

  @override
  Future<Conversation?> getConversationFromLocal(String conversationId) async {
    try {
      return mockConversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteConversationFromLocal(String conversationId) async {
    mockConversations.removeWhere((c) => c.id == conversationId);
  }

  @override
  Future<void> clearLocalConversations() async {
    mockConversations.clear();
  }

  @override
  Future<ApiResponse<bool>> deleteConversation(String conversationId) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '删除会话失败');
    }
    
    mockConversations.removeWhere((c) => c.id == conversationId);
    return ApiResponse<bool>.success(true);
  }

  @override
  Future<ApiResponse<bool>> clearUnreadCount(String conversationId) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '清除未读计数失败');
    }
    
    final index = mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      mockConversations[index] = mockConversations[index].copyWith(unreadCount: 0);
    }
    return ApiResponse<bool>.success(true);
  }

  @override
  Future<ApiResponse<Conversation>> updateConversation({
    required String conversationId,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
  }) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '更新会话失败');
    }
    
    final index = mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = mockConversations[index];
      final updatedConversation = conversation.copyWith(
        isPinned: isPinned ?? conversation.isPinned,
        isMuted: isMuted ?? conversation.isMuted,
        isArchived: isArchived ?? conversation.isArchived,
      );
      mockConversations[index] = updatedConversation;
      return ApiResponse<Conversation>.success(updatedConversation);
    }
    
    throw Exception('会话不存在');
  }

  @override
  Future<void> updateConversationLastMessage(String conversationId, dynamic messageData) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? '更新最后消息失败');
    }
    
    final index = mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      mockConversations[index] = mockConversations[index].copyWith(
        lastActiveTime: DateTime.now(),
      );
    }
  }

  // 静态实例（为了兼容单例模式）
  static MockConversationRepository? _instance;
  static MockConversationRepository get instance {
    _instance ??= MockConversationRepository();
    return _instance!;
  }
}

void main() {
  group('ConversationViewModel Tests', () {
    late ConversationViewModel viewModel;
    late MockConversationRepository mockRepository;

    setUpAll(() async {
      // 初始化应用配置
      AppConfig.instance.apiBaseUrl = 'http://localhost:8080';
      AppConfig.instance.wsBaseUrl = 'ws://localhost:8080/ws';
      AppConfig.instance.isDebug = true;
      AppConfig.instance.defaultLanguage = 'zh';
      AppConfig.instance.connectionTimeout = 30000;
      AppConfig.instance.receiveTimeout = 30000;
      AppConfig.instance.encryptionEnabled = false;
      AppConfig.instance.pushNotificationConfig = {};
    });

    setUp(() {
      mockRepository = MockConversationRepository();
      // 注意：这里需要修改ConversationViewModel来接受repository参数
      // 或者使用依赖注入框架
      viewModel = ConversationViewModel(autoLoad: false);
      // 注入mock repository
      viewModel.setRepository(mockRepository);
    });

    tearDown(() {
      mockRepository.mockConversations.clear();
      mockRepository.shouldThrowError = false;
      mockRepository.errorMessage = null;
      mockRepository.mockCreatedConversation = null;
    });

    group('创建单聊会话测试', () {
      test('成功创建单聊会话', () async {
        // Arrange
        const userId = 'user123';
        final expectedConversation = Conversation(
          id: 'conv_123',
          type: ConversationType.direct,
          title: 'Test User',
          userId: userId,
          lastActiveTime: DateTime.now(),
        );
        
        mockRepository.mockCreatedConversation = expectedConversation;

        // Act
        final result = await viewModel.createOrGetUserConversation(userId);

        // Assert
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('conv_123'));
        expect(result.data!.type, equals(ConversationType.direct));
        expect(result.data!.userId, equals(userId));
        expect(viewModel.conversations.length, equals(1));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNull);
      });

      test('创建单聊会话失败 - 网络错误', () async {
        // Arrange
        const userId = 'user123';
        mockRepository.shouldThrowError = true;
        mockRepository.errorMessage = '网络连接失败';

        // Act
        final result = await viewModel.createOrGetUserConversation(userId);

        // Assert
        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.message, contains('创建会话失败'));
        expect(viewModel.conversations.length, equals(0));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNotNull);
      });

      test('创建单聊会话 - 用户ID为空', () async {
        // Act
        final result = await viewModel.createOrGetUserConversation('');

        // Assert
        expect(result.success, isFalse);
        expect(viewModel.errorMessage, isNotNull);
      });

      test('创建单聊会话 - 会话已存在时更新', () async {
        // Arrange
        const userId = 'user123';
        final existingConversation = Conversation(
          id: 'conv_123',
          type: ConversationType.direct,
          title: 'Old Title',
          userId: userId,
          lastActiveTime: DateTime.now().subtract(const Duration(hours: 1)),
        );
        
        final updatedConversation = Conversation(
          id: 'conv_123',
          type: ConversationType.direct,
          title: 'Updated Title',
          userId: userId,
          lastActiveTime: DateTime.now(),
        );
        
        // 先添加一个已存在的会话
        viewModel.conversations.add(existingConversation);
        mockRepository.mockCreatedConversation = updatedConversation;

        // Act
        final result = await viewModel.createOrGetUserConversation(userId);

        // Assert
        expect(result.success, isTrue);
        expect(viewModel.conversations.length, equals(1));
        expect(viewModel.conversations.first.title, equals('Updated Title'));
      });
    });

    group('加载会话列表测试', () {
      test('成功加载会话列表', () async {
        // Arrange
        final mockConversations = [
          Conversation(
            id: 'conv_1',
            type: ConversationType.direct,
            title: 'User 1',
            userId: 'user1',
            lastActiveTime: DateTime.now(),
          ),
          Conversation(
            id: 'conv_2',
            type: ConversationType.group,
            title: 'Group 1',
            groupId: 'group1',
            lastActiveTime: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ];
        
        mockRepository.mockConversations = mockConversations;

        // Act
        await viewModel.loadConversations();

        // Assert
        expect(viewModel.conversations.length, equals(2));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNull);
        // 验证排序（最新的在前面）
        expect(viewModel.conversations.first.id, equals('conv_1'));
      });

      test('加载会话列表失败', () async {
        // Arrange
        mockRepository.shouldThrowError = true;
        mockRepository.errorMessage = '服务器错误';

        // Act
        await viewModel.loadConversations();

        // Assert
        expect(viewModel.conversations.length, equals(0));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNotNull);
      });
    });

    group('会话选择测试', () {
      test('选择会话', () {
        // Arrange
        final conversation = Conversation(
          id: 'conv_1',
          type: ConversationType.direct,
          title: 'Test User',
          userId: 'user1',
          lastActiveTime: DateTime.now(),
          unreadCount: 5,
        );
        
        viewModel.conversations.add(conversation);

        // Act
        viewModel.selectConversation(conversation);

        // Assert
        expect(viewModel.selectedConversation, equals(conversation));
        expect(viewModel.selectedConversation!.unreadCount, equals(0)); // 应该清除未读计数
      });
    });

    group('会话搜索测试', () {
      test('搜索会话 - 按标题搜索', () async {
        // Arrange
        final conversations = [
          Conversation(
            id: 'conv_1',
            type: ConversationType.direct,
            title: 'Alice',
            userId: 'user1',
            lastActiveTime: DateTime.now(),
          ),
          Conversation(
            id: 'conv_2',
            type: ConversationType.direct,
            title: 'Bob',
            userId: 'user2',
            lastActiveTime: DateTime.now(),
          ),
        ];
        
        viewModel.conversations.addAll(conversations);

        // Act
        await viewModel.searchConversations('Alice');

        // Assert
        expect(viewModel.searchResults.length, equals(1));
        expect(viewModel.searchResults.first.title, equals('Alice'));
      });

      test('搜索会话 - 空查询', () async {
        // Act
        await viewModel.searchConversations('');

        // Assert
        expect(viewModel.searchResults.length, equals(0));
      });
    });

    group('状态管理测试', () {
      test('加载状态正确切换', () async {
        // Arrange
        bool loadingStateChanged = false;
        viewModel.addListener(() {
          if (viewModel.isLoading) {
            loadingStateChanged = true;
          }
        });

        // Act
        await viewModel.loadConversations();

        // Assert
        expect(loadingStateChanged, isTrue);
        expect(viewModel.isLoading, isFalse);
      });

      test('错误状态正确设置', () async {
        // Arrange
        mockRepository.shouldThrowError = true;
        mockRepository.errorMessage = '测试错误';

        // Act
        await viewModel.createOrGetUserConversation('user123');

        // Assert
        expect(viewModel.errorMessage, isNotNull);
        expect(viewModel.errorMessage, contains('测试错误'));
      });
    });
  });
}