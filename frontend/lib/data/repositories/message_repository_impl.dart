import 'dart:io';

import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/result.dart';
import '../datasources/local/message_local_datasource.dart';
import '../datasources/remote/message_remote_datasource.dart';
import '../datasources/remote/api_exception.dart';

/// 消息仓库实现
/// 
/// 实现了 [MessageRepository] 接口，处理消息相关的数据操作
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;
  
  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required MessageLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  
  @override
  Future<Result<List<MessageModel>>> getMessages({
    required String conversationId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // 尝试从远程获取消息
      final messages = await _remoteDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
        offset: offset,
      );
      
      // 将消息保存到本地
      await _localDataSource.saveMessages(messages);
      
      return Result.success(messages);
    } on ApiException catch (e) {
      // 如果远程获取失败，尝试从本地获取
      try {
        final localMessages = await _localDataSource.getMessages(
          conversationId: conversationId,
          limit: limit,
          offset: offset,
        );
        
        if (localMessages.isNotEmpty) {
          return Result.success(localMessages);
        } else {
          return Result.error(e.message);
        }
      } catch (localError) {
        return Result.error(e.message);
      }
    } on SocketException {
      // 网络错误，尝试从本地获取
      try {
        final localMessages = await _localDataSource.getMessages(
          conversationId: conversationId,
          limit: limit,
          offset: offset,
        );
        
        if (localMessages.isNotEmpty) {
          return Result.success(localMessages);
        } else {
          return Result.error('Network error. Please check your connection.');
        }
      } catch (localError) {
        return Result.error('Network error. Please check your connection.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<MessageModel>> sendMessage(MessageModel message) async {
    try {
      // 先保存到本地
      await _localDataSource.saveMessage(message);
      
      // 发送到远程
      final sentMessage = await _remoteDataSource.sendMessage(message);
      
      // 更新本地消息
      await _localDataSource.saveMessage(sentMessage);
      
      return Result.success(sentMessage);
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      // 网络错误，但消息已保存到本地，标记为待发送
      final offlineMessage = message.copyWith(
        status: MessageStatus.failed,
        metadata: {
          ...message.metadata ?? {},
          'pendingSend': true,
        },
      );
      
      await _localDataSource.saveMessage(offlineMessage);
      
      return Result.error('Network error. Message saved locally and will be sent when connection is restored.');
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      // 从远程删除
      await _remoteDataSource.deleteMessage(messageId);
      
      // 从本地删除
      await _localDataSource.deleteMessage(messageId);
      
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      // 网络错误，仅从本地删除并标记为待同步
      try {
        await _localDataSource.markMessageForDeletion(messageId);
        return Result.success(null);
      } catch (localError) {
        return Result.error('Network error. Please try again when connection is restored.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<void>> markMessageAsRead(String messageId) async {
    try {
      // 在远程标记为已读
      await _remoteDataSource.markMessageAsRead(messageId);
      
      // 在本地标记为已读
      await _localDataSource.markMessageAsRead(messageId);
      
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      // 网络错误，仅在本地标记为已读并标记为待同步
      try {
        await _localDataSource.markMessageAsRead(messageId, pendingSync: true);
        return Result.success(null);
      } catch (localError) {
        return Result.error('Network error. Please try again when connection is restored.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<void>> markAllMessagesAsRead(String conversationId) async {
    try {
      // 在远程标记所有消息为已读
      await _remoteDataSource.markAllMessagesAsRead(conversationId);
      
      // 在本地标记所有消息为已读
      await _localDataSource.markAllMessagesAsRead(conversationId);
      
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      // 网络错误，仅在本地标记所有消息为已读并标记为待同步
      try {
        await _localDataSource.markAllMessagesAsRead(conversationId, pendingSync: true);
        return Result.success(null);
      } catch (localError) {
        return Result.error('Network error. Please try again when connection is restored.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<int>> getUnreadMessageCount(String userId) async {
    try {
      // 尝试从远程获取未读消息数量
      final count = await _remoteDataSource.getUnreadMessageCount(userId);
      
      return Result.success(count);
    } on ApiException catch (e) {
      // 如果远程获取失败，尝试从本地获取
      try {
        final localCount = await _localDataSource.getUnreadMessageCount(userId);
        return Result.success(localCount);
      } catch (localError) {
        return Result.error(e.message);
      }
    } on SocketException {
      // 网络错误，尝试从本地获取
      try {
        final localCount = await _localDataSource.getUnreadMessageCount(userId);
        return Result.success(localCount);
      } catch (localError) {
        return Result.error('Network error. Please check your connection.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<List<MessageModel>>> searchMessages({
    required String query,
    String? conversationId,
  }) async {
    try {
      // 尝试从远程搜索消息
      final messages = await _remoteDataSource.searchMessages(
        query: query,
        conversationId: conversationId,
      );
      
      return Result.success(messages);
    } on ApiException catch (e) {
      // 如果远程搜索失败，尝试从本地搜索
      try {
        final localMessages = await _localDataSource.searchMessages(
          query: query,
          conversationId: conversationId,
        );
        
        if (localMessages.isNotEmpty) {
          return Result.success(localMessages);
        } else {
          return Result.error(e.message);
        }
      } catch (localError) {
        return Result.error(e.message);
      }
    } on SocketException {
      // 网络错误，尝试从本地搜索
      try {
        final localMessages = await _localDataSource.searchMessages(
          query: query,
          conversationId: conversationId,
        );
        
        if (localMessages.isNotEmpty) {
          return Result.success(localMessages);
        } else {
          return Result.error('Network error. Please check your connection.');
        }
      } catch (localError) {
        return Result.error('Network error. Please check your connection.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<MessageModel>> recallMessage(String messageId) async {
    try {
      // 首先从本地获取原始消息
      final originalMessage = await _localDataSource.getMessage(messageId);
      if (originalMessage == null) {
        return Result.error('消息不存在');
      }
      
      // 检查是否可以撤回
      if (!originalMessage.canRecall()) {
        return Result.error('消息已超过撤回时限或已被撤回');
      }
      
      // 创建撤回消息
      final recalledMessage = originalMessage.recall();
      
      // 尝试在远程撤回消息
      await _remoteDataSource.recallMessage(messageId);
      
      // 在本地保存撤回消息
      await _localDataSource.saveMessage(recalledMessage);
      
      return Result.success(recalledMessage);
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      // 网络错误，仅在本地标记为撤回并标记为待同步
      try {
        final originalMessage = await _localDataSource.getMessage(messageId);
        if (originalMessage == null) {
          return Result.error('消息不存在');
        }
        
        if (!originalMessage.canRecall()) {
          return Result.error('消息已超过撤回时限或已被撤回');
        }
        
        final recalledMessage = originalMessage.recall();
        await _localDataSource.saveMessage(recalledMessage);
        
        // TODO: 添加到待同步撤回列表
        
        return Result.success(recalledMessage);
      } catch (localError) {
        return Result.error('Network error. Please try again when connection is restored.');
      }
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  /// 同步待发送的消息
  Future<void> syncPendingMessages() async {
    try {
      // 获取所有待发送的消息
      final pendingMessages = await _localDataSource.getPendingMessages();
      
      for (final message in pendingMessages) {
        try {
          // 尝试发送消息
          final sentMessage = await _remoteDataSource.sendMessage(message);
          
          // 更新本地消息
          await _localDataSource.saveMessage(sentMessage);
        } catch (e) {
          // 发送失败，继续处理下一条消息
          continue;
        }
      }
    } catch (e) {
      // 同步失败，稍后重试
      print('Failed to sync pending messages: $e');
    }
  }
  
  /// 同步待删除的消息
  Future<void> syncPendingDeletions() async {
    try {
      // 获取所有待删除的消息ID
      final pendingDeletions = await _localDataSource.getPendingDeletions();
      
      for (final messageId in pendingDeletions) {
        try {
          // 尝试从远程删除
          await _remoteDataSource.deleteMessage(messageId);
          
          // 从本地删除
          await _localDataSource.deleteMessage(messageId);
        } catch (e) {
          // 删除失败，继续处理下一条消息
          continue;
        }
      }
    } catch (e) {
      // 同步失败，稍后重试
      print('Failed to sync pending deletions: $e');
    }
  }
  
  /// 同步待标记为已读的消息
  Future<void> syncPendingReadStatus() async {
    try {
      // 获取所有待标记为已读的消息ID
      final pendingReadStatus = await _localDataSource.getPendingReadStatus();
      
      for (final messageId in pendingReadStatus) {
        try {
          // 尝试在远程标记为已读
          await _remoteDataSource.markMessageAsRead(messageId);
          
          // 更新本地状态
          await _localDataSource.clearPendingReadStatus(messageId);
        } catch (e) {
          // 标记失败，继续处理下一条消息
          continue;
        }
      }
    } catch (e) {
      // 同步失败，稍后重试
      print('Failed to sync pending read status: $e');
    }
  }
}