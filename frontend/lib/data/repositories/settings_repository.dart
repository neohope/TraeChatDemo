import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

/// 应用主题模式枚举
enum ThemeMode {
  /// 跟随系统
  system,
  /// 亮色主题
  light,
  /// 暗色主题
  dark,
}

/// 应用语言枚举
enum AppLanguage {
  /// 跟随系统
  system,
  /// 简体中文
  zhCN,
  /// 繁体中文
  zhTW,
  /// 英文
  enUS,
  /// 日文
  jaJP,
  /// 韩文
  koKR,
}

/// 聊天背景类型枚举
enum ChatBackgroundType {
  /// 纯色
  solid,
  /// 渐变色
  gradient,
  /// 图片
  image,
}

/// 应用设置类
class AppSettings {
  /// 主题模式
  final ThemeMode themeMode;
  /// 应用语言
  final AppLanguage language;
  /// 是否启用通知
  final bool enableNotification;
  /// 是否启用声音
  final bool enableSound;
  /// 是否启用震动
  final bool enableVibration;
  /// 字体大小（百分比，100表示正常大小）
  final int fontSize;
  /// 聊天背景类型
  final ChatBackgroundType chatBackgroundType;
  /// 聊天背景值（颜色代码或图片路径）
  final String chatBackgroundValue;
  /// 是否自动下载媒体文件
  final bool autoDownloadMedia;
  /// 是否在移动网络下自动下载媒体文件
  final bool autoDownloadOnCellular;
  /// 是否启用已读回执
  final bool enableReadReceipt;
  /// 是否启用输入状态提示
  final bool enableTypingIndicator;
  /// 是否启用表情建议
  final bool enableEmojiSuggestions;
  /// 是否启用自动夜间模式
  final bool enableAutoNightMode;
  /// 自动夜间模式开始时间（小时，24小时制）
  final int nightModeStartHour;
  /// 自动夜间模式结束时间（小时，24小时制）
  final int nightModeEndHour;
  /// 是否启用隐私模式（应用切换时模糊内容）
  final bool enablePrivacyMode;
  /// 是否启用应用锁
  final bool enableAppLock;
  /// 应用锁类型（密码、图案、生物识别等）
  final String appLockType;
  /// 自定义设置
  final Map<String, dynamic>? customSettings;
  
  AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.system,
    this.enableNotification = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.fontSize = 100,
    this.chatBackgroundType = ChatBackgroundType.solid,
    this.chatBackgroundValue = '#FFFFFF',
    this.autoDownloadMedia = true,
    this.autoDownloadOnCellular = false,
    this.enableReadReceipt = true,
    this.enableTypingIndicator = true,
    this.enableEmojiSuggestions = true,
    this.enableAutoNightMode = false,
    this.nightModeStartHour = 22,
    this.nightModeEndHour = 6,
    this.enablePrivacyMode = false,
    this.enableAppLock = false,
    this.appLockType = 'none',
    this.customSettings,
  });
  
  /// 从JSON创建设置对象
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: _parseThemeMode(json['theme_mode'] as String?),
      language: _parseAppLanguage(json['language'] as String?),
      enableNotification: json['enable_notification'] as bool? ?? true,
      enableSound: json['enable_sound'] as bool? ?? true,
      enableVibration: json['enable_vibration'] as bool? ?? true,
      fontSize: json['font_size'] as int? ?? 100,
      chatBackgroundType: _parseChatBackgroundType(json['chat_background_type'] as String?),
      chatBackgroundValue: json['chat_background_value'] as String? ?? '#FFFFFF',
      autoDownloadMedia: json['auto_download_media'] as bool? ?? true,
      autoDownloadOnCellular: json['auto_download_on_cellular'] as bool? ?? false,
      enableReadReceipt: json['enable_read_receipt'] as bool? ?? true,
      enableTypingIndicator: json['enable_typing_indicator'] as bool? ?? true,
      enableEmojiSuggestions: json['enable_emoji_suggestions'] as bool? ?? true,
      enableAutoNightMode: json['enable_auto_night_mode'] as bool? ?? false,
      nightModeStartHour: json['night_mode_start_hour'] as int? ?? 22,
      nightModeEndHour: json['night_mode_end_hour'] as int? ?? 6,
      enablePrivacyMode: json['enable_privacy_mode'] as bool? ?? false,
      enableAppLock: json['enable_app_lock'] as bool? ?? false,
      appLockType: json['app_lock_type'] as String? ?? 'none',
      customSettings: json['custom_settings'] != null ? Map<String, dynamic>.from(json['custom_settings']) : null,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode.toString().split('.').last,
      'language': language.toString().split('.').last,
      'enable_notification': enableNotification,
      'enable_sound': enableSound,
      'enable_vibration': enableVibration,
      'font_size': fontSize,
      'chat_background_type': chatBackgroundType.toString().split('.').last,
      'chat_background_value': chatBackgroundValue,
      'auto_download_media': autoDownloadMedia,
      'auto_download_on_cellular': autoDownloadOnCellular,
      'enable_read_receipt': enableReadReceipt,
      'enable_typing_indicator': enableTypingIndicator,
      'enable_emoji_suggestions': enableEmojiSuggestions,
      'enable_auto_night_mode': enableAutoNightMode,
      'night_mode_start_hour': nightModeStartHour,
      'night_mode_end_hour': nightModeEndHour,
      'enable_privacy_mode': enablePrivacyMode,
      'enable_app_lock': enableAppLock,
      'app_lock_type': appLockType,
      'custom_settings': customSettings,
    };
  }
  
  /// 创建设置副本并更新指定字段
  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? enableNotification,
    bool? enableSound,
    bool? enableVibration,
    int? fontSize,
    ChatBackgroundType? chatBackgroundType,
    String? chatBackgroundValue,
    bool? autoDownloadMedia,
    bool? autoDownloadOnCellular,
    bool? enableReadReceipt,
    bool? enableTypingIndicator,
    bool? enableEmojiSuggestions,
    bool? enableAutoNightMode,
    int? nightModeStartHour,
    int? nightModeEndHour,
    bool? enablePrivacyMode,
    bool? enableAppLock,
    String? appLockType,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      enableNotification: enableNotification ?? this.enableNotification,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      fontSize: fontSize ?? this.fontSize,
      chatBackgroundType: chatBackgroundType ?? this.chatBackgroundType,
      chatBackgroundValue: chatBackgroundValue ?? this.chatBackgroundValue,
      autoDownloadMedia: autoDownloadMedia ?? this.autoDownloadMedia,
      autoDownloadOnCellular: autoDownloadOnCellular ?? this.autoDownloadOnCellular,
      enableReadReceipt: enableReadReceipt ?? this.enableReadReceipt,
      enableTypingIndicator: enableTypingIndicator ?? this.enableTypingIndicator,
      enableEmojiSuggestions: enableEmojiSuggestions ?? this.enableEmojiSuggestions,
      enableAutoNightMode: enableAutoNightMode ?? this.enableAutoNightMode,
      nightModeStartHour: nightModeStartHour ?? this.nightModeStartHour,
      nightModeEndHour: nightModeEndHour ?? this.nightModeEndHour,
      enablePrivacyMode: enablePrivacyMode ?? this.enablePrivacyMode,
      enableAppLock: enableAppLock ?? this.enableAppLock,
      appLockType: appLockType ?? this.appLockType,
      customSettings: customSettings ?? this.customSettings,
    );
  }
  
  /// 解析主题模式
  static ThemeMode _parseThemeMode(String? modeStr) {
    if (modeStr == null) return ThemeMode.system;
    
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// 解析应用语言
  static AppLanguage _parseAppLanguage(String? langStr) {
    if (langStr == null) return AppLanguage.system;
    
    switch (langStr) {
      case 'zhCN':
        return AppLanguage.zhCN;
      case 'zhTW':
        return AppLanguage.zhTW;
      case 'enUS':
        return AppLanguage.enUS;
      case 'jaJP':
        return AppLanguage.jaJP;
      case 'koKR':
        return AppLanguage.koKR;
      default:
        return AppLanguage.system;
    }
  }
  
  /// 解析聊天背景类型
  static ChatBackgroundType _parseChatBackgroundType(String? typeStr) {
    if (typeStr == null) return ChatBackgroundType.solid;
    
    switch (typeStr) {
      case 'gradient':
        return ChatBackgroundType.gradient;
      case 'image':
        return ChatBackgroundType.image;
      default:
        return ChatBackgroundType.solid;
    }
  }
}

