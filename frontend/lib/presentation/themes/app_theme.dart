import 'package:flutter/material.dart';

/// 应用主题配置
class AppTheme {
  // 私有构造函数，防止实例化
  AppTheme._();
  
  // 颜色常量
  static const Color primaryColor = Color(0xFF2196F3);      // 主色调
  static const Color primaryDarkColor = Color(0xFF1976D2);   // 深色主色调
  static const Color accentColor = Color(0xFF03A9F4);        // 强调色
  
  // 亮色主题背景色
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightCardColor = Colors.white;
  static const Color lightDividerColor = Color(0xFFE0E0E0);
  
  // 暗色主题背景色
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkDividerColor = Color(0xFF323232);
  
  // 文本颜色
  static const Color lightTextColor = Color(0xFF212121);     // 亮色主题文本
  static const Color lightSecondaryTextColor = Color(0xFF757575); // 亮色主题次要文本
  static const Color darkTextColor = Color(0xFFE0E0E0);      // 暗色主题文本
  static const Color darkSecondaryTextColor = Color(0xFF9E9E9E); // 暗色主题次要文本
  
  // 聊天气泡颜色
  static const Color sentMessageBubbleLight = Color(0xFFE3F2FD);
  static const Color receivedMessageBubbleLight = Color(0xFFFFFFFF);
  static const Color sentMessageBubbleDark = Color(0xFF1565C0);
  static const Color receivedMessageBubbleDark = Color(0xFF2C2C2C);
  
  // 用户状态颜色
  static const Color onlineStatusColor = Color(0xFF4CAF50);
  static const Color offlineStatusColor = Color(0xFF9E9E9E);
  static const Color busyStatusColor = Color(0xFFF44336);
  static const Color awayStatusColor = Color(0xFFFF9800);
  
  // 尺寸常量
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusNormal = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingNormal = 16.0;
  static const double spacingLarge = 24.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeNormal = 24.0;
  static const double iconSizeMedium = 28.0;
  static const double iconSizeLarge = 32.0;
  
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeNormal = 40.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 56.0;
  
  // 亮色主题
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    primaryColorDark: primaryDarkColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: lightBackgroundColor,
    ),
    scaffoldBackgroundColor: lightBackgroundColor,
    cardColor: lightCardColor,
    dividerColor: lightDividerColor,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightTextColor, fontSize: fontSizeNormal, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: lightTextColor, fontSize: fontSizeNormal, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: lightSecondaryTextColor, fontSize: fontSizeSmall, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: lightTextColor, fontSize: fontSizeLarge, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      titleMedium: TextStyle(color: lightTextColor, fontSize: fontSizeMedium, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      titleSmall: TextStyle(color: lightTextColor, fontSize: fontSizeNormal, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
        padding: const EdgeInsets.symmetric(vertical: spacingNormal, horizontal: spacingLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: lightDividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: lightDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingNormal, vertical: spacingNormal),
    ),
  );
  
  // 暗色主题
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    primaryColorDark: primaryDarkColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: darkBackgroundColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    dividerColor: darkDividerColor,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkTextColor, fontSize: fontSizeNormal, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: darkTextColor, fontSize: fontSizeNormal, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: darkSecondaryTextColor, fontSize: fontSizeSmall, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: darkTextColor, fontSize: fontSizeLarge, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      titleMedium: TextStyle(color: darkTextColor, fontSize: fontSizeMedium, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      titleSmall: TextStyle(color: darkTextColor, fontSize: fontSizeNormal, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCardColor,
      foregroundColor: darkTextColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
        padding: const EdgeInsets.symmetric(vertical: spacingNormal, horizontal: spacingLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: darkDividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: darkDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingNormal, vertical: spacingNormal),
    ),
  );
  
  // 获取聊天气泡颜色
  static Color getChatBubbleColor(bool isSent, bool isDarkMode) {
    if (isSent) {
      return isDarkMode ? sentMessageBubbleDark : sentMessageBubbleLight;
    } else {
      return isDarkMode ? receivedMessageBubbleDark : receivedMessageBubbleLight;
    }
  }
  
  // 获取用户状态颜色
  static Color getUserStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return onlineStatusColor;
      case 'busy':
        return busyStatusColor;
      case 'away':
        return awayStatusColor;
      case 'offline':
      default:
        return offlineStatusColor;
    }
  }
  
  // 获取状态颜色
  static Color getStatusColor(dynamic status) {
    if (status is String) {
      return getUserStatusColor(status);
    } else if (status.toString().contains('.')) {
      // 处理枚举类型
      return getUserStatusColor(status.toString().split('.').last);
    } else {
      return offlineStatusColor;
    }
  }
}