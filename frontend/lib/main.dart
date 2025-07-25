import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/config/app_config.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/app_logger.dart';
import 'core/services/api_service.dart';
import 'core/services/websocket_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/file_service.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/settings_repository.dart' as settings_repository;
import 'domain/viewmodels/conversation_viewmodel.dart';
import 'domain/viewmodels/settings_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart' as presentation;
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/message_viewmodel.dart' as presentation;
import 'presentation/viewmodels/group_viewmodel.dart' as presentation;
import 'presentation/viewmodels/notification_viewmodel.dart' as presentation;
import 'presentation/viewmodels/voice_message_viewmodel.dart';
import 'presentation/viewmodels/file_transfer_viewmodel.dart';
import 'presentation/widgets/auth/login_widget.dart';
import 'presentation/widgets/main/main_screen_widget.dart';

final logger = AppLogger.instance.logger;

/// 初始化应用服务
Future<void> _initializeServices() async {
  try {
    logger.i('Initializing TraeChat application services...');
    
    // 初始化音频服务
    await AudioService().initialize();
    logger.i('Audio service initialized');
    
    // 初始化文件服务
    await FileService().initialize();
    logger.i('File service initialized');
    
    // 初始化通知服务
    await NotificationService().initialize();
    logger.i('Notification service initialized');
    
    logger.i('All services initialized successfully');
  } catch (e) {
    logger.e('Failed to initialize services: $e');
    rethrow;
  }
}

/// Firebase后台消息处理器
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.i('Handling a background message: ${message.messageId}');
}

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
  
  // 初始化服务
  await _initializeServices();
  
  // 初始化Firebase
  try {
    await Firebase.initializeApp();
    logger.i('Firebase initialized successfully');
    
    // 设置后台消息处理器
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    logger.i('Notification service initialized successfully');
  } catch (e) {
    logger.w('Failed to initialize Firebase or Notification service: $e');
  }
  
  // 运行应用
  runApp(MultiProvider(
    providers: [
      // 服务提供者
      Provider<ApiService>(create: (_) => ApiService()),
      Provider<WebSocketService>(create: (_) => WebSocketService()),
      Provider<AudioService>(create: (_) => AudioService()),
      Provider<FileService>(create: (_) => FileService()),
      Provider<NotificationService>(create: (_) => NotificationService()),
      
      // Domain ViewModels
      ChangeNotifierProvider(create: (_) => ConversationViewModel()),
      ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      
      // Presentation ViewModels
      ChangeNotifierProvider(create: (context) => presentation.AuthViewModel(
        context.read<ApiService>(),
      )),
      // ChangeNotifierProvider(create: (context) => presentation.UserViewModel(
      //   context.read<ApiService>(),
      // )),
      ChangeNotifierProvider(create: (context) => ChatViewModel(
        context.read<ApiService>(),
        context.read<WebSocketService>(),
      )),
      ChangeNotifierProvider(create: (_) => presentation.MessageViewModel()),
      // ChangeNotifierProvider(create: (context) => FriendViewModel(
      //   friendRepository: FriendRepository.instance,
      //   notificationService: context.read<NotificationService>(),
      // )),
      ChangeNotifierProvider(create: (context) => presentation.GroupViewModel()),
      ChangeNotifierProvider(create: (context) => presentation.NotificationViewModel()),
      ChangeNotifierProvider(create: (context) => VoiceMessageViewModel()),
      ChangeNotifierProvider(create: (context) => FileTransferViewModel()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        return MaterialApp(
          title: 'TraeChat',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: _convertThemeMode(settingsViewModel.themeMode),
          debugShowCheckedModeBanner: false,
          home: Consumer<presentation.AuthViewModel>(
            builder: (context, authViewModel, child) {
              if (authViewModel.isAuthenticated) {
                 return const MainScreenWidget();
               } else {
                 return const LoginWidget();
               }
             },
           ),
         );
       },
     );
   }
 
   /// 转换主题模式
   ThemeMode _convertThemeMode(settings_repository.ThemeMode themeMode) {
     switch (themeMode) {
       case settings_repository.ThemeMode.light:
         return ThemeMode.light;
       case settings_repository.ThemeMode.dark:
         return ThemeMode.dark;
       case settings_repository.ThemeMode.system:
       default:
         return ThemeMode.system;
     }
   }

  
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
  
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}