import 'dart:async';
import 'dart:convert';

import '../../core/network/websocket_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../models/message.dart';
import '../../domain/models/conversation_model.dart' show MessageStatus, MessageType;
// import '../repositories/message_repository.dart';

/// WebSocket消息类型
enum WebSocketMessageType {
  /// 文本消息
  text,
  /// 图片消息
  image,
  /// 语音消息
  voice,
  /// 视频消息
  video,
  /// 文件消息
  file,
  /// 系统消息
  system,
  /// 通知消息
  notification,
  /// 心跳消息
  ping,
  /// 未知类型
  unknown
}

/// WebSocket消息服务，用于处理WebSocket消息的发送和接收
class WebSocketService {
  // 单例模式
  static final WebSocketService _instance = WebSocketService._internal();
  static WebSocketService get instance => _instance;
  
  // WebSocket客户端
  final _wsClient = WebSocketClient.instance;
  // 消息仓库
  // final _messageRepository = MessageRepository.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 消息流控制器
  final _messageController = StreamController<Message>.broadcast();
  // 通知流控制器
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  // 连接状态流控制器
  final _connectionStatusController = StreamController<WebSocketStatus>.broadcast();
  
  // 消息流
  Stream<Message> get messageStream => _messageController.stream;
  // 通知流
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  // 连接状态流
  Stream<WebSocketStatus> get connectionStatusStream => _connectionStatusController.stream;
  
  // 私有构造函数
  WebSocketService._internal() {
    _init();
  }
  
  // 初始化
  void _init() {
    // 监听WebSocket消息
    _wsClient.messageStream.listen(_handleWebSocketMessage);
    
    // 监听WebSocket连接状态
    _wsClient.statusStream.listen((status) {
      _connectionStatusController.add(status);
    });
  }
  
  // 处理WebSocket消息
  void _handleWebSocketMessage(dynamic data) {
    try {
      _logger.d('收到WebSocket消息: $data');
      
      // 解析消息类型
      final Map<String, dynamic> messageData = data is String ? jsonDecode(data) : data;
      final String type = messageData['type'] ?? 'unknown';
      
      switch (type) {
        case 'ping':
          // 心跳消息，不需要处理
          break;
        case 'message':
          // 聊天消息
          _handleChatMessage(messageData);
          break;
        case 'notification':
          // 通知消息
          _handleNotificationMessage(messageData);
          break;
        case 'system':
          // 系统消息
          _handleSystemMessage(messageData);
          break;
        default:
          _logger.w('未知的WebSocket消息类型: $type');
      }
    } catch (e) {
      _logger.e('处理WebSocket消息失败: $e');
    }
  }
  
