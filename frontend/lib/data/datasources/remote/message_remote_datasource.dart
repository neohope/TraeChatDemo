import '../../../domain/models/message_model.dart';

/// 消息远程数据源接口
/// 
/// 定义了与服务器交互的方法，用于获取和发送消息数据
abstract class MessageRemoteDataSource {
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
  
  /// 发送消息
  /// 
  /// [message] 要发送的消息
  Future<MessageModel> sendMessage(MessageModel message);
  
  /// 删除消息
  /// 
  /// [messageId] 要删除的消息ID
  Future<void> deleteMessage(String messageId);
  
  /// 标记消息为已读
  /// 
  /// [messageId] 要标记的消息ID
  Future<void> markMessageAsRead(String messageId);
  
  /// 标记会话中的所有消息为已读
  /// 
  /// [conversationId] 会话ID
  Future<void> markAllMessagesAsRead(String conversationId);
  
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
}