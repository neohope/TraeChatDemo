import 'dart:convert';

import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

/// 会话仓库类，用于管理聊天会话数据的存取
class ConversationRepository {
  // 单例模式
  static final ConversationRepository _instance = ConversationRepository._internal();
  static ConversationRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  ConversationRepository._internal();
  
  /// 获取会话列表
  Future<ApiResponse<List<Conversation>>> getConversations() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/api/v1/conversations');
      
      if (response.success && response.data != null) {
        final conversations = response.data!.map((json) => Conversation.fromJson(json)).toList();
        // 保存到本地存储
        await _saveConversationsToLocal(conversations);
        return ApiResponse<List<Conversation>>.success(conversations);
      } else {
        return ApiResponse<List<Conversation>>.error(response.message ?? '获取会话列表失败');
      }
    } catch (e) {
      _logger.e('获取会话列表失败: $e');
      
      // 尝试从本地获取
      try {
        final localConversationsData = await LocalStorage.getConversations();
        if (localConversationsData.isNotEmpty) {
          final localConversations = localConversationsData
              .map((data) => Conversation.fromJson(Map<String, dynamic>.from(data)))
              .toList();
          return ApiResponse<List<Conversation>>.success(localConversations, message: '从本地存储获取的会话');
        }
      } catch (localError) {
        _logger.e('从本地获取会话失败: $localError');
      }
      
      return ApiResponse<List<Conversation>>.error('获取会话列表失败: $e');
    }
  }
  
  /// 获取单个会话
  Future<ApiResponse<Conversation>> getConversation(String conversationId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/v1/conversations/$conversationId');
      
      if (response.success && response.data != null) {
        final conversation = Conversation.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveConversation(conversation);
        return ApiResponse<Conversation>.success(conversation);
      } else {
        return ApiResponse<Conversation>.error(response.message ?? '获取会话失败');
      }
    } catch (e) {
      _logger.e('获取会话失败: $e');
      
      // 尝试从本地获取
      try {
        final localConversationData = await LocalStorage.getConversation(conversationId);
        if (localConversationData != null) {
          final localConversation = Conversation.fromJson(Map<String, dynamic>.from(localConversationData));
          return ApiResponse<Conversation>.success(localConversation, message: '从本地存储获取的会话');
        }
      } catch (localError) {
        _logger.e('从本地获取会话失败: $localError');
      }
      
      return ApiResponse<Conversation>.error('获取会话失败: $e');
    }
  }
  
  /// 创建或获取单聊会话
  Future<ApiResponse<Conversation>> createOrGetDirectConversation(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/conversations/direct',
        data: {'user_id': userId},
      );
      
      if (response.success && response.data != null) {
        final conversation = Conversation.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveConversation(conversation);
        return ApiResponse<Conversation>.success(conversation);
      } else {
        return ApiResponse<Conversation>.error(response.message ?? '创建会话失败');
      }
    } catch (e) {
      _logger.e('创建单聊会话失败: $e');
      return ApiResponse<Conversation>.error('创建会话失败: $e');
    }
  }
  
  /// 创建或获取群聊会话
  Future<ApiResponse<Conversation>> createOrGetGroupConversation(String groupId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/conversations/group',
        data: {'group_id': groupId},
      );
      
      if (response.success && response.data != null) {
        final conversation = Conversation.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveConversation(conversation);
        return ApiResponse<Conversation>.success(conversation);
      } else {
        return ApiResponse<Conversation>.error(response.message ?? '创建会话失败');
      }
    } catch (e) {
      _logger.e('创建群聊会话失败: $e');
      return ApiResponse<Conversation>.error('创建会话失败: $e');
    }
  }
  
  /// 更新会话（置顶、静音等）
  Future<ApiResponse<Conversation>> updateConversation({
    required String conversationId,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (isPinned != null) data['is_pinned'] = isPinned;
      if (isMuted != null) data['is_muted'] = isMuted;
      if (isArchived != null) data['is_archived'] = isArchived;
      
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/v1/conversations/$conversationId',
        data: data,
      );
      
      if (response.success && response.data != null) {
        final conversation = Conversation.fromJson(response.data!);
        // 更新本地存储
        await LocalStorage.saveConversation(conversation);
        return ApiResponse<Conversation>.success(conversation);
      } else {
        return ApiResponse<Conversation>.error(response.message ?? '更新会话失败');
      }
    } catch (e) {
      _logger.e('更新会话失败: $e');
      return ApiResponse<Conversation>.error('更新会话失败: $e');
    }
  }
  
  /// 删除会话
  Future<ApiResponse<bool>> deleteConversation(String conversationId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/api/v1/conversations/$conversationId',
      );
      
      if (response.success) {
        // 从本地存储中删除
        await LocalStorage.deleteConversation(conversationId);
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('删除会话失败: $e');
      return ApiResponse<bool>.error('删除会话失败: $e');
    }
  }
  
  /// 清除会话未读消息计数
  Future<ApiResponse<bool>> clearUnreadCount(String conversationId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/conversations/$conversationId/read',
      );
      
      if (response.success) {
        // 更新本地存储中的会话未读计数
        final conversation = await LocalStorage.getConversation(conversationId);
        if (conversation != null) {
          final updatedConversation = conversation.copyWith(unreadCount: 0);
          await LocalStorage.saveConversation(updatedConversation);
        }
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('清除会话未读消息计数失败: $e');
      return ApiResponse<bool>.error('清除未读消息计数失败: $e');
    }
  }
  
  /// 将会话保存到本地存储
  Future<void> _saveConversationsToLocal(List<Conversation> conversations) async {
    for (final conversation in conversations) {
      await LocalStorage.saveConversation(conversation);
    }
  }
  
  /// 更新本地会话的最后一条消息
  Future<void> updateConversationLastMessage(String conversationId, dynamic messageData) async {
    try {
      final conversationData = await LocalStorage.getConversation(conversationId);
      if (conversationData != null) {
        // 将JSON数据转换为Conversation对象
        final conversation = Conversation.fromJson(Map<String, dynamic>.from(conversationData));
        
        // 解析消息数据
        final message = messageData is String
            ? jsonDecode(messageData)
            : messageData;
        
        // 更新会话
        final updatedConversation = conversation.copyWith(
          lastMessage: message,
          lastActiveTime: DateTime.now(),
          unreadCount: conversation.unreadCount + 1,
        );
        
        await LocalStorage.saveConversation(updatedConversation);
      }
    } catch (e) {
      _logger.e('更新会话最后一条消息失败: $e');
    }
  }
}