/// 设置仓库类，用于管理应用设置和用户偏好
class SettingsRepository {
  // 单例模式
  static final SettingsRepository _instance = SettingsRepository._internal();
  static SettingsRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  SettingsRepository._internal();
  
  /// 获取应用设置
  Future<ApiResponse<AppSettings>> getSettings() async {
    try {
      // 尝试从本地获取
      final localSettingsData = await LocalStorage.getSettings();
      if (localSettingsData != null) {
        final localSettings = AppSettings.fromJson(localSettingsData);
        _logger.i('从本地加载设置成功');
        return ApiResponse<AppSettings>.success(localSettings);
      }

      // 检查用户是否已认证
      final isAuthenticated = await _apiService.isAuthenticated();
      if (!isAuthenticated) {
        _logger.i('用户未认证，返回默认设置');
        final defaultSettings = AppSettings();
        await LocalStorage.saveSettings(defaultSettings);
        return ApiResponse<AppSettings>.success(defaultSettings, message: '用户未认证，使用默认设置');
      }

      // 如果本地没有，并且用户已认证，则从服务器获取
      _logger.i('尝试从服务器获取设置');
      final response = await _apiService.get<Map<String, dynamic>>('/api/v1/settings');

      if (response.success && response.data != null) {
        _logger.i('从服务器获取设置成功');
        final settings = AppSettings.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveSettings(settings);
        return ApiResponse<AppSettings>.success(settings);
      } else {
        _logger.w('从服务器获取设置失败，返回默认设置');
        // 如果服务器获取失败，则返回默认设置
        final defaultSettings = AppSettings();
        await LocalStorage.saveSettings(defaultSettings);
        return ApiResponse<AppSettings>.success(defaultSettings, message: '无法从服务器获取设置，使用默认设置');
      }
    } catch (e) {
      _logger.e('获取应用设置失败: $e');

      // 发生任何异常都返回默认设置
      final defaultSettings = AppSettings();
      await LocalStorage.saveSettings(defaultSettings);
      return ApiResponse<AppSettings>.success(defaultSettings, message: '获取设置时发生错误，使用默认设置');
    }
  }
  
  /// 更新应用设置
  Future<ApiResponse<AppSettings>> updateSettings(AppSettings settings) async {
    try {
      // 保存到本地存储
      await LocalStorage.saveSettings(settings);
      
      // 同步到服务器
      final response = await _apiService.put<Map<String, dynamic>>(
        '/settings',
        data: settings.toJson(),
      );
      
      if (response.success) {
        return ApiResponse<AppSettings>.success(settings);
      } else {
        // 即使服务器同步失败，本地设置也已更新
        return ApiResponse<AppSettings>.success(settings, message: '设置已保存到本地，但同步到服务器失败');
      }
    } catch (e) {
      _logger.e('更新应用设置失败: $e');
      
      // 尝试只保存到本地
      try {
        await LocalStorage.saveSettings(settings);
        return ApiResponse<AppSettings>.success(settings, message: '设置已保存到本地，但同步到服务器失败');
      } catch (localError) {
        _logger.e('保存设置到本地失败: $localError');
        return ApiResponse<AppSettings>.error('更新应用设置失败: $e');
      }
    }
  }
  
