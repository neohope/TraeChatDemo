import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../storage/local_storage.dart';
import '../utils/app_logger.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  static WebSocketService get instance => _instance;

  WebSocketChannel? _channel;
  final AppLogger _logger = AppLogger.instance;
  
  // 连接状态
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  
  // 重连配置
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelay = 3000; // 毫秒
  
  // 事件流控制器
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  
  // 心跳
  Timer? _heartbeatTimer;
  static const int _heartbeatInterval = 30000; // 30秒
  
  // WebSocket URL
  static const String _wsUrl = 'ws://localhost:3000';
  
  /// 消息流
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// 连接状态流
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// 是否已连接
  bool get isConnected => _isConnected;
  
  /// 连接WebSocket
  Future<void> connect({String? url}) async {
    if (_isConnected || _isConnecting) {
      _logger.logger.w('WebSocket已连接或正在连接中');
      return;
    }
    
    _isConnecting = true;
    _shouldReconnect = true;
    
    try {
      final token = await LocalStorage.getAuthToken();
      final wsUrl = url ?? _wsUrl;
      final uri = Uri.parse('$wsUrl?token=$token');
      
      _logger.logger.i('正在连接WebSocket: $uri');
      
      _channel = IOWebSocketChannel.connect(uri);
      
      // 监听连接状态
      _channel!.ready.then((_) {
        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0;
        _connectionController.add(true);
        _startHeartbeat();
        _logger.logger.i('WebSocket连接成功');
      }).catchError((error) {
        _logger.logger.e('WebSocket连接失败: $error');
        _handleConnectionError();
      });
      
      // 监听消息
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
    } catch (e) {
      _logger.logger.e('WebSocket连接异常: $e');
      _handleConnectionError();
    }
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _stopHeartbeat();
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    _logger.logger.i('WebSocket已断开连接');
  }
  
  /// 发送消息
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      _logger.logger.w('WebSocket未连接，无法发送消息');
      return;
    }
    
    try {
      final jsonMessage = json.encode(message);
      _channel!.sink.add(jsonMessage);
      _logger.logger.d('发送WebSocket消息: $jsonMessage');
    } catch (e) {
      _logger.logger.e('发送WebSocket消息失败: $e');
    }
  }
  
  /// 发送聊天消息
  void sendChatMessage({
    required String chatId,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
  }) {
    sendMessage({
      'type': 'chat_message',
      'data': {
        'chatId': chatId,
        'content': content,
        'messageType': type,
        'metadata': metadata,
      },
    });
  }
  
  /// 发送输入状态
  void sendTypingStatus({
    required String chatId,
    required bool isTyping,
  }) {
    sendMessage({
      'type': 'typing_status',
      'data': {
        'chatId': chatId,
        'isTyping': isTyping,
      },
    });
  }
  
  /// 发送在线状态
  void sendOnlineStatus({
    required String status,
  }) {
    sendMessage({
      'type': 'online_status',
      'data': {
        'status': status,
      },
    });
  }
  
  /// 加入聊天室
  void joinChat(String chatId) {
    sendMessage({
      'type': 'join_chat',
      'data': {
        'chatId': chatId,
      },
    });
  }
  
  /// 离开聊天室
  void leaveChat(String chatId) {
    sendMessage({
      'type': 'leave_chat',
      'data': {
        'chatId': chatId,
      },
    });
  }
  
  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      _logger.logger.d('收到WebSocket消息: $data');
      
      // 处理心跳响应
      if (data['type'] == 'pong') {
        _logger.logger.d('收到心跳响应');
        return;
      }
      
      // 广播消息给监听者
      _messageController.add(data);
    } catch (e) {
      _logger.logger.e('解析WebSocket消息失败: $e');
    }
  }
  
  /// 处理错误
  void _handleError(error) {
    _logger.logger.e('WebSocket错误: $error');
    _handleConnectionError();
  }
  
  /// 处理断开连接
  void _handleDisconnection() {
    _logger.logger.w('WebSocket连接已断开');
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    _stopHeartbeat();
    
    // 尝试重连
    if (_shouldReconnect) {
      _attemptReconnect();
    }
  }
  
  /// 处理连接错误
  void _handleConnectionError() {
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    _stopHeartbeat();
    
    if (_shouldReconnect) {
      _attemptReconnect();
    }
  }
  
  /// 尝试重连
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.logger.e('WebSocket重连次数已达上限，停止重连');
      _shouldReconnect = false;
      return;
    }
    
    _reconnectAttempts++;
    _logger.logger.i('WebSocket重连尝试 $_reconnectAttempts/$_maxReconnectAttempts');
    
    Timer(const Duration(milliseconds: _reconnectDelay), () {
      if (_shouldReconnect && !_isConnected && !_isConnecting) {
        connect();
      }
    });
  }
  
  /// 开始心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatInterval),
      (timer) {
        if (_isConnected) {
          sendMessage({'type': 'ping'});
        } else {
          timer.cancel();
        }
      },
    );
  }
  
  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  /// 重置重连计数
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }
  
  /// 销毁服务
  void dispose() {
    _shouldReconnect = false;
    _stopHeartbeat();
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

/// WebSocket消息类型
class WebSocketMessageType {
  static const String chatMessage = 'chat_message';
  static const String typingStatus = 'typing_status';
  static const String onlineStatus = 'online_status';
  static const String userJoined = 'user_joined';
  static const String userLeft = 'user_left';
  static const String messageRead = 'message_read';
  static const String messageDelivered = 'message_delivered';
  static const String friendRequest = 'friend_request';
  static const String friendAccepted = 'friend_accepted';
  static const String notification = 'notification';
  static const String ping = 'ping';
  static const String pong = 'pong';
}

/// WebSocket事件数据模型
class WebSocketEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  WebSocketEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}