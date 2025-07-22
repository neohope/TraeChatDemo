import 'package:flutter/material.dart' as flutter;
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/config/app_config.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/app_logger.dart';
import 'data/repositories/settings_repository.dart';
import 'domain/viewmodels/auth_viewmodel.dart';
import 'domain/viewmodels/conversation_viewmodel.dart';
import 'domain/viewmodels/group_viewmodel.dart';
import 'domain/viewmodels/media_viewmodel.dart';
import 'domain/viewmodels/message_viewmodel.dart';
import 'domain/viewmodels/notification_viewmodel.dart';
import 'domain/viewmodels/settings_viewmodel.dart';
import 'domain/viewmodels/user_viewmodel.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/themes/app_theme.dart';

final logger = AppLogger.instance.logger;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置应用方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 初始化本地存储
  await Hive.initFlutter();
  await LocalStorage.init();
  
  // 加载配置
  await AppConfig.instance.load();
  
  // 初始化WebSocket服务
  try {
    // 确保WebSocket服务实例已创建
    logger.i('WebSocket service initialized');
  } catch (e) {
    logger.e('Failed to initialize WebSocket service: $e');
  }
  
  // 初始化Firebase (可选，根据需要)
  try {
    await Firebase.initializeApp();
    logger.i('Firebase initialized successfully');
  } catch (e) {
    logger.w('Failed to initialize Firebase: $e');
  }
  
  // 初始化本地通知
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // 运行应用
  runApp(MultiProvider(
    providers: [
      // 注册视图模型
      ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ChangeNotifierProvider(create: (_) => UserViewModel()),
      ChangeNotifierProvider(create: (_) => MessageViewModel()),
      ChangeNotifierProvider(create: (_) => ConversationViewModel()),
      ChangeNotifierProvider(create: (_) => GroupViewModel()),
      ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ChangeNotifierProvider(create: (_) => MediaViewModel()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, _) {
        // 根据设置选择主题
        final themeMode = settingsViewModel.themeMode;
        
        return flutter.MaterialApp.router(
          title: 'Chat App',
          debugShowCheckedModeBanner: false,
          // 设置主题
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _getThemeMode(themeMode),
          // 使用路由配置
          routerConfig: AppRouter.router,
          // 错误处理
          builder: (context, child) {
            // 添加全局错误处理
            flutter.ErrorWidget.builder = (flutter.FlutterErrorDetails details) {
              return flutter.Material(
                child: flutter.Container(
                  color: flutter.Theme.of(context).scaffoldBackgroundColor,
                  child: flutter.Column(
                    mainAxisAlignment: flutter.MainAxisAlignment.center,
                    children: [
                      const flutter.Icon(
                        flutter.Icons.error_outline,
                        color: flutter.Colors.red,
                        size: 60,
                      ),
                      const flutter.SizedBox(height: 16),
                      flutter.Text(
                        '发生了一个错误',
                        style: flutter.Theme.of(context).textTheme.titleLarge,
                      ),
                      if (AppConfig.instance.isDebug)
                        flutter.Padding(
                          padding: const flutter.EdgeInsets.all(16.0),
                          child: flutter.Text(
                            details.exception.toString(),
                            style: flutter.Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            };
            
            return child!;
          },
        );
      },
    );
  }
  
  // 将应用的主题模式枚举转换为Flutter的ThemeMode
  flutter.ThemeMode _getThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return flutter.ThemeMode.light;
      case ThemeMode.dark:
        return flutter.ThemeMode.dark;
      case ThemeMode.system:
      default:
        return flutter.ThemeMode.system;
    }
  }
}