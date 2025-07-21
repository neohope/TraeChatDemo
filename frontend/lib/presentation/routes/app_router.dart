import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/viewmodels/auth_viewmodel.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/chat/group_chat_page.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/settings_page.dart';
import '../pages/splash/splash_page.dart';

/// 应用路由配置
class AppRouter {
  // 私有构造函数，防止实例化
  AppRouter._();
  
  // 路由路径常量
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String groupChat = '/group-chat';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // GoRouter 实例
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '$chat/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final userName = state.uri.queryParameters['userName'] ?? '';
          return ChatPage(userId: userId, userName: userName);
        },
      ),
      GoRoute(
        path: '$groupChat/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          final groupName = state.uri.queryParameters['groupName'] ?? '';
          return GroupChatPage(groupId: groupId, groupName: groupName);
        },
      ),
      GoRoute(
        path: profile,
        builder: (context, state) {
          // 不需要 userId 参数
          return const ProfilePage();
        },
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('未找到路由: ${state.uri.path}'),
      ),
    ),
  );
  
  // 路由重定向处理
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    // 获取认证状态
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isAuthenticated = authViewModel.isAuthenticated;
    
    // 不需要认证的路由
    final isAuthRoute = state.matchedLocation == login || 
                        state.matchedLocation == register || 
                        state.matchedLocation == forgotPassword || 
                        state.matchedLocation == splash;
    
    // 如果用户未认证且不是认证相关路由，重定向到登录页面
    if (!isAuthenticated && !isAuthRoute) {
      return login;
    }
    
    // 如果用户已认证且是认证相关路由，重定向到首页
    if (isAuthenticated && isAuthRoute && state.matchedLocation != splash) {
      return home;
    }
    
    // 不需要重定向
    return null;
  }
}