import 'package:flutter/foundation.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';

import '../../core/services/api_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/storage/local_storage.dart';

class ChatViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _webSocketService;
  final AppLogger _logger = AppLogger.instance;

  ChatViewModel(this._apiService, this._webSocketService) {
    _initializeWebSocket();
  }

  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  ConversationModel? _currentConversation;
  bool _isLoading = false;
  String? _error;
  bool _isConnected = false;
  bool _isTyping = false;
  String? _typingUserId;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  ConversationModel? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;
  String? get typingUserId => _typingUserId;

  /// 初始化WebSocket连接
  void _initializeWebSocket() {
    // 监听连接状态变化
    _webSocketService.connectionStream.listen((isConnected) {
      _isConnected = isConnected;
      notifyListeners();
    });

    // 监听新消息
    _webSocketService.messageStream.listen((data) {
      if (data['type'] == 'chat_message') {
        _handleNewMessage(data['data']);
      } else if (data['type'] == 'typing_status') {
        _isTyping = data['data']['isTyping'] ?? false;
        _typingUserId = data['data']['userId'];
        notifyListeners();
      }
    });
  }

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

  /// 加载对话列表
  Future<void> loadConversations() async {
    _setLoading(true);
    _setError(null);

    try {
      // 先从本地存储加载
      final localConversationsData = await LocalStorage.getConversations();
      if (localConversationsData.isNotEmpty) {
        _conversations = localConversationsData
            .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }

      // 从服务器获取最新数据
      final response = await _apiService.get('/api/v1/conversations');
      
      if (response['success'] == true) {
        final dynamic data = response['data'];
        if (data != null && data is List) {
          final List<dynamic> conversationList = data;
          _conversations = conversationList
              .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // 保存到本地存储
          await LocalStorage.saveConversations(_conversations);
          notifyListeners();
        } else {
          // 数据为空或格式不正确，初始化为空列表
          _conversations = [];
          notifyListeners();
          _logger.logger.w('API返回的对话列表数据为空或格式不正确');
        }
      } else {
        _setError(response['message'] ?? '获取对话列表失败');
      }
    } catch (e) {
      _logger.error('加载对话列表失败: $e');
      _setError('加载对话列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 选择对话
  Future<void> selectConversation(String conversationId) async {
    _setLoading(true);
    _setError(null);

    try {
      // 查找对话
      final conversation = _conversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse: () => throw Exception('对话不存在'),
      );

      _currentConversation = conversation;
      
      // 加载消息
      await _loadMessages(conversationId);
      
      // 标记为已读
      await _markAsRead(conversationId);
      
    } catch (e) {
      _logger.error('选择对话失败: $e');
      _setError('选择对话失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载消息
  Future<void> _loadMessages(String conversationId) async {
    try {
      // 先从本地存储加载
      final localMessages = await LocalStorage.getConversation(conversationId);
      if (localMessages != null && localMessages.isNotEmpty) {
        _currentMessages = localMessages;
        notifyListeners();
      }

      // 从服务器获取最新消息
      final response = await _apiService.get('/api/v1/conversations/$conversationId/messages');
      
      if (response['success'] == true) {
        final dynamic data = response['data'];
        if (data != null && data is List) {
          final List<dynamic> messageList = data;
          _currentMessages = messageList
              .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // 保存到本地存储
          await LocalStorage.saveConversations(_currentMessages.map((msg) => msg.toJson()).toList());
          notifyListeners();
        } else {
          // 数据为空或格式不正确，初始化为空列表
          _currentMessages = [];
          notifyListeners();
          _logger.logger.w('API返回的消息列表数据为空或格式不正确');
        }
      }
    } catch (e) {
      _logger.error('加载消息失败: $e');
      throw e;
    }
  }

  /// 发送消息
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final tempMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: '', // 当前用户ID
        receiverId: '', // 接收者ID
        conversationId: conversationId,
        type: MessageType.text,
        text: content,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        metadata: metadata,
      );

      // 立即添加到本地列表
      _currentMessages.add(tempMessage);
      notifyListeners();

      // 发送到服务器
      final response = await _apiService.post('/api/v1/messages', data: {
        'conversationId': conversationId,
        'content': content,
        'type': type,
        'metadata': metadata,
      });

      if (response['success'] == true) {
        final sentMessage = MessageModel.fromJson(response['data'] as Map<String, dynamic>);
        
        // 替换临时消息
        final index = _currentMessages.indexWhere((msg) => msg.id == tempMessage.id);
        if (index != -1) {
          _currentMessages[index] = sentMessage;
        }
        
        // 更新对话列表中的最后一条消息
        _updateConversationLastMessage(conversationId, sentMessage);
        
        // 保存到本地存储
        await LocalStorage.saveConversations(_currentMessages.map((msg) => msg.toJson()).toList());
        
        notifyListeners();
        return true;
      } else {
        // 发送失败，更新消息状态
        final index = _currentMessages.indexWhere((msg) => msg.id == tempMessage.id);
        if (index != -1) {
          _currentMessages[index] = tempMessage.copyWith(status: MessageStatus.failed);
          notifyListeners();
        }
        _setError(response['message'] ?? '发送消息失败');
        return false;
      }
    } catch (e) {
      _logger.error('发送消息失败: $e');
      _setError('发送消息失败: $e');
      return false;
    }
  }

  /// 重新发送失败的消息
  Future<bool> resendMessage(String messageId) async {
    final message = _currentMessages.firstWhere(
      (msg) => msg.id == messageId,
      orElse: () => throw Exception('消息不存在'),
    );

    if (message.status != MessageStatus.failed) {
      return false;
    }

    return await sendMessage(
      conversationId: message.conversationId!,
      content: message.text ?? '',
      type: 'text',
      metadata: message.metadata,
    );
  }

  /// 删除消息
  Future<bool> deleteMessage(String messageId) async {
    try {
      final response = await _apiService.delete('/api/v1/messages/$messageId');
      
      if (response['success'] == true) {
        _currentMessages.removeWhere((msg) => msg.id == messageId);
        
        // 更新本地存储
        if (_currentConversation != null) {
          await LocalStorage.saveConversations(_currentMessages.map((msg) => msg.toJson()).toList());
        }
        
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? '删除消息失败');
        return false;
      }
    } catch (e) {
      _logger.error('删除消息失败: $e');
      _setError('删除消息失败: $e');
      return false;
    }
  }

  /// 创建新对话
  Future<ConversationModel?> createConversation({
    required String participantId,
    String type = 'private',
    String? title,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post('/api/v1/conversations', data: {
        'participantIds': [participantId],
        'type': type,
        'title': title,
      });
      
      if (response['success'] == true) {
        final conversation = ConversationModel.fromJson(response['data']);
        _conversations.insert(0, conversation);
        
        // 保存到本地存储
        await LocalStorage.saveConversations(_conversations);
        
        notifyListeners();
        return conversation;
      } else {
        _setError(response['message'] ?? '创建对话失败');
        return null;
      }
    } catch (e) {
      _logger.error('创建对话失败: $e');
      _setError('创建对话失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 标记消息为已读
  Future<void> _markAsRead(String conversationId) async {
    try {
      await _apiService.put('/api/v1/conversations/$conversationId/read');
      
      // 更新本地对话的未读计数
      final index = _conversations.indexWhere((conv) => conv.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      _logger.error('标记已读失败: $e');
    }
  }

  /// 标记聊天为已读
  Future<void> markChatAsRead(String chatId) async {
    await _markAsRead(chatId);
  }

  /// 处理新收到的消息
  void _handleNewMessage(Map<String, dynamic> messageData) {
    final message = MessageModel.fromJson(messageData);
    // 如果是当前对话的消息，添加到消息列表
    if (_currentConversation?.id == message.conversationId) {
      _currentMessages.add(message);
      // 自动标记为已读
      _markAsRead(message.conversationId!);
    }
    
    // 更新对话列表
    if (message.conversationId != null) {
      _updateConversationLastMessage(message.conversationId!, message);
    }
    
    notifyListeners();
  }

  /// 更新对话的最后一条消息
  void _updateConversationLastMessage(String conversationId, MessageModel message) {
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessageTime: message.timestamp,
        unreadCount: _currentConversation?.id == conversationId ? 0 : 
                    (_conversations[index].unreadCount + 1),
      );
      
      // 将对话移到列表顶部
      final conversation = _conversations.removeAt(index);
      _conversations.insert(0, conversation);
    }
  }

  /// 发送正在输入状态
  void sendTypingStatus(String conversationId, bool typing) {
    try {
      _webSocketService.sendTypingStatus(
        chatId: conversationId,
        isTyping: typing,
      );
    } catch (error) {
      _logger.error('发送输入状态失败: $error');
    }
  }

  /// 连接WebSocket
  Future<void> connect() async {
    await _webSocketService.connect();
  }

  /// 断开WebSocket连接
  void disconnect() {
    _webSocketService.disconnect();
  }

  /// 清除当前对话
  void clearCurrentConversation() {
    _currentConversation = null;
    _currentMessages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}