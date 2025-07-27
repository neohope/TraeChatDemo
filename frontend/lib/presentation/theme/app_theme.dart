import 'package:flutter/material.dart';

/// 应用主题配置类，用于定义应用的颜色、字体和样式
class AppTheme {
  // 私有构造函数，防止外部实例化
  AppTheme._();
  
  // 主题颜色
  static const Color primaryColor = Color(0xFF2196F3);       // 蓝色
  static const Color secondaryColor = Color(0xFF03DAC6);     // 青色
  static const Color accentColor = Color(0xFF03A9F4);        // 浅蓝色
  static const Color errorColor = Color(0xFFB00020);         // 错误红色
  
  // 背景颜色
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);  // 浅灰色
  static const Color darkBackgroundColor = Color(0xFF121212);   // 深灰色
  
  // 文本颜色
  static const Color lightTextColor = Color(0xFF212121);        // 深灰色
  static const Color darkTextColor = Color(0xFFE0E0E0);         // 浅灰色
  static const Color lightSecondaryTextColor = Color(0xFF757575); // 中灰色
  static const Color darkSecondaryTextColor = Color(0xFFAAAAAA);  // 中浅灰色
  
  // 边框颜色
  static const Color lightBorderColor = Color(0xFFE0E0E0);      // 浅灰色
  static const Color darkBorderColor = Color(0xFF424242);       // 深灰色
  
  // 聊天气泡颜色
  static const Color lightSentBubbleColor = Color(0xFFE3F2FD);  // 浅蓝色
  static const Color darkSentBubbleColor = Color(0xFF1565C0);   // 深蓝色
  static const Color lightReceivedBubbleColor = Color(0xFFFFFFFF); // 白色
  static const Color darkReceivedBubbleColor = Color(0xFF2C2C2C); // 深灰色
  
  // 在线状态颜色
  static const Color onlineColor = Color(0xFF4CAF50);          // 绿色
  static const Color offlineColor = Color(0xFF9E9E9E);         // 灰色
  static const Color busyColor = Color(0xFFF44336);            // 红色
  static const Color awayColor = Color(0xFFFF9800);            // 橙色
  
  // 字体大小
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 22.0;
  
  // 圆角大小
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusNormal = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 24.0;
  
  // 间距大小
  static const double spacingTiny = 2.0;
  static const double spacingSmall = 4.0;
  static const double spacingNormal = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingExtraLarge = 24.0;
  
  // 图标大小
  static const double iconSizeSmall = 16.0;
  static const double iconSizeNormal = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
  
  // 头像大小
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeNormal = 40.0;
  static const double avatarSizeLarge = 56.0;
  static const double avatarSizeExtraLarge = 80.0;
  
  // 亮色主题
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: lightTextColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      displayMedium: TextStyle(color: lightTextColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      displaySmall: TextStyle(color: lightTextColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      headlineMedium: TextStyle(color: lightTextColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      headlineSmall: TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      titleMedium: TextStyle(color: lightTextColor, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      titleSmall: TextStyle(color: lightTextColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      bodyLarge: TextStyle(color: lightTextColor, fontSize: 16, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: lightTextColor, fontSize: 14, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: lightSecondaryTextColor, fontSize: 12, fontFamily: 'Roboto'),
      labelLarge: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      labelMedium: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      labelSmall: TextStyle(color: lightSecondaryTextColor, fontSize: 10, fontFamily: 'Roboto'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingNormal,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: lightBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: lightBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: lightBorderColor,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: lightTextColor,
      size: iconSizeNormal,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey[800],
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadiusLarge),
          topRight: Radius.circular(borderRadiusLarge),
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: darkSecondaryTextColor,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .32);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        },
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .32);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        },
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .32);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: .5);
          }
          return Colors.grey.withValues(alpha: .5);
        },
      ),
    ),
  );
  
  // 暗色主题
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: darkTextColor,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkTextColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      displayMedium: TextStyle(color: darkTextColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      displaySmall: TextStyle(color: darkTextColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      headlineMedium: TextStyle(color: darkTextColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      headlineSmall: TextStyle(color: darkTextColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      titleLarge: TextStyle(color: darkTextColor, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      titleMedium: TextStyle(color: darkTextColor, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      titleSmall: TextStyle(color: darkTextColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      bodyLarge: TextStyle(color: darkTextColor, fontSize: 16, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: darkTextColor, fontSize: 14, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: darkSecondaryTextColor, fontSize: 12, fontFamily: 'Roboto'),
      labelLarge: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      labelMedium: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      labelSmall: TextStyle(color: darkSecondaryTextColor, fontSize: 10, fontFamily: 'Roboto'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingNormal,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: darkBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: darkBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorderColor,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: darkTextColor,
      size: iconSizeNormal,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: darkSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey[900],
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadiusLarge),
          topRight: Radius.circular(borderRadiusLarge),
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: lightSecondaryTextColor,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .32);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        },
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .32);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        },
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .32);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: .5);
          }
          return Colors.grey.withValues(alpha: .5);
        },
      ),
    ),
  );
  
  /// 获取聊天气泡颜色
  static Color getSentBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightSentBubbleColor
        : darkSentBubbleColor;
  }
  
  /// 获取接收气泡颜色
  static Color getReceivedBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightReceivedBubbleColor
        : darkReceivedBubbleColor;
  }
  
  /// 获取用户状态颜色
  static Color getUserStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return onlineColor;
      case 'busy':
        return busyColor;
      case 'away':
        return awayColor;
      case 'offline':
      default:
        return offlineColor;
    }
  }
}