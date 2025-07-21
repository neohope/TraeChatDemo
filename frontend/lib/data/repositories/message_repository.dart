import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../core/network/websocket_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/conversation_model.dart'; // 导入 MessageType 枚举
import '../models/api_response.dart';
import '../models/message.dart';
import '../services/api_service.dart';

/// 消息仓库类，用于管理消息数据的存取
class MessageRepository {
  // 单例模式
  static final MessageRepository _instance = MessageRepository._internal();
  static MessageRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // WebSocket客户端
  final _wsClient = WebSocketClient.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  // UUID生成器
  final _uuid = Uuid();
  
  // 私有构造函数
  MessageRepository._internal();
  
  /// 获取单聊消息历史
  Future<ApiResponse<List<Message>>> getDirectMessages(String userId, {
    String? lastMessageId,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (lastMessageId != null) {
        queryParams['last_message_id'] = lastMessageId;
      }
      
      final response = await _apiService.get<List<dynamic>>(
        '/messages/direct/$userId',
        queryParameters: queryParams,
      );
      
      if (response.success && response.data != null) {
        final messages = response.data!.map((json) => Message.fromJson(json)).toList();
        // 保存到本地存储
        await _saveMessagesToLocal(messages);
        return ApiResponse<List<Message>>.success(messages);
      } else {
        return ApiResponse<List<Message>>.error(response.message ?? '获取消息历史失败');
      }
    } catch (e) {
      _logger.e('获取单聊消息历史失败: $e');
      
      // 尝试从本地获取
      try {
        // 使用 getChatData 方法获取消息
        final messagesData = LocalStorage.getChatData('messages_$userId', defaultValue: []);
        if (messagesData != null && messagesData is List && messagesData.isNotEmpty) {
          final localMessages = messagesData
              .map((data) => Message.fromJson(Map<String, dynamic>.from(data)))
              .take(limit)
              .toList();
          if (localMessages.isNotEmpty) {
            return ApiResponse<List<Message>>.success(localMessages, message: '从本地存储获取的消息');
          }
        }
      } catch (localError) {
        _logger.e('从本地获取消息失败: $localError');
      }
      
      return ApiResponse<List<Message>>.error('获取消息历史失败: $e');
    }
  }
  
  /// 获取群聊消息历史
  Future<ApiResponse<List<Message>>> getGroupMessages(String groupId, {
    String? lastMessageId,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (lastMessageId != null) {
        queryParams['last_message_id'] = lastMessageId;
      }
      
      final response = await _apiService.get<List<dynamic>>(
        '/messages/group/$groupId',
        queryParameters: queryParams,
      );
      
      if (response.success && response.data != null) {
        final messages = response.data!.map((json) => Message.fromJson(json)).toList();
        // 保存到本地存储
        await _saveMessagesToLocal(messages);
        return ApiResponse<List<Message>>.success(messages);
      } else {
        return ApiResponse<List<Message>>.error(response.message ?? '获取消息历史失败');
      }
    } catch (e) {
      _logger.e('获取群聊消息历史失败: $e');
      
      // 尝试从本地获取
      try {
        // 使用 getChatData 方法获取消息
        final messagesData = LocalStorage.getChatData('group_messages_$groupId', defaultValue: []);
        if (messagesData != null && messagesData is List && messagesData.isNotEmpty) {
          final localMessages = messagesData
              .map((data) => Message.fromJson(Map<String, dynamic>.from(data)))
              .take(limit)
              .toList();
          if (localMessages.isNotEmpty) {
            return ApiResponse<List<Message>>.success(localMessages, message: '从本地存储获取的消息');
          }
        }
      } catch (localError) {
        _logger.e('从本地获取消息失败: $localError');
      }
      
      return ApiResponse<List<Message>>.error('获取消息历史失败: $e');
    }
  }
  
