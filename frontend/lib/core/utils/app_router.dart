import 'package:flutter/material.dart';

// 导入页面
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/chat/chat_page.dart';
import '../../presentation/pages/chat/group_chat_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/profile/settings_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';

/// 应用路由器，用于管理应用的导航
class AppRouter {
  // 路由名称常量
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String groupChat = '/group-chat';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // 初始路由
  static String get initialRoute => splash;
  
  // 路由生成器
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';
    switch (routeName) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            userId: args?['userId'] as String? ?? '',
            userName: args?['userName'] as String? ?? '',
          ),
        );
      case '/group-chat':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => GroupChatPage(
            groupId: args?['groupId'] as String? ?? '',
            groupName: args?['groupName'] as String? ?? '',
          ),
        );
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        // 未知路由
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('未找到路由: ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  // 导航到指定页面
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }
  
  // 替换当前页面
  static Future<T?> navigateToReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(context, routeName, arguments: arguments);
  }
  
  // 清除所有页面并导航到指定页面
  static Future<T?> navigateToAndClearStack<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(context, routeName, (route) => false, arguments: arguments);
  }
  
  // 返回上一页
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}