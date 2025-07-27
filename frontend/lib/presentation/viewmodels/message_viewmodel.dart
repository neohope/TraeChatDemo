import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/message_model.dart';

class MessageViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;
  final AppLogger _logger = AppLogger.instance;

  // 状态管理
  bool _isLoading = false;
  String? _error;
  
  // 消息数据
  List<MessageModel> _messages = [];
  List<MessageModel> _searchResults = [];
  MessageModel? _selectedMessage;
  
  // 分页
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasMoreMessages = true;
  
  // 输入状态
  final Map<String, bool> _typingUsers = {};
  
  // 未读消息
  final Map<String, int> _unreadCounts = {};
  
  // 流订阅
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  List<MessageModel> get searchResults => List.unmodifiable(_searchResults);
  MessageModel? get selectedMessage => _selectedMessage;
  int get currentPage => _currentPage;
  bool get hasMoreMessages => _hasMoreMessages;
  Map<String, bool> get typingUsers => Map.unmodifiable(_typingUsers);
  Map<String, int> get unreadCounts => Map.unmodifiable(_unreadCounts);
  
  MessageViewModel() {
    _initializeWebSocket();
  }
  
  /// 初始化WebSocket连接
  void _initializeWebSocket() {
    // 监听WebSocket消息
    _messageSubscription = _webSocketService.messageStream.listen(
      _handleWebSocketMessage,
      onError: (error) {
        _logger.error('WebSocket消息流错误: $error');
      },
    );
    
    // 监听连接状态
    _connectionSubscription = _webSocketService.connectionStream.listen(
      (isConnected) {
        if (isConnected) {
          _logger.logger.i('WebSocket已连接，开始同步消息');
        } else {
          _logger.warning('WebSocket连接断开');
        }
      },
    );
  }
  
  /// 处理WebSocket消息
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'];
    final messageData = data['data'];
    
    switch (messageType) {
      case 'chat_message':
        _handleNewMessage(messageData);
        break;
      case 'message_read':
        _handleMessageRead(messageData);
        break;
      case 'message_delivered':
        _handleMessageDelivered(messageData);
        break;
      case 'typing_status':
        _handleTypingStatus(messageData);
        break;
      case 'message_deleted':
        _handleMessageDeleted(messageData);
        break;
      case 'message_updated':
        _handleMessageUpdated(messageData);
        break;
      default:
        _logger.debug('未处理的WebSocket消息类型: $messageType');
    }
  }
  
  /// 处理新消息
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = MessageModel.fromJson(data);
      
      // 添加到消息列表
      _messages.insert(0, message);
      
      // 更新未读计数
      if (!message.isRead) {
        _unreadCounts[message.chatId] = (_unreadCounts[message.chatId] ?? 0) + 1;
      }
      
      notifyListeners();
      _logger.debug('收到新消息: ${message.id}');
    } catch (e) {
      _logger.error('处理新消息失败: $e');
    }
  }
  
  /// 处理消息已读
  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final messageId = data['messageId'];
      final readBy = data['readBy'];
      
      // 更新消息状态
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final updatedMessage = message.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _messages[messageIndex] = updatedMessage;
        notifyListeners();
      }
      
      _logger.debug('消息已读: $messageId by $readBy');
    } catch (e) {
      _logger.error('处理消息已读失败: $e');
    }
  }
  
  /// 处理消息已送达
  void _handleMessageDelivered(Map<String, dynamic> data) {
    try {
      final messageId = data['messageId'];
      
      // 更新消息状态
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final updatedMessage = message.copyWith(
          isDelivered: true,
          deliveredAt: DateTime.now(),
        );
        _messages[messageIndex] = updatedMessage;
        notifyListeners();
      }
      
      _logger.debug('消息已送达: $messageId');
    } catch (e) {
      _logger.error('处理消息已送达失败: $e');
    }
  }
  
  /// 处理输入状态
  void _handleTypingStatus(Map<String, dynamic> data) {
    try {
      final userId = data['userId'];
      final isTyping = data['isTyping'] ?? false;
      
      if (isTyping) {
        _typingUsers[userId] = true;
      } else {
        _typingUsers.remove(userId);
      }
      
      notifyListeners();
      _logger.debug('用户输入状态: $userId - $isTyping');
    } catch (e) {
      _logger.error('处理输入状态失败: $e');
    }
  }
  
  /// 处理消息删除
  void _handleMessageDeleted(Map<String, dynamic> data) {
    try {
      final messageId = data['messageId'];
      
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      
      _logger.debug('消息已删除: $messageId');
    } catch (e) {
      _logger.error('处理消息删除失败: $e');
    }
  }
  
  /// 处理消息更新
  void _handleMessageUpdated(Map<String, dynamic> data) {
    try {
      final updatedMessage = MessageModel.fromJson(data);
      
      final messageIndex = _messages.indexWhere((m) => m.id == updatedMessage.id);
      if (messageIndex != -1) {
        _messages[messageIndex] = updatedMessage;
        notifyListeners();
      }
      
      _logger.debug('消息已更新: ${updatedMessage.id}');
    } catch (e) {
      _logger.error('处理消息更新失败: $e');
    }
  }
  
  /// 加载聊天消息
  Future<void> loadMessages(String chatId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreMessages = true;
      _messages.clear();
    }
    
    if (!_hasMoreMessages) {
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.get(
        '/api/v1/chats/$chatId/messages',
        queryParameters: {
          'page': _currentPage,
          'limit': _pageSize,
        },
      );
      
      final List<dynamic> messageData = response['messages'] ?? [];
      final List<MessageModel> newMessages = messageData
          .map((json) => MessageModel.fromJson(json))
          .toList();
      
      if (refresh) {
        _messages = newMessages;
      } else {
        _messages.addAll(newMessages);
      }
      
      _hasMoreMessages = newMessages.length == _pageSize;
      _currentPage++;
      
      // 加入聊天室
      _webSocketService.joinChat(chatId);
      
      _logger.logger.i('加载消息成功: ${newMessages.length} 条');
    } catch (e) {
      _setError('加载消息失败: $e');
      _logger.error('加载消息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载更多消息
  Future<void> loadMoreMessages(String chatId) async {
    await loadMessages(chatId, refresh: false);
  }

  /// 获取指定聊天的消息列表
  List<MessageModel> getMessagesForChat(String chatId) {
    return _messages;
  }
  
  /// 发送消息
  Future<MessageModel?> sendMessage({
    required String chatId,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
  }) async {
    try {
      // 创建临时消息
      final tempMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: 'current_user', // 应该从用户状态获取
        content: content,
        type: type,
        metadata: metadata,
        attachments: attachments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDelivered: false,
        isRead: false,
      );
      
      // 立即显示在界面上
      _messages.insert(0, tempMessage);
      notifyListeners();
      
      // 通过WebSocket发送
      _webSocketService.sendChatMessage(
        chatId: chatId,
        content: content,
        type: type,
        metadata: {
          ...?metadata,
          'attachments': attachments,
        },
      );
      
      // 同时通过API发送（确保可靠性）
      final response = await _apiService.post(
        '/chats/$chatId/messages',
        data: {
          'content': content,
          'type': type,
          'metadata': metadata,
          'attachments': attachments,
        },
      );
      
      final sentMessage = MessageModel.fromJson(response['message']);
      
      // 替换临时消息
      final tempIndex = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (tempIndex != -1) {
        _messages[tempIndex] = sentMessage;
        notifyListeners();
      }
      
      _logger.logger.i('消息发送成功: ${sentMessage.id}');
      return sentMessage;
    } catch (e) {
      // 移除临时消息
      _messages.removeWhere((m) => m.id.startsWith('temp_'));
      notifyListeners();
      
      _setError('发送消息失败: $e');
      _logger.error('发送消息失败: $e');
      return null;
    }
  }
  
  /// 删除消息
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _apiService.delete('/api/v1/messages/$messageId');
      
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      
      _logger.logger.i('消息删除成功: $messageId');
      return true;
    } catch (e) {
      _setError('删除消息失败: $e');
      _logger.error('删除消息失败: $e');
      return false;
    }
  }
  
  /// 编辑消息
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      final response = await _apiService.put(
        '/api/v1/messages/$messageId',
        data: {'content': newContent},
      );
      
      final updatedMessage = MessageModel.fromJson(response['message']);
      
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = updatedMessage;
        notifyListeners();
      }
      
      _logger.logger.i('消息编辑成功: $messageId');
      return true;
    } catch (e) {
      _setError('编辑消息失败: $e');
      _logger.error('编辑消息失败: $e');
      return false;
    }
  }
  
  /// 标记消息为已读
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _apiService.post('/api/v1/messages/$messageId/read');
      
      // 更新本地状态
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        _messages[messageIndex] = message.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      _logger.debug('消息已标记为已读: $messageId');
    } catch (e) {
      _logger.error('标记消息已读失败: $e');
    }
  }
  
  /// 搜索消息
  Future<void> searchMessages(String query, {String? chatId}) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.get(
        '/api/v1/messages/search',
        queryParameters: {
          'query': query,
          if (chatId != null) 'chatId': chatId,
        },
      );
      
      final List<dynamic> messageData = response['messages'] ?? [];
      _searchResults = messageData
          .map((json) => MessageModel.fromJson(json))
          .toList();
      
      _logger.logger.i('搜索消息成功: ${_searchResults.length} 条结果');
    } catch (e) {
      _setError('搜索消息失败: $e');
      _logger.error('搜索消息失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 发送输入状态
  void sendTypingStatus(String chatId, bool isTyping) {
    _webSocketService.sendTypingStatus(
      chatId: chatId,
      isTyping: isTyping,
    );
  }
  
  /// 获取未读消息数量
  int getUnreadCount(String chatId) {
    return _unreadCounts[chatId] ?? 0;
  }
  
  /// 清除未读计数
  void clearUnreadCount(String chatId) {
    _unreadCounts.remove(chatId);
    notifyListeners();
  }
  
  /// 选择消息
  void selectMessage(MessageModel? message) {
    _selectedMessage = message;
    notifyListeners();
  }
  
  /// 清除搜索结果
  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  /// 清除错误信息
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}