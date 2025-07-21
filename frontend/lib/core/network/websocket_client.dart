import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../config/app_config.dart';
import '../storage/local_storage.dart';
import '../utils/app_logger.dart';

/// WebSocket连接状态
enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed
}

/// WebSocket客户端，用于管理实时通信
class WebSocketClient {
  // 单例模式
  static final WebSocketClient _instance = WebSocketClient._internal();
  static WebSocketClient get instance => _instance;
  
  // WebSocket通道
  WebSocketChannel? _channel;
  // 消息流控制器
  final StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();
  // 连接状态流控制器
  final StreamController<WebSocketStatus> _statusController = StreamController<WebSocketStatus>.broadcast();
  
  // 当前连接状态
  WebSocketStatus _status = WebSocketStatus.disconnected;
  WebSocketStatus get status => _status;
  
  // 重连计时器
  Timer? _reconnectTimer;
  // 心跳计时器
  Timer? _heartbeatTimer;
  // 重连尝试次数
  int _reconnectAttempts = 0;
  // 最大重连尝试次数
  final int _maxReconnectAttempts = 5;
  // 重连延迟（毫秒）
  final int _reconnectDelay = 3000;
  // 心跳间隔（毫秒）
  final int _heartbeatInterval = 30000;
  
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 消息流
  Stream<dynamic> get messageStream => _messageController.stream;
  // 状态流
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  
  // 私有构造函数
  WebSocketClient._internal();
  
  // 连接WebSocket服务器
  Future<bool> connect() async {
    if (_status == WebSocketStatus.connected || _status == WebSocketStatus.connecting) {
      return true;
    }
    
    _updateStatus(WebSocketStatus.connecting);
    
    try {
      // 获取认证令牌
      final token = await LocalStorage.getAuthToken();
      final wsUrl = '${AppConfig.instance.wsBaseUrl}?token=$token';
      
      _logger.i('正在连接WebSocket: $wsUrl');
      
      // 创建WebSocket连接
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: Duration(milliseconds: _heartbeatInterval),
      );
      
      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      
      _updateStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      _logger.i('WebSocket连接成功');
      return true;
    } catch (e) {
      _logger.e('WebSocket连接失败: $e');
      _updateStatus(WebSocketStatus.failed);
      _scheduleReconnect();
      return false;
    }
  }
  
  // 断开WebSocket连接
  void disconnect() {
    _stopHeartbeat();
    _stopReconnect();
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    
    _updateStatus(WebSocketStatus.disconnected);
    _logger.i('WebSocket已断开连接');
  }
  
  // 发送消息
  void send(dynamic message) {
    if (_status != WebSocketStatus.connected) {
      _logger.w('WebSocket未连接，无法发送消息');
      return;
    }
    
    try {
      final String jsonMessage = message is String ? message : jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      _logger.d('WebSocket发送消息: $jsonMessage');
    } catch (e) {
      _logger.e('WebSocket发送消息失败: $e');
    }
  }
  
  // 接收消息处理
  void _onMessage(dynamic message) {
    try {
      _logger.d('WebSocket接收消息: $message');
      
      // 如果是字符串，尝试解析为JSON
      if (message is String) {
        try {
          final jsonMessage = jsonDecode(message);
          _messageController.add(jsonMessage);
        } catch (e) {
          // 如果不是有效的JSON，直接传递字符串
          _messageController.add(message);
        }
      } else {
        // 非字符串消息直接传递
        _messageController.add(message);
      }
    } catch (e) {
      _logger.e('WebSocket处理消息失败: $e');
    }
  }
  
  // 错误处理
  void _onError(dynamic error) {
    _logger.e('WebSocket错误: $error');
    _updateStatus(WebSocketStatus.failed);
    _scheduleReconnect();
  }
  
  // 连接关闭处理
  void _onDone() {
    _logger.w('WebSocket连接已关闭');
    _updateStatus(WebSocketStatus.disconnected);
    _scheduleReconnect();
  }
  
  // 更新连接状态
  void _updateStatus(WebSocketStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }
  
  // 安排重连
  void _scheduleReconnect() {
    _stopHeartbeat();
    _stopReconnect();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _updateStatus(WebSocketStatus.reconnecting);
      
      final delay = _reconnectDelay * _reconnectAttempts;
      _logger.i('安排WebSocket重连，尝试次数: $_reconnectAttempts，延迟: ${delay}ms');
      
      _reconnectTimer = Timer(Duration(milliseconds: delay), () {
        connect();
      });
    } else {
      _logger.e('WebSocket重连失败，已达到最大尝试次数: $_maxReconnectAttempts');
      _updateStatus(WebSocketStatus.failed);
    }
  }
  
  // 停止重连
  void _stopReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }
  
  // 开始心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: _heartbeatInterval), (timer) {
      if (_status == WebSocketStatus.connected) {
        // 发送心跳消息
        send({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch});
      }
    });
  }
  
  // 停止心跳
  void _stopHeartbeat() {
    if (_heartbeatTimer != null && _heartbeatTimer!.isActive) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
    }
  }
  
  // 重置连接
  Future<bool> resetConnection() async {
    disconnect();
    return await connect();
  }
  
  // 释放资源
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}