  /// 发送文本消息（单聊）
  Future<ApiResponse<Message>> sendDirectTextMessage(String receiverId, String content) async {
    // 生成临时消息ID
    final tempId = _uuid.v4();
    final currentUser = await LocalStorage.getCurrentUser();
    
    if (currentUser == null) {
      return ApiResponse<Message>.error('未登录，无法发送消息');
    }
    
    // 创建临时消息对象
    final tempMessage = Message(
      id: tempId,
      senderId: currentUser.id,
      sender: currentUser,
      receiverId: receiverId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    
    // 保存临时消息到本地
    await _saveMessagesToLocal([tempMessage]);
    
    try {
      // 准备发送数据
      final data = {
        'receiver_id': receiverId,
        'content': content,
        'type': 'text',
        'temp_id': tempId,
      };
      
      // 通过WebSocket发送
      if (_wsClient.status == WebSocketStatus.connected) {
        _wsClient.send({
          'action': 'send_message',
          'data': data,
        });
        
        // 更新消息状态为已发送
        final updatedMessage = tempMessage.copyWith(status: MessageStatus.sent);
        await _saveMessagesToLocal([updatedMessage]);
        
        return ApiResponse<Message>.success(updatedMessage);
      }
      
      // WebSocket未连接，使用HTTP API发送
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages/direct',
        data: data,
      );
      
      if (response.success && response.data != null) {
        final message = Message.fromJson(response.data!);
        // 保存到本地存储
        await _saveMessagesToLocal([message]);
        return ApiResponse<Message>.success(message);
      } else {
        // 更新消息状态为发送失败
        final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
        await _saveMessagesToLocal([failedMessage]);
        
        return ApiResponse<Message>.error(
          response.message ?? '发送消息失败',
          data: failedMessage,
        );
      }
    } catch (e) {
      _logger.e('发送文本消息失败: $e');
      
      // 更新消息状态为发送失败
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      await _saveMessagesToLocal([failedMessage]);
      
      return ApiResponse<Message>.error('发送消息失败: $e', data: failedMessage);
    }
  }
  
  /// 发送文本消息（群聊）
  Future<ApiResponse<Message>> sendGroupTextMessage(String groupId, String content) async {
    // 生成临时消息ID
    final tempId = _uuid.v4();
    final currentUser = await LocalStorage.getCurrentUser();
    
    if (currentUser == null) {
      return ApiResponse<Message>.error('未登录，无法发送消息');
    }
    
    // 创建临时消息对象
    final tempMessage = Message(
      id: tempId,
      senderId: currentUser.id,
      sender: currentUser,
      groupId: groupId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    
    // 保存临时消息到本地
    await _saveMessagesToLocal([tempMessage]);
    
    try {
      // 准备发送数据
      final data = {
        'group_id': groupId,
        'content': content,
        'type': 'text',
        'temp_id': tempId,
      };
      
      // 通过WebSocket发送
      if (_wsClient.status == WebSocketStatus.connected) {
        _wsClient.send({
          'action': 'send_group_message',
          'data': data,
        });
        
        // 更新消息状态为已发送
        final updatedMessage = tempMessage.copyWith(status: MessageStatus.sent);
        await _saveMessagesToLocal([updatedMessage]);
        
        return ApiResponse<Message>.success(updatedMessage);
      }
      
      // WebSocket未连接，使用HTTP API发送
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages/group',
        data: data,
      );
      
      if (response.success && response.data != null) {
        final message = Message.fromJson(response.data!);
        // 保存到本地存储
        await _saveMessagesToLocal([message]);
        return ApiResponse<Message>.success(message);
      } else {
        // 更新消息状态为发送失败
        final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
        await _saveMessagesToLocal([failedMessage]);
        
        return ApiResponse<Message>.error(
          response.message ?? '发送消息失败',
          data: failedMessage,
        );
      }
    } catch (e) {
      _logger.e('发送群聊文本消息失败: $e');
      
      // 更新消息状态为发送失败
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      await _saveMessagesToLocal([failedMessage]);
      
      return ApiResponse<Message>.error('发送消息失败: $e', data: failedMessage);
    }
  }
  
