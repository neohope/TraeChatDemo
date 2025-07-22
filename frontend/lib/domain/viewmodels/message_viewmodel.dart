import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/network/websocket_client.dart' show WebSocketStatus;
import '../../data/models/api_response.dart';
import '../../data/models/message.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/services/websocket_service.dart';
import '../../domain/models/conversation_model.dart' show MessageStatus, MessageType;

/// 消息视图模型，用于管理消息相关的UI状态和业务逻辑
class MessageViewModel extends ChangeNotifier {
  // 消息仓库实例
  final _messageRepository = MessageRepository.instance;
  // WebSocket服务实例
  final _webSocketService = WebSocketService.instance;
  
  // 单聊消息映射表，键为用户ID，值为消息列表
  final Map<String, List<Message>> _userMessages = {};
  // 群聊消息映射表，键为群组ID，值为消息列表
  final Map<String, List<Message>> _groupMessages = {};
  
  // 当前选中的聊天ID（用户ID或群组ID）
  String? _selectedChatId;
  // 当前聊天是否为群聊
  bool _isGroupChat = false;
  
  // 加载状态
  bool _isLoading = false;
  // 是否正在发送消息
  bool _isSending = false;
  // 错误信息
  String? _errorMessage;
  
  /// 获取单聊消息映射表
  Map<String, List<Message>> get userMessages => _userMessages;
  
  /// 获取群聊消息映射表
  Map<String, List<Message>> get groupMessages => _groupMessages;
  
  /// 获取当前选中的聊天ID
  String? get selectedChatId => _selectedChatId;
  
  /// 当前聊天是否为群聊
  bool get isGroupChat => _isGroupChat;
  
  /// 获取当前聊天的消息列表
  List<Message> get currentMessages {
    if (_selectedChatId == null) return [];
    
    return _isGroupChat
        ? _groupMessages[_selectedChatId] ?? []
        : _userMessages[_selectedChatId] ?? [];
  }
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 是否正在发送消息
  bool get isSending => _isSending;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 构造函数
  MessageViewModel() {
    // 初始化WebSocket连接
    _initWebSocket();
  }
  
  /// 初始化WebSocket连接
  void _initWebSocket() {
    // 监听消息事件
    _webSocketService.messageStream.listen(_handleWebSocketMessage);
    
    // 监听连接状态
    _webSocketService.connectionStatusStream.listen((status) {
      // 可以在这里处理连接状态变化
      if (status == WebSocketStatus.disconnected) {
        // 尝试重新连接
        _webSocketService.resetConnection();
      }
    });
    
    // 连接WebSocket
    if (_webSocketService.connectionStatus != WebSocketStatus.connected) {
      _webSocketService.connect();
    }
  }
  
  /// 处理WebSocket消息
  void _handleWebSocketMessage(Message message) {
    try {
      // 根据消息类型添加到对应的消息列表
      if (message.isGroupMessage && message.groupId != null) {
        final String groupId = message.groupId!;
        _groupMessages[groupId] = [...(_groupMessages[groupId] ?? []), message];
      } else if (message.receiverId != null) {
        final String userId = message.senderId == _selectedChatId
            ? message.senderId
            : message.receiverId!;
        _userMessages[userId] = [...(_userMessages[userId] ?? []), message];
      }
      
      notifyListeners();
    } catch (e) {
      _setError('处理WebSocket消息失败: $e');
    }
  }
  
  /// 设置当前选中的聊天
  void selectChat(String chatId, {bool isGroup = false}) {
    _selectedChatId = chatId;
    _isGroupChat = isGroup;
    notifyListeners();
    
    // 加载历史消息
    if (isGroup) {
      loadGroupMessages(chatId);
    } else {
      loadUserMessages(chatId);
    }
  }
  
