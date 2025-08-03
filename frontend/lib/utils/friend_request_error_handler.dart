import 'package:flutter/material.dart';

/// 好友请求错误处理工具类
/// 提供统一的友好错误提示
class FriendRequestErrorHandler {
  /// 显示好友请求成功的提示
  static void showSuccessMessage(
    BuildContext context,
    String displayName, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('已向 $displayName 发送好友请求'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 显示好友请求错误的友好提示
  static void showErrorMessage(
    BuildContext context,
    String displayName,
    dynamic error, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    String errorMessage;
    Color backgroundColor;
    IconData iconData;
    
    // 检查特定的错误类型并提供友好的提示
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('users are already friends')) {
      errorMessage = '您和 $displayName 已经是好友了 😊';
      backgroundColor = Colors.blue;
      iconData = Icons.people;
    } else if (errorString.contains('friend request already exists')) {
      errorMessage = '您已经向 $displayName 发送过好友请求，请耐心等待对方回复 ⏳';
      backgroundColor = Colors.orange;
      iconData = Icons.schedule;
    } else if (errorString.contains('已经发送过好友请求')) {
      errorMessage = '您已经向 $displayName 发送过好友请求，请耐心等待对方回复 ⏳';
      backgroundColor = Colors.orange;
      iconData = Icons.schedule;
    } else if (errorString.contains('user not found')) {
      errorMessage = '用户不存在，请检查用户信息 🔍';
      backgroundColor = Colors.grey;
      iconData = Icons.person_off;
    } else if (errorString.contains('network')) {
      errorMessage = '网络连接失败，请检查网络后重试 📶';
      backgroundColor = Colors.red;
      iconData = Icons.wifi_off;
    } else if (errorString.contains('timeout')) {
      errorMessage = '请求超时，请稍后重试 ⏰';
      backgroundColor = Colors.red;
      iconData = Icons.access_time;
    } else {
      errorMessage = '发送好友请求失败，请稍后重试 🔄';
      backgroundColor = Colors.red;
      iconData = Icons.error;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              iconData,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: backgroundColor == Colors.red
            ? SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: () {
                  // 可以在这里添加重试逻辑
                },
              )
            : null,
      ),
    );
  }

  /// 处理好友请求的通用方法
  static Future<void> handleFriendRequest(
    BuildContext context,
    String displayName,
    Future<void> Function() requestFunction,
  ) async {
    try {
      await requestFunction();
      if (context.mounted) {
        showSuccessMessage(context, displayName);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorMessage(context, displayName, e);
      }
    }
  }
}