  /// 发送媒体消息（单聊）
  Future<ApiResponse<Message>> sendDirectMediaMessage({
    required String receiverId,
    required File file,
    required MessageType type,
    String? caption,
  }) async {
    // 生成临时消息ID
    final tempId = _uuid.v4();
    final currentUser = await LocalStorage.getCurrentUser();
    
    if (currentUser == null) {
      return ApiResponse<Message>.error('未登录，无法发送消息');
    }
    
    // 获取文件信息
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();
    
    // 创建临时消息对象
    final tempMessage = Message(
      id: tempId,
      senderId: currentUser.id,
      sender: currentUser,
      receiverId: receiverId,
      content: caption ?? '',
      type: type,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      fileName: fileName,
      fileSize: fileSize,
    );
    
    // 保存临时消息到本地
    await _saveMessagesToLocal([tempMessage]);
    
    try {
      // 准备额外数据
      final extraData = <String, dynamic>{
        'receiver_id': receiverId,
        'type': type.toString().split('.').last,
        'temp_id': tempId,
      };
      
      if (caption != null && caption.isNotEmpty) {
        extraData['content'] = caption;
      }
      
      // 上传文件
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/messages/direct/media',
        file,
        extraData: extraData,
      );
      
      if (response.success && response.data != null) {
        final message = Message.fromJson(response.data!);
        // 保存到本地存储
        await _saveMessagesToLocal([message]);
        return ApiResponse<Message>.success(message);
      } else {
        // 更新消息状态为发送失败
        final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
        await _saveMessagesToLocal([failedMessage]);
        
        return ApiResponse<Message>.error(
          response.message ?? '发送媒体消息失败',
          data: failedMessage,
        );
      }
    } catch (e) {
      _logger.e('发送媒体消息失败: $e');
      
      // 更新消息状态为发送失败
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      await _saveMessagesToLocal([failedMessage]);
      
      return ApiResponse<Message>.error('发送媒体消息失败: $e', data: failedMessage);
    }
  }
  
  /// 发送媒体消息（群聊）
  Future<ApiResponse<Message>> sendGroupMediaMessage({
    required String groupId,
    required File file,
    required MessageType type,
    String? caption,
  }) async {
    // 生成临时消息ID
    final tempId = _uuid.v4();
    final currentUser = await LocalStorage.getCurrentUser();
    
    if (currentUser == null) {
      return ApiResponse<Message>.error('未登录，无法发送消息');
    }
    
    // 获取文件信息
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();
    
    // 创建临时消息对象
    final tempMessage = Message(
      id: tempId,
      senderId: currentUser.id,
      sender: currentUser,
      groupId: groupId,
      content: caption ?? '',
      type: type,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      fileName: fileName,
      fileSize: fileSize,
    );
    
    // 保存临时消息到本地
    await _saveMessagesToLocal([tempMessage]);
    
    try {
      // 准备额外数据
      final extraData = <String, dynamic>{
        'group_id': groupId,
        'type': type.toString().split('.').last,
        'temp_id': tempId,
      };
      
      if (caption != null && caption.isNotEmpty) {
        extraData['content'] = caption;
      }
      
      // 上传文件
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/messages/group/media',
        file,
        extraData: extraData,
      );
      
      if (response.success && response.data != null) {
        final message = Message.fromJson(response.data!);
        // 保存到本地存储
        await _saveMessagesToLocal([message]);
        return ApiResponse<Message>.success(message);
      } else {
        // 更新消息状态为发送失败
        final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
        await _saveMessagesToLocal([failedMessage]);
        
        return ApiResponse<Message>.error(
          response.message ?? '发送媒体消息失败',
          data: failedMessage,
        );
      }
    } catch (e) {
      _logger.e('发送群聊媒体消息失败: $e');
      
      // 更新消息状态为发送失败
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      await _saveMessagesToLocal([failedMessage]);
      
      return ApiResponse<Message>.error('发送媒体消息失败: $e', data: failedMessage);
    }
  }
  
  /// 标记消息为已读（单聊）
  Future<ApiResponse<bool>> markDirectMessagesAsRead(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages/direct/$userId/read',
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('标记单聊消息为已读失败: $e');
      return ApiResponse<bool>.error('标记消息为已读失败: $e');
    }
  }
  
  /// 标记消息为已读（群聊）
  Future<ApiResponse<bool>> markGroupMessagesAsRead(String groupId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages/group/$groupId/read',
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('标记群聊消息为已读失败: $e');
      return ApiResponse<bool>.error('标记消息为已读失败: $e');
    }
  }
  
  /// 删除消息（单聊）
  Future<ApiResponse<bool>> deleteDirectMessage(String messageId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/messages/direct/$messageId',
      );
      
      if (response.success) {
        // 从本地存储中标记为已删除
        // 获取所有单聊消息
        final allDirectMessages = await getDirectMessages('', limit: 1000);
        if (allDirectMessages.success && allDirectMessages.data != null) {
          // 找到要删除的消息并标记为已删除
          final messages = allDirectMessages.data!;
          for (final message in messages) {
            if (message.id == messageId) {
              final deletedMessage = message.copyWith(isDeleted: true);
              await _saveMessagesToLocal([deletedMessage]);
              break;
            }
          }
        }
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('删除单聊消息失败: $e');
      return ApiResponse<bool>.error('删除消息失败: $e');
    }
  }
  
  /// 删除消息（群聊）
  Future<ApiResponse<bool>> deleteGroupMessage(String messageId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/messages/group/$messageId',
      );
      
      if (response.success) {
        // 从本地存储中标记为已删除
        // 获取所有群聊消息
        final allGroupMessages = await getGroupMessages('', limit: 1000);
        if (allGroupMessages.success && allGroupMessages.data != null) {
          // 找到要删除的消息并标记为已删除
          final messages = allGroupMessages.data!;
          for (final message in messages) {
            if (message.id == messageId) {
              final deletedMessage = message.copyWith(isDeleted: true);
              await _saveMessagesToLocal([deletedMessage]);
              break;
            }
          }
        }
      }
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('删除群聊消息失败: $e');
      return ApiResponse<bool>.error('删除消息失败: $e');
    }
  }
  
  /// 重新发送失败的消息
  Future<ApiResponse<Message>> resendMessage(Message failedMessage) async {
    // 根据消息类型和目标类型选择合适的发送方法
    if (failedMessage.isDirectMessage) {
      if (failedMessage.type == MessageType.text) {
        return sendDirectTextMessage(
          failedMessage.receiverId!,
          failedMessage.content,
        );
      } else if (failedMessage.isMediaMessage && failedMessage.mediaUrl != null) {
        // 对于媒体消息，需要重新获取文件
        // 这里简化处理，实际应用中可能需要从本地缓存获取文件
        final file = File(failedMessage.mediaUrl!);
        if (await file.exists()) {
          return sendDirectMediaMessage(
            receiverId: failedMessage.receiverId!,
            file: file,
            type: failedMessage.type,
            caption: failedMessage.content.isNotEmpty ? failedMessage.content : null,
          );
        } else {
          return ApiResponse<Message>.error('媒体文件不存在，无法重新发送');
        }
      }
    } else if (failedMessage.isGroupMessage) {
      if (failedMessage.type == MessageType.text) {
        return sendGroupTextMessage(
          failedMessage.groupId!,
          failedMessage.content,
        );
      } else if (failedMessage.isMediaMessage && failedMessage.mediaUrl != null) {
        // 对于媒体消息，需要重新获取文件
        final file = File(failedMessage.mediaUrl!);
        if (await file.exists()) {
          return sendGroupMediaMessage(
            groupId: failedMessage.groupId!,
            file: file,
            type: failedMessage.type,
            caption: failedMessage.content.isNotEmpty ? failedMessage.content : null,
          );
        } else {
          return ApiResponse<Message>.error('媒体文件不存在，无法重新发送');
        }
      }
    }
    
    return ApiResponse<Message>.error('无法重新发送此类型的消息');
  }
  
  /// 将消息保存到本地存储
  Future<void> _saveMessagesToLocal(List<Message> messages) async {
    for (final message in messages) {
      if (message.isDirectMessage && message.receiverId != null) {
        // 获取现有消息
        final existingMessages = LocalStorage.getChatData('messages_${message.receiverId}', defaultValue: []);
        if (existingMessages is List) {
          // 检查消息是否已存在
          final messageExists = existingMessages.any((m) => 
              m is Map && m['id'] == message.id);
          
          if (!messageExists) {
            // 添加新消息
            existingMessages.add(message.toJson());
            // 保存更新后的消息列表
            await LocalStorage.saveChatData('messages_${message.receiverId}', existingMessages);
          }
        }
      } else if (message.isGroupMessage && message.groupId != null) {
        // 获取现有消息
        final existingMessages = LocalStorage.getChatData('group_messages_${message.groupId}', defaultValue: []);
        if (existingMessages is List) {
          // 检查消息是否已存在
          final messageExists = existingMessages.any((m) => 
              m is Map && m['id'] == message.id);
          
          if (!messageExists) {
            // 添加新消息
            existingMessages.add(message.toJson());
            // 保存更新后的消息列表
            await LocalStorage.saveChatData('group_messages_${message.groupId}', existingMessages);
          }
        }
      }
    }
  }
}