  /// 更新主题模式
  Future<ApiResponse<AppSettings>> updateThemeMode(ThemeMode themeMode) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新主题模式
      final updatedSettings = currentSettingsResponse.data!.copyWith(themeMode: themeMode);
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新主题模式失败: $e');
      return ApiResponse<AppSettings>.error('更新主题模式失败: $e');
    }
  }
  
  /// 更新应用语言
  Future<ApiResponse<AppSettings>> updateLanguage(AppLanguage language) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新语言
      final updatedSettings = currentSettingsResponse.data!.copyWith(language: language);
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新应用语言失败: $e');
      return ApiResponse<AppSettings>.error('更新应用语言失败: $e');
    }
  }
  
  /// 更新字体大小
  Future<ApiResponse<AppSettings>> updateFontSize(int fontSize) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新字体大小
      final updatedSettings = currentSettingsResponse.data!.copyWith(fontSize: fontSize);
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新字体大小失败: $e');
      return ApiResponse<AppSettings>.error('更新字体大小失败: $e');
    }
  }
  
  /// 更新聊天背景
  Future<ApiResponse<AppSettings>> updateChatBackground({
    required ChatBackgroundType type,
    required String value,
  }) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新聊天背景
      final updatedSettings = currentSettingsResponse.data!.copyWith(
        chatBackgroundType: type,
        chatBackgroundValue: value,
      );
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新聊天背景失败: $e');
      return ApiResponse<AppSettings>.error('更新聊天背景失败: $e');
    }
  }
  
  /// 更新通知设置
  Future<ApiResponse<AppSettings>> updateNotificationSettings({
    required bool enableNotification,
    required bool enableSound,
    required bool enableVibration,
  }) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新通知设置
      final updatedSettings = currentSettingsResponse.data!.copyWith(
        enableNotification: enableNotification,
        enableSound: enableSound,
        enableVibration: enableVibration,
      );
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新通知设置失败: $e');
      return ApiResponse<AppSettings>.error('更新通知设置失败: $e');
    }
  }
  
  /// 更新媒体下载设置
  Future<ApiResponse<AppSettings>> updateMediaDownloadSettings({
    required bool autoDownloadMedia,
    required bool autoDownloadOnCellular,
  }) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新媒体下载设置
      final updatedSettings = currentSettingsResponse.data!.copyWith(
        autoDownloadMedia: autoDownloadMedia,
        autoDownloadOnCellular: autoDownloadOnCellular,
      );
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新媒体下载设置失败: $e');
      return ApiResponse<AppSettings>.error('更新媒体下载设置失败: $e');
    }
  }
  
  /// 更新隐私设置
  Future<ApiResponse<AppSettings>> updatePrivacySettings({
    required bool enableReadReceipt,
    required bool enableTypingIndicator,
    required bool enablePrivacyMode,
  }) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新隐私设置
      final updatedSettings = currentSettingsResponse.data!.copyWith(
        enableReadReceipt: enableReadReceipt,
        enableTypingIndicator: enableTypingIndicator,
        enablePrivacyMode: enablePrivacyMode,
      );
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新隐私设置失败: $e');
      return ApiResponse<AppSettings>.error('更新隐私设置失败: $e');
    }
  }
  
  /// 更新应用锁设置
  Future<ApiResponse<AppSettings>> updateAppLockSettings({
    required bool enableAppLock,
    required String appLockType,
  }) async {
    try {
      // 获取当前设置
      final currentSettingsResponse = await getSettings();
      if (!currentSettingsResponse.success) {
        return ApiResponse<AppSettings>.error(currentSettingsResponse.message ?? '获取当前设置失败');
      }
      
      // 更新应用锁设置
      final updatedSettings = currentSettingsResponse.data!.copyWith(
        enableAppLock: enableAppLock,
        appLockType: appLockType,
      );
      return await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('更新应用锁设置失败: $e');
      return ApiResponse<AppSettings>.error('更新应用锁设置失败: $e');
    }
  }
  
  /// 重置所有设置为默认值
  Future<ApiResponse<AppSettings>> resetSettings() async {
    try {
      final defaultSettings = AppSettings();
      return await updateSettings(defaultSettings);
    } catch (e) {
      _logger.e('重置设置失败: $e');
      return ApiResponse<AppSettings>.error('重置设置失败: $e');
    }
  }
}