  // 处理聊天消息
  void _handleChatMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data['data']);
      _messageController.add(message);
    } catch (e) {
      _logger.e('处理聊天消息失败: $e');
    }
  }
  
  // 处理通知消息
  void _handleNotificationMessage(Map<String, dynamic> data) {
    try {
      _notificationController.add(data['data']);
    } catch (e) {
      _logger.e('处理通知消息失败: $e');
    }
  }
  
  // 处理系统消息
  void _handleSystemMessage(Map<String, dynamic> data) {
    try {
      // 系统消息可能需要特殊处理，例如用户上线/下线通知
      _logger.i('收到系统消息: ${data['data']}');
    } catch (e) {
      _logger.e('处理系统消息失败: $e');
    }
  }
  
  /// 发送文本消息（单聊）
  Future<ApiResponse<Message>> sendDirectTextMessage(String receiverId, String content) async {
    try {
      // 生成临时消息ID
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 创建消息对象
      var message = Message(
        id: tempId,
        senderId: _wsClient.userId ?? '',
        receiverId: receiverId,
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 构建WebSocket消息
      final wsMessage = {
        'type': 'message',
        'data': {
          'id': message.id,
          'senderId': message.senderId,
          'receiverId': receiverId,
          'content': message.content,
          'type': message.type.name,
          'mediaUrl': message.mediaUrl,
          'thumbnailUrl': message.thumbnailUrl,
          'timestamp': message.createdAt.toIso8601String(),
        },
      };
      
      // 发送WebSocket消息
      final sent = await _wsClient.send(jsonEncode(wsMessage));
      
      if (sent) {
        // 更新消息状态为已发送
        message = message.copyWith(status: MessageStatus.sent);
        return ApiResponse.success(message);
      } else {
        // 更新消息状态为发送失败
        message = message.copyWith(status: MessageStatus.failed);
        return ApiResponse.error('发送消息失败', data: message);
      }
    } catch (e) {
      _logger.e('发送文本消息失败: $e');
      return ApiResponse.error('发送消息失败: $e');
    }
  }
  
  /// 发送文本消息（群聊）
  Future<ApiResponse<Message>> sendGroupTextMessage(String groupId, String content) async {
    try {
      // 生成临时消息ID
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 创建消息对象
      var message = Message(
        id: tempId,
        senderId: _wsClient.userId ?? '',
        groupId: groupId,
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 构建WebSocket消息
      final wsMessage = {
        'type': 'message',
        'data': {
          'id': message.id,
          'senderId': message.senderId,
          'groupId': groupId,
          'content': message.content,
          'type': message.type.name,
          'mediaUrl': message.mediaUrl,
          'thumbnailUrl': message.thumbnailUrl,
          'timestamp': message.createdAt.toIso8601String(),
        },
      };
      
      // 发送WebSocket消息
      final sent = await _wsClient.send(jsonEncode(wsMessage));
      
      if (sent) {
        // 更新消息状态为已发送
        message = message.copyWith(status: MessageStatus.sent);
        return ApiResponse.success(message);
      } else {
        // 更新消息状态为发送失败
        message = message.copyWith(status: MessageStatus.failed);
        return ApiResponse.error('发送消息失败', data: message);
      }
    } catch (e) {
      _logger.e('发送群聊文本消息失败: $e');
      return ApiResponse.error('发送消息失败: $e');
    }
  }
  
  /// 发送媒体消息（单聊）
  Future<ApiResponse<Message>> sendDirectMediaMessage({
    required String receiverId,
    required dynamic file,
    required MessageType type,
    String? caption,
  }) async {
    try {
      // 模拟上传媒体文件（实际项目中需要实现真实的上传逻辑）
      final mediaUrl = 'https://example.com/media/${DateTime.now().millisecondsSinceEpoch}';
      final thumbnailUrl = 'https://example.com/thumbnail/${DateTime.now().millisecondsSinceEpoch}';
      
      // 生成临时消息ID
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 创建消息对象
      var message = Message(
        id: tempId,
        senderId: _wsClient.userId ?? '',
        receiverId: receiverId,
        content: caption ?? '',
        type: type,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 构建WebSocket消息
      final wsMessage = {
        'type': 'message',
        'data': {
          'id': message.id,
          'senderId': message.senderId,
          'receiverId': receiverId,
          'content': message.content,
          'type': message.type.name,
          'mediaUrl': message.mediaUrl,
          'thumbnailUrl': message.thumbnailUrl,
          'timestamp': message.createdAt.toIso8601String(),
        },
      };
      
      // 发送WebSocket消息
      final sent = await _wsClient.send(jsonEncode(wsMessage));
      
      if (sent) {
        // 更新消息状态为已发送
        message = message.copyWith(status: MessageStatus.sent);
        return ApiResponse.success(message);
      } else {
        // 更新消息状态为发送失败
        message = message.copyWith(status: MessageStatus.failed);
        return ApiResponse.error('发送消息失败', data: message);
      }
    } catch (e) {
      _logger.e('发送媒体消息失败: $e');
      return ApiResponse.error('发送消息失败: $e');
    }
  }
  
  /// 发送媒体消息（群聊）
  Future<ApiResponse<Message>> sendGroupMediaMessage({
    required String groupId,
    required dynamic file,
    required MessageType type,
    String? caption,
  }) async {
    try {
      // 模拟上传媒体文件（实际项目中需要实现真实的上传逻辑）
      final mediaUrl = 'https://example.com/media/${DateTime.now().millisecondsSinceEpoch}';
      final thumbnailUrl = 'https://example.com/thumbnail/${DateTime.now().millisecondsSinceEpoch}';
      
      // 生成临时消息ID
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 创建消息对象
      var message = Message(
        id: tempId,
        senderId: _wsClient.userId ?? '',
        groupId: groupId,
        content: caption ?? '',
        type: type,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 构建WebSocket消息
      final wsMessage = {
        'type': 'message',
        'data': {
          'id': message.id,
          'senderId': message.senderId,
          'groupId': groupId,
          'content': message.content,
          'type': message.type.name,
          'mediaUrl': message.mediaUrl,
          'thumbnailUrl': message.thumbnailUrl,
          'timestamp': message.createdAt.toIso8601String(),
        },
      };
      
      // 发送WebSocket消息
      final sent = await _wsClient.send(jsonEncode(wsMessage));
      
      if (sent) {
        // 更新消息状态为已发送
        message = message.copyWith(status: MessageStatus.sent);
        return ApiResponse.success(message);
      } else {
        // 更新消息状态为发送失败
        message = message.copyWith(status: MessageStatus.failed);
        return ApiResponse.error('发送消息失败', data: message);
      }
    } catch (e) {
      _logger.e('发送群聊媒体消息失败: $e');
      return ApiResponse.error('发送消息失败: $e');
    }
  }
  
  /// 连接WebSocket
  Future<bool> connect() async {
    return await _wsClient.connect();
  }
  
  /// 断开WebSocket连接
  void disconnect() {
    _wsClient.disconnect();
  }
  
  /// 重置WebSocket连接
  Future<bool> resetConnection() async {
    return await _wsClient.resetConnection();
  }
  
  /// 获取当前连接状态
  WebSocketStatus get connectionStatus => _wsClient.status;
  
  /// 释放资源
  void dispose() {
    _messageController.close();
    _notificationController.close();
    _connectionStatusController.close();
  }
}