import 'package:flutter/foundation.dart';

import '../../data/models/api_response.dart';
import '../../data/repositories/settings_repository.dart';

/// 设置视图模型，用于管理应用设置相关的UI状态和业务逻辑
class SettingsViewModel extends ChangeNotifier {
  // 设置仓库实例
  final _settingsRepository = SettingsRepository.instance;
  
  // 应用设置
  AppSettings? _settings;
  
  // 加载状态
  bool _isLoading = false;
  // 是否正在更新设置
  bool _isUpdating = false;
  // 错误信息
  String? _errorMessage;
  
  /// 获取应用设置
  AppSettings? get settings => _settings;
  
  /// 获取主题模式
  ThemeMode get themeMode => _settings?.themeMode ?? ThemeMode.system;
  
  /// 获取应用语言
  AppLanguage get language => _settings?.language ?? AppLanguage.system;
  
  /// 获取字体大小
  int get fontSize => _settings?.fontSize ?? 100;
  
  /// 获取聊天背景类型
  ChatBackgroundType get chatBackgroundType => 
      _settings?.chatBackgroundType ?? ChatBackgroundType.solid;
  
  /// 获取聊天背景值
  String? get chatBackgroundValue => _settings?.chatBackgroundValue;
  
  /// 获取通知设置
  bool get enableNotification => _settings?.enableNotification ?? true;
  
  /// 获取自动下载媒体设置
  bool get autoDownloadMedia => _settings?.autoDownloadMedia ?? true;
  
  /// 获取已读回执设置
  bool get enableReadReceipt => _settings?.enableReadReceipt ?? true;
  
  /// 获取隐私模式设置
  bool get enablePrivacyMode => _settings?.enablePrivacyMode ?? false;
  
  /// 获取应用锁设置
  bool get enableAppLock => _settings?.enableAppLock ?? false;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 是否正在更新设置
  bool get isUpdating => _isUpdating;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 构造函数
  SettingsViewModel() {
    // 初始化加载设置
    loadSettings();
  }
  
  /// 加载应用设置
  Future<void> loadSettings() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.getSettings();
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载设置失败');
      }
    } catch (e) {
      _setError('加载设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更新应用设置
  Future<ApiResponse<AppSettings>> updateSettings(AppSettings settings) async {
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateSettings(settings);
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新设置失败: $e');
      return ApiResponse<AppSettings>.error('更新设置失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新主题模式
  Future<ApiResponse<AppSettings>> updateThemeMode(ThemeMode themeMode) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateThemeMode(themeMode);
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新主题模式失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新主题模式失败: $e');
      return ApiResponse<AppSettings>.error('更新主题模式失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新应用语言
  Future<ApiResponse<AppSettings>> updateLanguage(AppLanguage language) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateLanguage(language);
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新应用语言失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新应用语言失败: $e');
      return ApiResponse<AppSettings>.error('更新应用语言失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新字体大小
  Future<ApiResponse<AppSettings>> updateFontSize(int fontSize) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateFontSize(fontSize);
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新字体大小失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新字体大小失败: $e');
      return ApiResponse<AppSettings>.error('更新字体大小失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新聊天背景
  Future<ApiResponse<AppSettings>> updateChatBackground({
    required ChatBackgroundType type,
    required String value,
  }) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateChatBackground(type: type, value: value);
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新聊天背景失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新聊天背景失败: $e');
      return ApiResponse<AppSettings>.error('更新聊天背景失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新通知设置
  Future<ApiResponse<AppSettings>> updateNotificationSettings({
    required bool enableNotification,
    bool enableSound = true,
    bool enableVibration = true,
  }) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateNotificationSettings(
        enableNotification: enableNotification,
        enableSound: enableSound,
        enableVibration: enableVibration,
      );
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新通知设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新通知设置失败: $e');
      return ApiResponse<AppSettings>.error('更新通知设置失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新媒体下载设置
  Future<ApiResponse<AppSettings>> updateMediaDownloadSettings({
    required bool autoDownloadMedia,
    bool autoDownloadOnCellular = false,
  }) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateMediaDownloadSettings(
        autoDownloadMedia: autoDownloadMedia,
        autoDownloadOnCellular: autoDownloadOnCellular,
      );
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新媒体下载设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新媒体下载设置失败: $e');
      return ApiResponse<AppSettings>.error('更新媒体下载设置失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新隐私设置
  Future<ApiResponse<AppSettings>> updatePrivacySettings({
    bool? enableReadReceipt,
    bool? enableTypingIndicator,
    bool? enablePrivacyMode,
  }) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updatePrivacySettings(
        enableReadReceipt: enableReadReceipt ?? _settings!.enableReadReceipt,
        enableTypingIndicator: enableTypingIndicator ?? _settings!.enableTypingIndicator,
        enablePrivacyMode: enablePrivacyMode ?? _settings!.enablePrivacyMode,
      );
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新隐私设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新隐私设置失败: $e');
      return ApiResponse<AppSettings>.error('更新隐私设置失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 更新应用锁设置
  Future<ApiResponse<AppSettings>> updateAppLockSettings({
    required bool enableAppLock,
    String appLockType = 'none',
  }) async {
    if (_settings == null) {
      return ApiResponse<AppSettings>.error('设置未初始化');
    }
    
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.updateAppLockSettings(
        enableAppLock: enableAppLock,
        appLockType: appLockType,
      );
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新应用锁设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新应用锁设置失败: $e');
      return ApiResponse<AppSettings>.error('更新应用锁设置失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 重置所有设置为默认值
  Future<ApiResponse<AppSettings>> resetToDefaults() async {
    _setUpdating(true);
    _clearError();
    
    try {
      final response = await _settingsRepository.resetSettings();
      
      if (response.success && response.data != null) {
        _settings = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '重置设置失败');
      }
      
      return response;
    } catch (e) {
      _setError('重置设置失败: $e');
      return ApiResponse<AppSettings>.error('重置设置失败: $e');
    } finally {
      _setUpdating(false);
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置更新状态
  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}