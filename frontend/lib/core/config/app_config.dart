import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
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
  late FirebaseOptions firebaseOptions;
  
  // 日志实例
  final logger = AppLogger.instance.logger;
  
  // 加载配置
  Future<void> load() async {
    try {
      // 从assets加载配置文件
      final configString = await rootBundle.loadString('assets/config/app_config.yaml');
      final dynamic yamlData = loadYaml(configString);
      final Map<String, dynamic> config = Map<String, dynamic>.from(yamlData);
      
      // 设置配置属性
      apiBaseUrl = config['api_base_url'] ?? 'http://localhost:8080';
      wsBaseUrl = config['ws_base_url'] ?? 'ws://localhost:8080/ws';
      isDebug = config['is_debug'] ?? true;
      defaultLanguage = config['default_language'] ?? 'zh';
      connectionTimeout = config['connection_timeout'] ?? 30000;
      receiveTimeout = config['receive_timeout'] ?? 30000;
      encryptionEnabled = config['encryption_enabled'] ?? false;
      pushNotificationConfig = Map<String, dynamic>.from(config['push_notification'] ?? {});

      if (kIsWeb) {
        final firebaseConfig = Map<String, dynamic>.from(config['firebase_web_config'] ?? {});
        firebaseOptions = FirebaseOptions(
          apiKey: firebaseConfig['apiKey'] ?? '',
          authDomain: firebaseConfig['authDomain'] ?? '',
          projectId: firebaseConfig['projectId'] ?? '',
          storageBucket: firebaseConfig['storageBucket'] ?? '',
          messagingSenderId: firebaseConfig['messagingSenderId'] ?? '',
          appId: firebaseConfig['appId'] ?? '',
        );
      }
      
      logger.i('配置加载成功');
    } catch (e, s) {
       logger.e('无法加载配置', e, s);
      // 设置默认值
      apiBaseUrl = 'http://localhost:8080';
      wsBaseUrl = 'ws://localhost:8080/ws';
      isDebug = true;
      defaultLanguage = 'zh';
      connectionTimeout = 30000;
      receiveTimeout = 30000;
      encryptionEnabled = false;
      pushNotificationConfig = {};
      if (kIsWeb) {
        firebaseOptions = const FirebaseOptions(
          apiKey: '',
          authDomain: '',
          projectId: '',
          storageBucket: '',
          messagingSenderId: '',
          appId: '',
        );
      }
    }
  }
  
  // 获取环境名称
  String get environmentName => isDebug ? '开发环境' : '生产环境';
  
  // 重新加载配置
  Future<void> reload() async {
    await load();
  }
}