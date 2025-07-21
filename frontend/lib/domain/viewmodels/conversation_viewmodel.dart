import 'package:flutter/foundation.dart';

import '../../data/models/api_response.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/repositories/conversation_repository.dart';
import '../models/conversation_model.dart';

/// 会话视图模型，用于管理会话相关的UI状态和业务逻辑
class ConversationViewModel extends ChangeNotifier {
  // 会话仓库实例
  final _conversationRepository = ConversationRepository.instance;
  
  // 会话列表
  List<Conversation> _conversations = [];
  // 搜索结果
  List<Conversation> _searchResults = [];
  // 当前选中的会话
  Conversation? _selectedConversation;
  
  // 加载状态
  bool _isLoading = false;
  // 错误信息
  String? _errorMessage;
  
  /// 获取会话列表
  List<Conversation> get conversations => _conversations;
  
  /// 获取会话模型列表（用于UI显示）
  List<ConversationModel> get conversationModels => _conversations.map((c) => convertToConversationModel(c)).toList();
  
  /// 获取搜索结果
  List<Conversation> get searchResults => _searchResults;
  
  /// 获取搜索结果模型列表（用于UI显示）
  List<ConversationModel> get searchResultModels => _searchResults.map((c) => convertToConversationModel(c)).toList();
  
  /// 获取当前选中的会话
  Conversation? get selectedConversation => _selectedConversation;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 获取错误信息（兼容旧代码）
  String? get error => _errorMessage;
  
  /// 获取总未读消息数
  int get totalUnreadCount => _conversations.fold(0, (sum, conversation) => sum + conversation.unreadCount);
  
  /// 将 Conversation 转换为 ConversationModel
  ConversationModel convertToConversationModel(Conversation conversation) {
    // 确定是否为群聊
    bool isGroup = conversation.type == ConversationType.group;
    
    // 获取参与者ID列表
    List<String>? participantIds;
    if (isGroup && conversation.group != null && conversation.group!.members != null) {
      participantIds = conversation.group!.members!.map((member) => member.userId).toList();
    }
    
    // 创建 ConversationModel
    return ConversationModel(
      id: conversation.id,
      name: conversation.title,
      avatarUrl: conversation.avatarUrl,
      isGroup: isGroup,
      participantId: isGroup ? null : conversation.userId,
      participantIds: participantIds,
      lastMessage: conversation.lastMessage?.content,
      lastMessageType: conversation.lastMessage?.type == MessageType.text ? MessageType.text : MessageType.image,
      lastMessageTime: conversation.lastActiveTime,
      unreadCount: conversation.unreadCount,
      isPinned: conversation.isPinned,
      isMuted: conversation.isMuted,
      isArchived: conversation.isArchived,
      isOnline: !isGroup && conversation.user?.status == UserStatus.online,
      participantStatus: !isGroup ? conversation.user?.status : null,
      lastMessageSenderId: conversation.lastMessage?.senderId,
    );
  }
  
  /// 获取当前用户ID (需要从认证服务获取)
  String? get currentUserId {
    // 这里应该从AuthViewModel或UserViewModel获取当前用户ID
    // 暂时返回null，需要在使用时进行适当的处理
    return null;
  }
  
  /// 构造函数
  ConversationViewModel() {
    // 初始化加载会话列表
    loadConversations();
  }
  
