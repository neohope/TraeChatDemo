import '../../../domain/models/message_model.dart';

/// 消息本地数据源接口
/// 
/// 定义了本地存储消息数据的方法，用于离线缓存和同步
abstract class MessageLocalDataSource {
  /// 获取会话的消息列表
  /// 
  /// [conversationId] 会话ID
  /// [limit] 限制返回的消息数量
  /// [offset] 分页偏移量
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 20,
    int offset = 0,
  });
  
  /// 保存单条消息
  /// 
  /// [message] 要保存的消息
  Future<void> saveMessage(MessageModel message);
  
  /// 保存多条消息
  /// 
  /// [messages] 要保存的消息列表
  Future<void> saveMessages(List<MessageModel> messages);
  
  /// 删除消息
  /// 
  /// [messageId] 要删除的消息ID
  Future<void> deleteMessage(String messageId);
  
  /// 标记消息为待删除
  /// 
  /// [messageId] 要标记的消息ID
  Future<void> markMessageForDeletion(String messageId);
  
  /// 标记消息为已读
  /// 
  /// [messageId] 要标记的消息ID
  /// [pendingSync] 是否标记为待同步到服务器
  Future<void> markMessageAsRead(String messageId, {bool pendingSync = false});
  
  /// 标记会话中的所有消息为已读
  /// 
  /// [conversationId] 会话ID
  /// [pendingSync] 是否标记为待同步到服务器
  Future<void> markAllMessagesAsRead(String conversationId, {bool pendingSync = false});
  
  /// 获取未读消息数量
  /// 
  /// [userId] 用户ID
  Future<int> getUnreadMessageCount(String userId);
  
  /// 搜索消息
  /// 
  /// [query] 搜索关键词
  /// [conversationId] 可选的会话ID，如果提供则只在该会话中搜索
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
  });
  
  /// 根据ID获取单条消息
  /// 
  /// [messageId] 消息ID
  Future<MessageModel?> getMessage(String messageId);
  
  /// 获取所有待发送的消息
  Future<List<MessageModel>> getPendingMessages();
  
  /// 获取所有待删除的消息ID
  Future<List<String>> getPendingDeletions();
  
  /// 获取所有待标记为已读的消息ID
  Future<List<String>> getPendingReadStatus();
  
  /// 清除消息的待标记为已读状态
  /// 
  /// [messageId] 消息ID
  Future<void> clearPendingReadStatus(String messageId);
  
  /// 清除所有本地消息数据
  Future<void> clearAll();
}