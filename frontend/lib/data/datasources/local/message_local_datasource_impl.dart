import 'package:hive/hive.dart';

import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';
import 'message_local_datasource.dart';

/// 消息本地数据源实现
/// 
/// 使用Hive数据库实现本地存储消息数据
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  static const String _messagesBoxName = 'messages';
  static const String _pendingMessagesBoxName = 'pending_messages';
  static const String _pendingDeletionsBoxName = 'pending_deletions';
  static const String _pendingReadStatusBoxName = 'pending_read_status';
  
  final Box<Map> _messagesBox;
  final Box<Map> _pendingMessagesBox;
  final Box<String> _pendingDeletionsBox;
  final Box<String> _pendingReadStatusBox;
  
  MessageLocalDataSourceImpl({
    required Box<Map> messagesBox,
    required Box<Map> pendingMessagesBox,
    required Box<String> pendingDeletionsBox,
    required Box<String> pendingReadStatusBox,
  }) : _messagesBox = messagesBox,
       _pendingMessagesBox = pendingMessagesBox,
       _pendingDeletionsBox = pendingDeletionsBox,
       _pendingReadStatusBox = pendingReadStatusBox;
  
  /// 工厂构造函数，用于初始化Hive数据库
  static Future<MessageLocalDataSourceImpl> create() async {
    // 打开Hive数据库
    final messagesBox = await Hive.openBox<Map>(_messagesBoxName);
    final pendingMessagesBox = await Hive.openBox<Map>(_pendingMessagesBoxName);
    final pendingDeletionsBox = await Hive.openBox<String>(_pendingDeletionsBoxName);
    final pendingReadStatusBox = await Hive.openBox<String>(_pendingReadStatusBoxName);
    
    return MessageLocalDataSourceImpl(
      messagesBox: messagesBox,
      pendingMessagesBox: pendingMessagesBox,
      pendingDeletionsBox: pendingDeletionsBox,
      pendingReadStatusBox: pendingReadStatusBox,
    );
  }
  
  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 20,
    int offset = 0,
  }) async {
    // 获取所有消息
    final allMessages = _messagesBox.values
        .where((map) => map['conversationId'] == conversationId)
        .map((map) => MessageModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
    
    // 按时间戳排序（从新到旧）
    allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // 应用分页
    if (offset >= allMessages.length) {
      return [];
    }
    
    final end = offset + limit;
    final actualEnd = end > allMessages.length ? allMessages.length : end;
    
    return allMessages.sublist(offset, actualEnd);
  }
  
  @override
  Future<void> saveMessage(MessageModel message) async {
    // 保存消息到本地数据库
    await _messagesBox.put(message.id, message.toJson());
    
    // 如果消息状态为发送中或失败，则添加到待发送列表
    if (message.status == MessageStatus.sending || message.status == MessageStatus.failed) {
      await _pendingMessagesBox.put(message.id, message.toJson());
    }
  }
  
  @override
  Future<void> saveMessages(List<MessageModel> messages) async {
    // 批量保存消息
    final Map<String, Map<String, dynamic>> messagesMap = {};
    final Map<String, Map<String, dynamic>> pendingMessagesMap = {};
    
    for (final message in messages) {
      messagesMap[message.id] = message.toJson();
      
      // 如果消息状态为发送中或失败，则添加到待发送列表
      if (message.status == MessageStatus.sending || message.status == MessageStatus.failed) {
        pendingMessagesMap[message.id] = message.toJson();
      }
    }
    
    await _messagesBox.putAll(messagesMap);
    if (pendingMessagesMap.isNotEmpty) {
      await _pendingMessagesBox.putAll(pendingMessagesMap);
    }
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    // 从本地数据库删除消息
    await _messagesBox.delete(messageId);
    
    // 从待发送列表中删除
    await _pendingMessagesBox.delete(messageId);
    
    // 从待删除列表中删除
    await _pendingDeletionsBox.delete(messageId);
  }
  
  @override
  Future<void> markMessageForDeletion(String messageId) async {
    // 标记消息为待删除
    await _pendingDeletionsBox.put(messageId, messageId);
  }
  
  @override
  Future<void> markMessageAsRead(String messageId, {bool pendingSync = false}) async {
    // 获取消息
    final messageData = _messagesBox.get(messageId);
    if (messageData == null) {
      return;
    }
    
    // 更新消息状态
    final message = MessageModel.fromJson(Map<String, dynamic>.from(messageData));
    final updatedMessage = message.copyWith(
      isRead: true,
      status: MessageStatus.read,
      readAt: DateTime.now(),
    );
    
    // 保存更新后的消息
    await _messagesBox.put(messageId, updatedMessage.toJson());
    
    // 如果需要同步到服务器，则添加到待同步列表
    if (pendingSync) {
      await _pendingReadStatusBox.put(messageId, messageId);
    }
  }
  
  @override
  Future<void> markAllMessagesAsRead(String conversationId, {bool pendingSync = false}) async {
    // 获取会话中的所有消息
    final allMessages = _messagesBox.values
        .where((map) => map['conversationId'] == conversationId && !(map['isRead'] as bool? ?? false))
        .map((map) => MessageModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
    
    // 更新所有消息状态
    for (final message in allMessages) {
      final updatedMessage = message.copyWith(
        isRead: true,
        status: MessageStatus.read,
        readAt: DateTime.now(),
      );
      
      // 保存更新后的消息
      await _messagesBox.put(message.id, updatedMessage.toJson());
      
      // 如果需要同步到服务器，则添加到待同步列表
      if (pendingSync) {
        await _pendingReadStatusBox.put(message.id, message.id);
      }
    }
  }
  
  @override
  Future<int> getUnreadMessageCount(String userId) async {
    // 获取所有未读消息
    final unreadMessages = _messagesBox.values
        .where((map) => 
            map['receiverId'] == userId && 
            !(map['isRead'] as bool? ?? false) &&
            map['senderId'] != userId
        )
        .length;
    
    return unreadMessages;
  }
  
  @override
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
  }) async {
    // 获取所有消息
    final allMessages = _messagesBox.values
        .where((map) {
          // 如果指定了会话ID，则只搜索该会话中的消息
          if (conversationId != null && map['conversationId'] != conversationId) {
            return false;
          }
          
          // 搜索文本内容
          final text = map['text'] as String? ?? '';
          return text.toLowerCase().contains(query.toLowerCase());
        })
        .map((map) => MessageModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
    
    // 按时间戳排序（从新到旧）
    allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return allMessages;
  }
  
  @override
  Future<MessageModel?> getMessage(String messageId) async {
    // 根据ID获取单条消息
    final messageData = _messagesBox.get(messageId);
    if (messageData == null) {
      return null;
    }
    
    return MessageModel.fromJson(Map<String, dynamic>.from(messageData));
  }
  
  @override
  Future<List<MessageModel>> getPendingMessages() async {
    // 获取所有待发送的消息
    final pendingMessages = _pendingMessagesBox.values
        .map((map) => MessageModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
    
    return pendingMessages;
  }
  
  @override
  Future<List<String>> getPendingDeletions() async {
    // 获取所有待删除的消息ID
    final pendingDeletions = _pendingDeletionsBox.values.toList();
    
    return pendingDeletions;
  }
  
  @override
  Future<List<String>> getPendingReadStatus() async {
    // 获取所有待标记为已读的消息ID
    final pendingReadStatus = _pendingReadStatusBox.values.toList();
    
    return pendingReadStatus;
  }
  
  @override
  Future<void> clearPendingReadStatus(String messageId) async {
    // 清除消息的待标记为已读状态
    await _pendingReadStatusBox.delete(messageId);
  }
  
  @override
  Future<void> clearAll() async {
    // 清除所有本地消息数据
    await _messagesBox.clear();
    await _pendingMessagesBox.clear();
    await _pendingDeletionsBox.clear();
    await _pendingReadStatusBox.clear();
  }
}