  /// 加载单聊历史消息
  Future<void> loadUserMessages(String userId) async {
    if (_userMessages.containsKey(userId) && _userMessages[userId]!.isNotEmpty) {
      // 如果已经有消息，则不重新加载
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _messageRepository.getDirectMessages(userId);
      
      if (response.success && response.data != null) {
        _userMessages[userId] = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载消息失败');
      }
    } catch (e) {
      _setError('加载消息失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载群聊历史消息
  Future<void> loadGroupMessages(String groupId) async {
    if (_groupMessages.containsKey(groupId) && _groupMessages[groupId]!.isNotEmpty) {
      // 如果已经有消息，则不重新加载
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _messageRepository.getGroupMessages(groupId);
      
      if (response.success && response.data != null) {
        _groupMessages[groupId] = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载消息失败');
      }
    } catch (e) {
      _setError('加载消息失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载消息历史
  /// 
  /// 根据用户ID加载单聊消息历史
  Future<void> loadMessages(String userId) async {
    // 选择聊天对象
    selectChat(userId, isGroup: false);
  }
  
  /// 标记消息为已读
  /// 
  /// 将与指定用户的所有未读消息标记为已读
  Future<void> markMessagesAsRead(String userId) async {
    // 获取与该用户的消息列表
    final messages = _userMessages[userId] ?? [];
    
    // 找出所有未读消息
    final unreadMessages = messages.where((msg) => 
      msg.receiverId == userId && msg.status == MessageStatus.delivered).toList();
    
    if (unreadMessages.isEmpty) return;
    
    try {
      // 更新消息状态
      for (final message in unreadMessages) {
        // 在本地更新消息状态
        final updatedMessage = message.copyWith(status: MessageStatus.read);
        
        // 更新消息列表
        final index = messages.indexWhere((msg) => msg.id == message.id);
        if (index != -1) {
          messages[index] = updatedMessage;
        }
      }
      
      // 更新消息列表
      _userMessages[userId] = messages;
      notifyListeners();
      
      // 向服务器发送已读回执
      // 这里可以调用API将消息标记为已读
      // await _messageRepository.markMessagesAsRead(userId, unreadMessages.map((msg) => msg.id).toList());
    } catch (e) {
      _setError('标记消息为已读失败: $e');
    }
  }
  
  /// 获取与指定用户的消息列表
  List<Message> getMessagesForUser(String userId) {
    return _userMessages[userId] ?? [];
  }
  
  /// 加载更多历史消息
  /// 
  /// 如果提供了userId，则加载该用户的更多消息
  /// 否则加载当前选中聊天的更多消息
  Future<void> loadMoreMessages([String? userId]) async {
    // 如果提供了userId，则临时设置为当前选中的聊天
    final String? originalSelectedChatId = _selectedChatId;
    final bool originalIsGroupChat = _isGroupChat;
    
    if (userId != null) {
      _selectedChatId = userId;
      _isGroupChat = false;
    }
    
    if (_selectedChatId == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final currentList = _isGroupChat
          ? _groupMessages[_selectedChatId] ?? []
          : _userMessages[_selectedChatId] ?? [];
      
      if (currentList.isEmpty) return;
      
      // 获取最早消息的时间戳作为分页标记
      final oldestMessageId = currentList.first.id;
      
      final response = _isGroupChat
          ? await _messageRepository.getGroupMessages(
              _selectedChatId!,
              lastMessageId: oldestMessageId,
            )
          : await _messageRepository.getDirectMessages(
              _selectedChatId!,
              lastMessageId: oldestMessageId,
            );
      
      if (response.success && response.data != null) {
        // 将新加载的消息添加到列表前面
        if (_isGroupChat) {
          _groupMessages[_selectedChatId!] = [
            ...response.data!,
            ...(_groupMessages[_selectedChatId!] ?? []),
          ];
        } else {
          _userMessages[_selectedChatId!] = [
            ...response.data!,
            ...(_userMessages[_selectedChatId!] ?? []),
          ];
        }
        notifyListeners();
      } else {
        _setError(response.message ?? '加载更多消息失败');
      }
    } catch (e) {
      _setError('加载更多消息失败: $e');
    } finally {
      _setLoading(false);
      
      // 如果提供了userId，则恢复原始的选中聊天状态
      if (userId != null) {
        _selectedChatId = originalSelectedChatId;
        _isGroupChat = originalIsGroupChat;
      }
    }
  }
  
  /// 发送文本消息
  Future<ApiResponse<Message>> sendTextMessage(String content) async {
    if (_selectedChatId == null) {
      return ApiResponse<Message>.error('未选择聊天对象');
    }
    
    _setSending(true);
    _clearError();
    
    try {
      final response = _isGroupChat
          ? await _webSocketService.sendGroupTextMessage(_selectedChatId!, content)
          : await _webSocketService.sendDirectTextMessage(_selectedChatId!, content);
      
      if (response.success && response.data != null) {
        // 将新消息添加到列表
        final message = response.data!;
        
        if (_isGroupChat) {
          _groupMessages[_selectedChatId!] = [
            ...(_groupMessages[_selectedChatId!] ?? []),
            message,
          ];
        } else {
          _userMessages[_selectedChatId!] = [
            ...(_userMessages[_selectedChatId!] ?? []),
            message,
          ];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '发送消息失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送消息失败: $e');
      return ApiResponse<Message>.error('发送消息失败: $e');
    } finally {
      _setSending(false);
    }
  }
  
  /// 发送图片消息
  Future<ApiResponse<Message>> sendImageMessage(File imageFile) async {
    if (_selectedChatId == null) {
      return ApiResponse<Message>.error('未选择聊天对象');
    }
    
    _setSending(true);
    _clearError();
    
    try {
      final response = _isGroupChat
          ? await _webSocketService.sendGroupMediaMessage(
              groupId: _selectedChatId!,
              file: imageFile,
              type: MessageType.image,
            )
          : await _webSocketService.sendDirectMediaMessage(
              receiverId: _selectedChatId!,
              file: imageFile,
              type: MessageType.image,
            );
      
      if (response.success && response.data != null) {
        // 将新消息添加到列表
        final message = response.data!;
        
        if (_isGroupChat) {
          _groupMessages[_selectedChatId!] = [
            ...(_groupMessages[_selectedChatId!] ?? []),
            message,
          ];
        } else {
          _userMessages[_selectedChatId!] = [
            ...(_userMessages[_selectedChatId!] ?? []),
            message,
          ];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '发送图片失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送图片失败: $e');
      return ApiResponse<Message>.error('发送图片失败: $e');
    } finally {
      _setSending(false);
    }
  }
  
  /// 发送语音消息
  Future<ApiResponse<Message>> sendVoiceMessage(File voiceFile) async {
    if (_selectedChatId == null) {
      return ApiResponse<Message>.error('未选择聊天对象');
    }
    
    _setSending(true);
    _clearError();
    
    try {
      final response = _isGroupChat
          ? await _webSocketService.sendGroupMediaMessage(
              groupId: _selectedChatId!,
              file: voiceFile,
              type: MessageType.voice,
            )
          : await _webSocketService.sendDirectMediaMessage(
              receiverId: _selectedChatId!,
              file: voiceFile,
              type: MessageType.voice,
            );
      
      if (response.success && response.data != null) {
        // 将新消息添加到列表
        final message = response.data!;
        
        if (_isGroupChat) {
          _groupMessages[_selectedChatId!] = [
            ...(_groupMessages[_selectedChatId!] ?? []),
            message,
          ];
        } else {
          _userMessages[_selectedChatId!] = [
            ...(_userMessages[_selectedChatId!] ?? []),
            message,
          ];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '发送语音失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送语音失败: $e');
      return ApiResponse<Message>.error('发送语音失败: $e');
    } finally {
      _setSending(false);
    }
  }
  
  /// 发送视频消息
  Future<ApiResponse<Message>> sendVideoMessage(File videoFile) async {
    if (_selectedChatId == null) {
      return ApiResponse<Message>.error('未选择聊天对象');
    }
    
    _setSending(true);
    _clearError();
    
    try {
      final response = _isGroupChat
          ? await _webSocketService.sendGroupMediaMessage(
              groupId: _selectedChatId!,
              file: videoFile,
              type: MessageType.video,
            )
          : await _webSocketService.sendDirectMediaMessage(
              receiverId: _selectedChatId!,
              file: videoFile,
              type: MessageType.video,
            );
      
      if (response.success && response.data != null) {
        // 将新消息添加到列表
        final message = response.data!;
        
        if (_isGroupChat) {
          _groupMessages[_selectedChatId!] = [
            ...(_groupMessages[_selectedChatId!] ?? []),
            message,
          ];
        } else {
          _userMessages[_selectedChatId!] = [
            ...(_userMessages[_selectedChatId!] ?? []),
            message,
          ];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '发送视频失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送视频失败: $e');
      return ApiResponse<Message>.error('发送视频失败: $e');
    } finally {
      _setSending(false);
    }
  }
  
  /// 发送文件消息
  Future<ApiResponse<Message>> sendFileMessage(File file) async {
    if (_selectedChatId == null) {
      return ApiResponse<Message>.error('未选择聊天对象');
    }
    
    _setSending(true);
    _clearError();
    
    try {
      final response = _isGroupChat
          ? await _webSocketService.sendGroupMediaMessage(
              groupId: _selectedChatId!,
              file: file,
              type: MessageType.file,
            )
          : await _webSocketService.sendDirectMediaMessage(
              receiverId: _selectedChatId!,
              file: file,
              type: MessageType.file,
            );
      
      if (response.success && response.data != null) {
        // 将新消息添加到列表
        final message = response.data!;
        
        if (_isGroupChat) {
          _groupMessages[_selectedChatId!] = [
            ...(_groupMessages[_selectedChatId!] ?? []),
            message,
          ];
        } else {
          _userMessages[_selectedChatId!] = [
            ...(_userMessages[_selectedChatId!] ?? []),
            message,
          ];
        }
        
        notifyListeners();
      } else {
        _setError(response.message ?? '发送文件失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送文件失败: $e');
      return ApiResponse<Message>.error('发送文件失败: $e');
    } finally {
      _setSending(false);
    }
  }
  
  /// 标记消息为已读
  Future<ApiResponse<bool>> markMessageAsRead(String messageId) async {
    if (_selectedChatId == null) {
      return ApiResponse<bool>.error('未选择聊天对象');
    }
    
    try {
      final response = _isGroupChat
          ? await _messageRepository.markGroupMessagesAsRead(_selectedChatId!)
          : await _messageRepository.markDirectMessagesAsRead(_selectedChatId!);
      
      if (response.success) {
        // 更新本地消息状态
        _updateMessageStatus(messageId, MessageStatus.read);
      }
      
      return response;
    } catch (e) {
      _setError('标记消息为已读失败: $e');
      return ApiResponse<bool>.error('标记消息为已读失败: $e');
    }
  }
  
  /// 删除消息
  Future<ApiResponse<bool>> deleteMessage(String messageId) async {
    try {
      final response = _isGroupChat
          ? await _messageRepository.deleteGroupMessage(messageId)
          : await _messageRepository.deleteDirectMessage(messageId);
      
      if (response.success) {
        // 从本地消息列表中删除
        _removeMessageFromLocal(messageId);
      }
      
      return response;
    } catch (e) {
      _setError('删除消息失败: $e');
      return ApiResponse<bool>.error('删除消息失败: $e');
    }
  }
  
  /// 重新发送失败消息
  Future<ApiResponse<Message>> resendMessage(String messageId) async {
    // 查找失败的消息
    Message? failedMessage;
    
    for (final messages in _userMessages.values) {
      final message = messages.firstWhere(
        (m) => m.id == messageId,
        orElse: () => Message(
          id: '',
          senderId: '',
          content: '',
          type: MessageType.text,
          status: MessageStatus.failed,
          createdAt: DateTime.now(),
          receiverId: '',
        ),
      );
      if (message.id.isNotEmpty) {
        failedMessage = message;
        break;
      }
    }
    
    if (failedMessage == null) {
      for (final messages in _groupMessages.values) {
        final message = messages.firstWhere(
          (m) => m.id == messageId,
          orElse: () => Message(
            id: '',
            senderId: '',
            content: '',
            type: MessageType.text,
            status: MessageStatus.failed,
            createdAt: DateTime.now(),
            groupId: '',
          ),
        );
        if (message.id.isNotEmpty) {
          failedMessage = message;
          break;
        }
      }
    }
    
    if (failedMessage == null || failedMessage.id.isEmpty) {
      return ApiResponse<Message>.error('未找到失败的消息');
    }
    
    _setSending(true);
    _clearError();
    
    try {
      final response = await _messageRepository.resendMessage(failedMessage);
      
      if (response.success && response.data != null) {
        // 更新本地消息状态
        _updateMessage(failedMessage.id, response.data!);
      } else {
        _setError(response.message ?? '重新发送消息失败');
      }
      
      return response;
    } catch (e) {
      _setError('重新发送消息失败: $e');
      return ApiResponse<Message>.error('重新发送消息失败: $e');
    } finally {
      _setSending(false);
    }
  }
  
  /// 更新消息状态
  void _updateMessageStatus(String messageId, MessageStatus status) {
    // 更新单聊消息
    for (final userId in _userMessages.keys) {
      final messages = _userMessages[userId]!;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId) {
          _userMessages[userId]![i] = messages[i].copyWith(status: status);
          notifyListeners();
          return;
        }
      }
    }
    
    // 更新群聊消息
    for (final groupId in _groupMessages.keys) {
      final messages = _groupMessages[groupId]!;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId) {
          _groupMessages[groupId]![i] = messages[i].copyWith(status: status);
          notifyListeners();
          return;
        }
      }
    }
  }
  
  /// 更新消息
  void _updateMessage(String messageId, Message newMessage) {
    // 更新单聊消息
    for (final userId in _userMessages.keys) {
      final messages = _userMessages[userId]!;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId) {
          _userMessages[userId]![i] = newMessage;
          notifyListeners();
          return;
        }
      }
    }
    
    // 更新群聊消息
    for (final groupId in _groupMessages.keys) {
      final messages = _groupMessages[groupId]!;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId) {
          _groupMessages[groupId]![i] = newMessage;
          notifyListeners();
          return;
        }
      }
    }
  }
  
  /// 从本地消息列表中删除消息
  void _removeMessageFromLocal(String messageId) {
    // 从单聊消息中删除
    for (final userId in _userMessages.keys) {
      _userMessages[userId] = _userMessages[userId]!.where(
        (message) => message.id != messageId
      ).toList();
    }
    
    // 从群聊消息中删除
    for (final groupId in _groupMessages.keys) {
      _groupMessages[groupId] = _groupMessages[groupId]!.where(
        (message) => message.id != messageId
      ).toList();
    }
    
    notifyListeners();
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置发送状态
  void _setSending(bool sending) {
    _isSending = sending;
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
  
  @override
  void dispose() {
    // 断开WebSocket连接
    _webSocketService.disconnect();
    super.dispose();
  }
}