  /// 搜索会话
  Future<void> searchConversations(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    
    try {
      // 在本地会话列表中搜索
      _searchResults = _conversations.where((conversation) {
        return conversation.title.toLowerCase().contains(query.toLowerCase()) ||
               (conversation.lastMessage?.content.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _searchResults = [];
      _setError('搜索失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 清除搜索结果
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// 加载会话列表
  Future<void> loadConversations({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _conversationRepository.getConversations();
      
      if (response.success && response.data != null) {
        _conversations = response.data!;
        // 按最后活跃时间排序
        _conversations.sort((a, b) => b.lastActiveTime.compareTo(a.lastActiveTime));
        notifyListeners();
      } else {
        _setError(response.message ?? '加载会话列表失败');
      }
    } catch (e) {
      _setError('加载会话列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 获取会话详情
  Future<ApiResponse<Conversation>> getConversation(String conversationId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _conversationRepository.getConversation(conversationId);
      
      if (response.success && response.data != null) {
        // 更新本地会话列表
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          _conversations[index] = response.data!;
        } else {
          _conversations.add(response.data!);
          // 按最后活跃时间排序
          _conversations.sort((a, b) => b.lastActiveTime.compareTo(a.lastActiveTime));
        }
        notifyListeners();
      } else {
        _setError(response.message ?? '获取会话详情失败');
      }
      
      return response;
    } catch (e) {
      _setError('获取会话详情失败: $e');
      return ApiResponse<Conversation>.error('获取会话详情失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 创建或获取单聊会话
  Future<ApiResponse<Conversation>> createOrGetUserConversation(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _conversationRepository.createOrGetDirectConversation(userId);
      
      if (response.success && response.data != null) {
        // 检查会话是否已存在于列表中
        final index = _conversations.indexWhere((c) => c.id == response.data!.id);
        if (index != -1) {
          _conversations[index] = response.data!;
        } else {
          _conversations.add(response.data!);
          // 按最后活跃时间排序
          _conversations.sort((a, b) => b.lastActiveTime.compareTo(a.lastActiveTime));
        }
        notifyListeners();
      } else {
        _setError(response.message ?? '创建会话失败');
      }
      
      return response;
    } catch (e) {
      _setError('创建会话失败: $e');
      return ApiResponse<Conversation>.error('创建会话失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 创建或获取群聊会话
  Future<ApiResponse<Conversation>> createOrGetGroupConversation(String groupId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _conversationRepository.createOrGetGroupConversation(groupId);
      
      if (response.success && response.data != null) {
        // 检查会话是否已存在于列表中
        final index = _conversations.indexWhere((c) => c.id == response.data!.id);
        if (index != -1) {
          _conversations[index] = response.data!;
        } else {
          _conversations.add(response.data!);
          // 按最后活跃时间排序
          _conversations.sort((a, b) => b.lastActiveTime.compareTo(a.lastActiveTime));
        }
        notifyListeners();
      } else {
        _setError(response.message ?? '创建群聊会话失败');
      }
      
      return response;
    } catch (e) {
      _setError('创建群聊会话失败: $e');
      return ApiResponse<Conversation>.error('创建群聊会话失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 选择会话
  void selectConversation(Conversation conversation) {
    _selectedConversation = conversation;
    notifyListeners();
    
    // 标记会话为已读
    if (conversation.unreadCount > 0) {
      clearUnreadCount(conversation.id);
    }
  }
  
  /// 选择会话（接受 ConversationModel 类型）
  void selectConversationByModel(ConversationModel conversationModel) {
    // 尝试查找对应的 Conversation 对象
    try {
      final conversation = _conversations.firstWhere(
        (c) => c.id == conversationModel.id,
      );
      
      _selectedConversation = conversation;
      notifyListeners();
      
      // 标记会话为已读
      if (conversation.unreadCount > 0) {
        clearUnreadCount(conversation.id);
      }
    } catch (e) {
      // 如果找不到对应的会话，则不执行任何操作
      print('找不到ID为 ${conversationModel.id} 的会话');
    }
  }
  
  /// 切换会话置顶状态
  Future<ApiResponse<Conversation>> togglePinConversation(String conversationId) async {
    final conversation = _conversations.firstWhere((c) => c.id == conversationId);
    return updateConversation(conversationId, isPinned: !conversation.isPinned);
  }
  
  /// 切换会话静音状态
  Future<ApiResponse<Conversation>> toggleMuteConversation(String conversationId) async {
    final conversation = _conversations.firstWhere((c) => c.id == conversationId);
    return updateConversation(conversationId, isMuted: !conversation.isMuted);
  }
  
  /// 切换会话归档状态
  Future<ApiResponse<Conversation>> toggleArchiveConversation(String conversationId) async {
    final conversation = _conversations.firstWhere((c) => c.id == conversationId);
    return updateConversation(conversationId, isArchived: !conversation.isArchived);
  }
  
  /// 更新会话（置顶、静音等）
  Future<ApiResponse<Conversation>> updateConversation(String conversationId, {
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
  }) async {
    try {
      final response = await _conversationRepository.updateConversation(
        conversationId: conversationId,
        isPinned: isPinned,
        isMuted: isMuted,
        isArchived: isArchived,
      );
      
      if (response.success && response.data != null) {
        // 更新本地会话
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          _conversations[index] = response.data!;
          
          // 如果更新的是当前选中的会话，也更新选中的会话
          if (_selectedConversation?.id == conversationId) {
            _selectedConversation = response.data!;
          }
          
          // 如果是置顶状态变更，需要重新排序
          if (isPinned != null) {
            _sortConversations();
          }
          
          notifyListeners();
        }
      } else {
        _setError(response.message ?? '更新会话失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新会话失败: $e');
      return ApiResponse<Conversation>.error('更新会话失败: $e');
    }
  }
  
  /// 删除会话
  Future<ApiResponse<bool>> deleteConversation(String conversationId) async {
    try {
      final response = await _conversationRepository.deleteConversation(conversationId);
      
      if (response.success) {
        // 从本地列表中删除
        _conversations.removeWhere((c) => c.id == conversationId);
        
        // 如果删除的是当前选中的会话，清除选中状态
        if (_selectedConversation?.id == conversationId) {
          _selectedConversation = null;
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '删除会话失败');
      }
      
      return response;
    } catch (e) {
      _setError('删除会话失败: $e');
      return ApiResponse<bool>.error('删除会话失败: $e');
    }
  }
  
  /// 清除会话未读消息计数
  Future<ApiResponse<bool>> clearUnreadCount(String conversationId) async {
    try {
      final response = await _conversationRepository.clearUnreadCount(conversationId);
      
      if (response.success) {
        // 更新本地会话未读计数
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
          
          // 如果是当前选中的会话，也更新选中的会话
          if (_selectedConversation?.id == conversationId) {
            _selectedConversation = _selectedConversation!.copyWith(unreadCount: 0);
          }
          
          notifyListeners();
        }
      } else {
        _setError(response.message ?? '清除未读消息计数失败');
      }
      
      return response;
    } catch (e) {
      _setError('清除未读消息计数失败: $e');
      return ApiResponse<bool>.error('清除未读消息计数失败: $e');
    }
  }
  
  /// 更新会话的最后一条消息
  void updateLastMessage(String conversationId, String lastMessageContent, DateTime timestamp) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      // 创建一个新的 Message 对象
      final lastMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_user', // 假设是当前用户发送的
        content: lastMessageContent,
        type: MessageType.text,
        status: MessageStatus.sent,
        createdAt: timestamp,
      );
      
      // 更新最后一条消息和时间
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: lastMessage,
        lastActiveTime: timestamp,
      );
      
      // 如果不是当前选中的会话，增加未读计数
      if (_selectedConversation?.id != conversationId) {
        _conversations[index] = _conversations[index].copyWith(
          unreadCount: _conversations[index].unreadCount + 1,
        );
      }
      
      // 重新排序会话列表
      _sortConversations();
      
      notifyListeners();
    }
  }
  
  /// 对会话列表进行排序
  void _sortConversations() {
    // 首先按照置顶状态排序，然后按照最后活跃时间排序
    _conversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.lastActiveTime.compareTo(a.lastActiveTime);
    });
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
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