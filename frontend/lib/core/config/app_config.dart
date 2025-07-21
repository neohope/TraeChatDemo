import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

/// 应用配置类，用于管理应用的全局配置
class AppConfig {
  // 单例模式
  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;
  
  AppConfig._internal();
  
  // 配置属性
  late String apiBaseUrl;
  late String wsBaseUrl;
  late bool isDebug;
  late String defaultLanguage;
  late int connectionTimeout;
  late int receiveTimeout;
  late bool encryptionEnabled;
  late Map<String, dynamic> pushNotificationConfig;
  
  // 日志实例
  final logger = AppLogger.instance.logger;
  
  // 加载配置
  Future<void> load() async {
    try {
      // 从assets加载配置文件
      final configString = await rootBundle.loadString('assets/config/app_config.yaml');
      final Map<String, dynamic> config = json.decode(configString);
      
      // 设置配置属性
      apiBaseUrl = config['api_base_url'] ?? 'http://localhost:8080';
      wsBaseUrl = config['ws_base_url'] ?? 'ws://localhost:8080/ws';
      isDebug = config['is_debug'] ?? true;
      defaultLanguage = config['default_language'] ?? 'zh';
      connectionTimeout = config['connection_timeout'] ?? 30000;
      receiveTimeout = config['receive_timeout'] ?? 30000;
      encryptionEnabled = config['encryption_enabled'] ?? false;
      pushNotificationConfig = config['push_notification'] ?? {};
      
      logger.i('配置加载成功');
    } catch (e) {
      logger.e('加载配置失败: $e');
      // 设置默认值
      apiBaseUrl = 'http://localhost:8080';
      wsBaseUrl = 'ws://localhost:8080/ws';
      isDebug = true;
      defaultLanguage = 'zh';
      connectionTimeout = 30000;
      receiveTimeout = 30000;
      encryptionEnabled = false;
      pushNotificationConfig = {};
    }
  }
  
  // 获取环境名称
  String get environmentName => isDebug ? '开发环境' : '生产环境';
  
  // 重新加载配置
  Future<void> reload() async {
    await load();
  }
}