import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/storage_service.dart';
import '../../utils/result.dart';

/// 消息视图模型
/// 
/// 负责管理消息数据和相关操作，包括加载、发送、删除消息等
class MessageViewModel extends ChangeNotifier {
  final MessageRepository _messageRepository;
  final AuthService _authService;
  final StorageService _storageService;
  
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;
  
  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _hasMoreMessages = true;
  bool get hasMoreMessages => _hasMoreMessages;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  MessageViewModel({
    required MessageRepository messageRepository,
    required AuthService authService,
    required StorageService storageService,
  }) : _messageRepository = messageRepository,
       _authService = authService,
       _storageService = storageService;
  
  /// 设置当前会话ID
  void setCurrentConversation(String conversationId) {
    _currentConversationId = conversationId;
    _messages = [];
    _hasMoreMessages = true;
    _errorMessage = null;
    notifyListeners();
    
    // 加载消息
    loadMessages();
  }
  
  /// 加载消息
  Future<void> loadMessages() async {
    if (_currentConversationId == null || _isLoading || !_hasMoreMessages) {
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _messageRepository.getMessages(
        conversationId: _currentConversationId!,
        limit: 20,
        offset: _messages.length,
      );
      
      result.when(
        success: (newMessages) {
          if (newMessages.isEmpty) {
            _hasMoreMessages = false;
          } else {
            _messages = [...newMessages, ..._messages];
          }
          _isLoading = false;
          notifyListeners();
        },
        error: (error) {
          _errorMessage = error;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 发送文本消息
  Future<Result<MessageModel>> sendTextMessage(String text, String receiverId) async {
    if (_currentConversationId == null) {
      return Result.error('No active conversation');
    }
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Result.error('User not authenticated');
    }
    
    // 创建临时消息ID
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 创建消息模型
    final message = MessageModel.text(
      id: tempId,
      senderId: currentUser.id,
      receiverId: receiverId,
      conversationId: _currentConversationId,
      text: text,
      status: MessageStatus.sending,
    );
    
    // 添加到本地消息列表
    _messages = [..._messages, message];
    notifyListeners();
    
    try {
      // 发送消息到服务器
      final result = await _messageRepository.sendMessage(message);
      
      return result.when(
        success: (sentMessage) {
          // 更新本地消息
          _updateMessage(tempId, sentMessage);
          return Result.success(sentMessage);
        },
        error: (error) {
          // 更新消息状态为失败
          _updateMessageStatus(tempId, MessageStatus.failed);
          return Result.error(error);
        },
      );
    } catch (e) {
      // 更新消息状态为失败
      _updateMessageStatus(tempId, MessageStatus.failed);
      return Result.error(e.toString());
    }
  }
  
  /// 发送图片消息
  Future<Result<MessageModel>> sendImageMessage(String imagePath, String receiverId) async {
    if (_currentConversationId == null) {
      return Result.error('No active conversation');
    }
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Result.error('User not authenticated');
    }
    
    // 创建临时消息ID
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 创建临时消息
    final tempMessage = MessageModel.image(
      id: tempId,
      senderId: currentUser.id,
      receiverId: receiverId,
      conversationId: _currentConversationId,
      imageUrl: imagePath, // 临时使用本地路径
      status: MessageStatus.sending,
    );
    
    // 添加到本地消息列表
    _messages = [..._messages, tempMessage];
    notifyListeners();
    
    try {
      // 上传图片
      final uploadResult = await _storageService.uploadFile(
        filePath: imagePath,
        fileType: 'image',
      );
      
      return uploadResult.when(
        success: (imageUrl) async {
          // 创建带有远程URL的消息
          final message = tempMessage.copyWith(
            mediaUrl: imageUrl,
          );
          
          // 发送消息到服务器
          final result = await _messageRepository.sendMessage(message);
          
          return result.when(
            success: (sentMessage) {
              // 更新本地消息
              _updateMessage(tempId, sentMessage);
              return Result.success(sentMessage);
            },
            error: (error) {
              // 更新消息状态为失败
              _updateMessageStatus(tempId, MessageStatus.failed);
              return Result.error(error);
            },
          );
        },
        error: (error) {
          // 更新消息状态为失败
          _updateMessageStatus(tempId, MessageStatus.failed);
          return Result.error('Failed to upload image: $error');
        },
      );
    } catch (e) {
      // 更新消息状态为失败
      _updateMessageStatus(tempId, MessageStatus.failed);
      return Result.error(e.toString());
    }
  }
  
  /// 发送语音消息
  Future<Result<MessageModel>> sendVoiceMessage(String audioPath, int durationInSeconds, String receiverId) async {
    if (_currentConversationId == null) {
      return Result.error('No active conversation');
    }
    
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Result.error('User not authenticated');
    }
    
    // 创建临时消息ID
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 创建临时消息
    final tempMessage = MessageModel.voice(
      id: tempId,
      senderId: currentUser.id,
      receiverId: receiverId,
      conversationId: _currentConversationId,
      audioUrl: audioPath, // 临时使用本地路径
      durationInSeconds: durationInSeconds,
      status: MessageStatus.sending,
    );
    
    // 添加到本地消息列表
    _messages = [..._messages, tempMessage];
    notifyListeners();
    
    try {
      // 上传音频文件
      final uploadResult = await _storageService.uploadFile(
        filePath: audioPath,
        fileType: 'audio',
      );
      
      return uploadResult.when(
        success: (audioUrl) async {
          // 创建带有远程URL的消息
          final message = tempMessage.copyWith(
            mediaUrl: audioUrl,
          );
          
          // 发送消息到服务器
          final result = await _messageRepository.sendMessage(message);
          
          return result.when(
            success: (sentMessage) {
              // 更新本地消息
              _updateMessage(tempId, sentMessage);
              return Result.success(sentMessage);
            },
            error: (error) {
              // 更新消息状态为失败
              _updateMessageStatus(tempId, MessageStatus.failed);
              return Result.error(error);
            },
          );
        },
        error: (error) {
          // 更新消息状态为失败
          _updateMessageStatus(tempId, MessageStatus.failed);
          return Result.error('Failed to upload audio: $error');
        },
      );
    } catch (e) {
      // 更新消息状态为失败
      _updateMessageStatus(tempId, MessageStatus.failed);
      return Result.error(e.toString());
    }
  }
  
  /// 重新发送失败的消息
  Future<Result<MessageModel>> resendMessage(String messageId) async {
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) {
      return Result.error('Message not found');
    }
    
    final message = _messages[messageIndex];
    if (message.status != MessageStatus.failed) {
      return Result.error('Message is not in failed state');
    }
    
    // 更新消息状态为发送中
    _updateMessageStatus(messageId, MessageStatus.sending);
    
    try {
      // 根据消息类型处理重新发送
      switch (message.type) {
        case MessageType.text:
          return sendTextMessage(message.text!, message.receiverId);
        case MessageType.image:
          // 如果是本地路径，则重新上传
          if (message.mediaUrl!.startsWith('file://') || message.mediaUrl!.startsWith('/')) {
            return sendImageMessage(message.mediaUrl!, message.receiverId);
          } else {
            // 如果已经是远程URL，则直接重新发送消息
            return _resendMessageToServer(message);
          }
        case MessageType.voice:
          // 如果是本地路径，则重新上传
          if (message.mediaUrl!.startsWith('file://') || message.mediaUrl!.startsWith('/')) {
            final duration = message.metadata?['duration'] as int? ?? 0;
            return sendVoiceMessage(message.mediaUrl!, duration, message.receiverId);
          } else {
            // 如果已经是远程URL，则直接重新发送消息
            return _resendMessageToServer(message);
          }
        default:
          return _resendMessageToServer(message);
      }
    } catch (e) {
      // 更新消息状态为失败
      _updateMessageStatus(messageId, MessageStatus.failed);
      return Result.error(e.toString());
    }
  }
  
  /// 重新发送消息到服务器
  Future<Result<MessageModel>> _resendMessageToServer(MessageModel message) async {
    try {
      final result = await _messageRepository.sendMessage(message);
      
      return result.when(
        success: (sentMessage) {
          // 更新本地消息
          _updateMessage(message.id, sentMessage);
          return Result.success(sentMessage);
        },
        error: (error) {
          // 更新消息状态为失败
          _updateMessageStatus(message.id, MessageStatus.failed);
          return Result.error(error);
        },
      );
    } catch (e) {
      // 更新消息状态为失败
      _updateMessageStatus(message.id, MessageStatus.failed);
      return Result.error(e.toString());
    }
  }
  
  /// 删除消息
  Future<Result<bool>> deleteMessage(String messageId) async {
    try {
      final result = await _messageRepository.deleteMessage(messageId);
      
      return result.when(
        success: (_) {
          // 从本地消息列表中移除
          _messages = _messages.where((m) => m.id != messageId).toList();
          notifyListeners();
          return Result.success(true);
        },
        error: (error) {
          return Result.error(error);
        },
      );
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  /// 发送引用回复消息
  Future<Result<MessageModel>> sendReplyMessage({
    required String text,
    required MessageModel replyToMessage,
    String? conversationId,
  }) async {
    final targetConversationId = conversationId ?? _currentConversationId;
    if (targetConversationId == null) {
      return Result.error('No active conversation');
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Result.error('User not authenticated');
    }

    try {
      // 创建临时消息ID
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 创建引用回复消息
      final replyMessage = MessageModel.reply(
        id: tempId,
        senderId: currentUser.id,
        receiverId: replyToMessage.senderId,
        conversationId: targetConversationId,
        text: text,
        replyToMessage: replyToMessage,
      );

      // 添加到本地消息列表（显示为发送中状态）
      _messages = [..._messages, replyMessage];
      notifyListeners();

      // 发送到服务器
      final result = await _messageRepository.sendMessage(replyMessage);

      return result.when(
        success: (sentMessage) {
          // 更新本地消息
          _updateMessage(tempId, sentMessage);
          return Result.success(sentMessage);
        },
        error: (error) {
          // 更新消息状态为失败
          _updateMessageStatus(tempId, MessageStatus.failed);
          return Result.error(error);
        },
      );
    } catch (e) {
      return Result.error(e.toString());
    }
  }

  /// 撤回消息
  Future<Result<MessageModel>> recallMessage(String messageId) async {
    try {
      // 检查消息是否存在
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) {
        return Result.error('消息不存在');
      }
      
      final message = _messages[messageIndex];
      
      // 检查是否可以撤回
      if (!message.canRecall()) {
        return Result.error('消息已超过撤回时限或已被撤回');
      }
      
      // 调用仓库层撤回消息
      final result = await _messageRepository.recallMessage(messageId);
      
      return result.when(
        success: (recalledMessage) {
          // 更新本地消息
          _messages[messageIndex] = recalledMessage;
          notifyListeners();
          return Result.success(recalledMessage);
        },
        error: (error) {
          return Result.error(error);
        },
      );
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  /// 标记消息为已读
  Future<Result<bool>> markMessageAsRead(String messageId) async {
    try {
      final result = await _messageRepository.markMessageAsRead(messageId);
      
      return result.when(
        success: (_) {
          // 更新本地消息状态
          final index = _messages.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            final updatedMessage = _messages[index].copyWith(
              isRead: true,
              status: MessageStatus.read,
              readAt: DateTime.now(),
            );
            _messages[index] = updatedMessage;
            notifyListeners();
          }
          return Result.success(true);
        },
        error: (error) {
          return Result.error(error);
        },
      );
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  /// 标记所有消息为已读
  Future<Result<bool>> markAllMessagesAsRead() async {
    if (_currentConversationId == null) {
      return Result.error('No active conversation');
    }
    
    try {
      final result = await _messageRepository.markAllMessagesAsRead(_currentConversationId!);
      
      return result.when(
        success: (_) {
          // 更新所有未读消息的状态
          _messages = _messages.map((message) {
            if (!message.isRead) {
              return message.copyWith(
                isRead: true,
                status: MessageStatus.read,
                readAt: DateTime.now(),
              );
            }
            return message;
          }).toList();
          notifyListeners();
          return Result.success(true);
        },
        error: (error) {
          return Result.error(error);
        },
      );
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  /// 更新消息
  void _updateMessage(String oldId, MessageModel newMessage) {
    final index = _messages.indexWhere((m) => m.id == oldId);
    if (index != -1) {
      _messages[index] = newMessage;
      notifyListeners();
    }
  }
  
  /// 更新消息状态
  void _updateMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
    }
  }
  
  /// 接收新消息
  void receiveMessage(MessageModel message) {
    if (message.conversationId == _currentConversationId) {
      // 添加到当前会话的消息列表
      _messages = [..._messages, message];
      notifyListeners();
      
      // 自动标记为已读
      markMessageAsRead(message.id);
    }
  }
  
  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 清除消息列表
  void clearMessages() {
    _messages = [];
    _currentConversationId = null;
    _hasMoreMessages = true;
    _errorMessage = null;
    notifyListeners();
  }
}