import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// 本地存储工具类，用于管理应用的本地数据存储
class LocalStorage {
  // Hive盒子名称
  static const String _settingsBoxName = 'settings';
  static const String _userBoxName = 'user';
  static const String _chatBoxName = 'chat';
  static const String _cacheBoxName = 'cache';
  
  // 安全存储键名
  static const String _encryptionKeyName = 'encryption_key';
  static const String _tokenKeyName = 'auth_token';
  static const String _refreshTokenKeyName = 'refresh_token';
  
  // 盒子实例
  static late Box _settingsBox;
  static late Box _userBox;
  static late Box _chatBox;
  static late Box _cacheBox;
  
  // 安全存储实例
  static final _secureStorage = FlutterSecureStorage();
  
  // 日志实例
  static final _logger = AppLogger.instance.logger;
  
  // 初始化本地存储
  static Future<void> init() async {
    try {
      // 初始化Hive
      await Hive.initFlutter();
      
      // 获取加密密钥或生成新密钥
      final encryptionKey = await _getEncryptionKey();
      
      // 打开加密盒子
      _settingsBox = await Hive.openBox(
        _settingsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      
      _userBox = await Hive.openBox(
        _userBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      
      _chatBox = await Hive.openBox(
        _chatBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      
      // 缓存盒子不加密
      _cacheBox = await Hive.openBox(_cacheBoxName);
      
      _logger.i('本地存储初始化成功');
    } catch (e) {
      _logger.e('初始化本地存储失败: $e');
      // 如果加密初始化失败，尝试非加密方式打开
      try {
        _settingsBox = await Hive.openBox(_settingsBoxName);
        _userBox = await Hive.openBox(_userBoxName);
        _chatBox = await Hive.openBox(_chatBoxName);
        _cacheBox = await Hive.openBox(_cacheBoxName);
        _logger.i('本地存储以非加密方式初始化成功');
      } catch (e) {
        _logger.e('非加密方式初始化本地存储也失败: $e');
        rethrow;
      }
    }
  }
  
  // 获取加密密钥
  static Future<List<int>> _getEncryptionKey() async {
    try {
      // 尝试从安全存储中获取密钥
      String? encryptionKeyString = await _secureStorage.read(key: _encryptionKeyName);
      
      if (encryptionKeyString == null) {
        // 生成新密钥
        final key = Hive.generateSecureKey();
        // 将密钥转换为字符串并存储
        encryptionKeyString = key.join(',');
        await _secureStorage.write(key: _encryptionKeyName, value: encryptionKeyString);
        return key;
      } else {
        // 将字符串转换回密钥
        return encryptionKeyString.split(',').map(int.parse).toList();
      }
    } catch (e) {
      _logger.e('获取加密密钥失败: $e');
      // 返回默认密钥
      return List.generate(32, (index) => index);
    }
  }
  
  // 保存设置
  static Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      _logger.e('保存设置失败: $e');
    }
  }
  
  // 获取设置
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      return _settingsBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      _logger.e('获取设置失败: $e');
      return defaultValue;
    }
  }
  
  // 保存用户数据
  static Future<void> saveUserData(String key, dynamic value) async {
    try {
      await _userBox.put(key, value);
    } catch (e) {
      _logger.e('保存用户数据失败: $e');
    }
  }
  
  // 获取用户数据
  static dynamic getUserData(String key, {dynamic defaultValue}) {
    try {
      return _userBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      _logger.e('获取用户数据失败: $e');
      return defaultValue;
    }
  }
  
  // 保存聊天数据
  static Future<void> saveChatData(String key, dynamic value) async {
    try {
      await _chatBox.put(key, value);
    } catch (e) {
      _logger.e('保存聊天数据失败: $e');
    }
  }
  
  // 获取聊天数据
  static dynamic getChatData(String key, {dynamic defaultValue}) {
    try {
      return _chatBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      _logger.e('获取聊天数据失败: $e');
      return defaultValue;
    }
  }
  
  // 保存缓存数据
  static Future<void> saveCache(String key, dynamic value) async {
    try {
      await _cacheBox.put(key, value);
    } catch (e) {
      _logger.e('保存缓存数据失败: $e');
    }
  }
  
  // 获取缓存数据
  static dynamic getCache(String key, {dynamic defaultValue}) {
    try {
      return _cacheBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      _logger.e('获取缓存数据失败: $e');
      return defaultValue;
    }
  }
  
  // 清除缓存
  static Future<void> clearCache() async {
    try {
      await _cacheBox.clear();
    } catch (e) {
      _logger.e('清除缓存失败: $e');
    }
  }
  
  // 保存认证令牌
  static Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKeyName, value: token);
    } catch (e) {
      _logger.e('保存认证令牌失败: $e');
    }
  }
  
  // 获取认证令牌
  static Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: _tokenKeyName);
    } catch (e) {
      _logger.e('获取认证令牌失败: $e');
      return null;
    }
  }
  
  // 实例方法包装器，用于兼容性
  Future<String?> getString(String key) async {
    return getSetting(key)?.toString();
  }
  
  Future<void> setString(String key, String value) async {
    await saveSetting(key, value);
  }
  
  Future<List<String>?> getStringList(String key) async {
    final value = getSetting(key);
    if (value is List) {
      return value.cast<String>();
    }
    return null;
  }
  
  Future<void> setStringList(String key, List<String> value) async {
    await saveSetting(key, value);
  }
  
  Future<bool?> getBool(String key) async {
    return getSetting(key) as bool?;
  }
  
  Future<void> setBool(String key, bool value) async {
    await saveSetting(key, value);
  }
  
  Future<int?> getInt(String key) async {
    return getSetting(key) as int?;
  }
  
  Future<void> setInt(String key, int value) async {
    await saveSetting(key, value);
  }
  
  Future<double?> getDouble(String key) async {
    return getSetting(key) as double?;
  }
  
  Future<void> setDouble(String key, double value) async {
    await saveSetting(key, value);
  }
  
  // 保存刷新令牌
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _refreshTokenKeyName, value: token);
    } catch (e) {
      _logger.e('保存刷新令牌失败: $e');
    }
  }
  
  // 获取刷新令牌
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKeyName);
    } catch (e) {
      _logger.e('获取刷新令牌失败: $e');
      return null;
    }
  }
  
  // 清除认证信息
  static Future<void> clearAuthInfo() async {
    try {
      await _secureStorage.delete(key: _tokenKeyName);
      await _secureStorage.delete(key: _refreshTokenKeyName);
    } catch (e) {
      _logger.e('清除认证信息失败: $e');
    }
  }
  
  // 清除所有数据
  static Future<void> clearAll() async {
    try {
      await _settingsBox.clear();
      await _userBox.clear();
      await _chatBox.clear();
      await _cacheBox.clear();
      await clearAuthInfo();
      _logger.i('所有本地数据已清除');
    } catch (e) {
      _logger.e('清除所有数据失败: $e');
    }
  }
  
  // 保存当前用户
  static Future<void> saveCurrentUser(dynamic user) async {
    try {
      await saveUserData('current_user', user);
      _logger.i('当前用户已保存到本地存储');
    } catch (e) {
      _logger.e('保存当前用户失败: $e');
    }
  }
  
  // 获取当前用户
  static Future<dynamic> getCurrentUser() async {
    try {
      return getUserData('current_user');
    } catch (e) {
      _logger.e('获取当前用户失败: $e');
      return null;
    }
  }
  
  // 获取用户ID
  static Future<String?> getUserId() async {
    try {
      final user = getUserData('current_user');
      if (user != null && user['id'] != null) {
        return user['id'].toString();
      }
      return null;
    } catch (e) {
      _logger.e('获取用户ID失败: $e');
      return null;
    }
  }
  
  // 清除认证数据
  static Future<void> clearAuthData() async {
    try {
      await clearAuthInfo();
      await saveUserData('current_user', null);
      _logger.i('认证数据已清除');
    } catch (e) {
      _logger.e('清除认证数据失败: $e');
    }
  }
  
  // 保存会话
  static Future<void> saveConversation(dynamic conversation) async {
    try {
      final String conversationId = conversation.id;
      await saveChatData('conversation_$conversationId', conversation.toJson());
      _logger.i('会话已保存到本地存储: $conversationId');
    } catch (e) {
      _logger.e('保存会话失败: $e');
    }
  }
  
  // 获取会话
  static Future<dynamic> getConversation(String conversationId) async {
    try {
      final data = getChatData('conversation_$conversationId');
      if (data == null) return null;
      
      // 导入Conversation类并创建实例
      // 这里需要在使用的地方导入Conversation类并使用fromJson方法
      return data;
    } catch (e) {
      _logger.e('获取会话失败: $e');
      return null;
    }
  }
  
  // 获取所有会话
  static Future<List<dynamic>> getConversations() async {
    try {
      final List<dynamic> conversations = [];
      final List<String> keys = _chatBox.keys
          .where((key) => key.toString().startsWith('conversation_'))
          .map((key) => key.toString())
          .toList();
      
      for (final key in keys) {
        final data = getChatData(key);
        if (data != null) {
          conversations.add(data);
        }
      }
      
      return conversations;
    } catch (e) {
      _logger.e('获取所有会话失败: $e');
      return [];
    }
  }

  // 保存会话列表
  static Future<void> saveConversations(List<dynamic> conversations) async {
    try {
      // 清除现有的会话数据
      final List<String> existingKeys = _chatBox.keys
          .where((key) => key.toString().startsWith('conversation_'))
          .map((key) => key.toString())
          .toList();
      
      for (final key in existingKeys) {
        await _chatBox.delete(key);
      }
      
      // 保存新的会话列表
      for (final conversation in conversations) {
        if (conversation != null) {
          String conversationId;
          Map<String, dynamic> conversationData;
          
          if (conversation is Map<String, dynamic>) {
            conversationId = conversation['id']?.toString() ?? '';
            conversationData = conversation;
          } else {
            conversationId = conversation.id?.toString() ?? '';
            conversationData = conversation.toJson();
          }
          
          if (conversationId.isNotEmpty) {
            await saveChatData('conversation_$conversationId', conversationData);
          }
        }
      }
      
      _logger.i('会话列表已保存到本地存储，共 ${conversations.length} 个会话');
    } catch (e) {
      _logger.e('保存会话列表失败: $e');
    }
  }
  
  // 删除会话
  static Future<void> deleteConversation(String conversationId) async {
    try {
      await _chatBox.delete('conversation_$conversationId');
      _logger.i('会话已从本地存储删除: $conversationId');
    } catch (e) {
      _logger.e('删除会话失败: $e');
    }
  }
  
  // 保存通知列表
  static Future<void> saveNotifications(List<dynamic> notifications) async {
    try {
      final List<dynamic> notificationsJson = notifications
          .map((notification) => notification.toJson())
          .toList();
      await saveChatData('notifications', notificationsJson);
      _logger.i('通知列表已保存到本地存储');
    } catch (e) {
      _logger.e('保存通知列表失败: $e');
    }
  }
  
  // 获取通知列表
  static Future<List<dynamic>> getNotifications() async {
    try {
      final List<dynamic> notificationsJson = getChatData('notifications', defaultValue: []);
      if (notificationsJson.isEmpty) return [];
      
      // 注意：这里返回的是原始JSON数据，需要在使用的地方转换为Notification对象
      return notificationsJson;
    } catch (e) {
      _logger.e('获取通知列表失败: $e');
      return [];
    }
  }
  
  // 清空通知列表
  static Future<void> clearNotifications() async {
    try {
      await saveChatData('notifications', []);
      _logger.i('通知列表已清空');
    } catch (e) {
      _logger.e('清空通知列表失败: $e');
    }
  }
  
  // 保存通知设置
  static Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    try {
      await saveUserData('notification_settings', settings);
      _logger.i('通知设置已保存到本地存储');
    } catch (e) {
      _logger.e('保存通知设置失败: $e');
    }
  }
  
  // 获取通知设置
  static Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      return getUserData('notification_settings');
    } catch (e) {
      _logger.e('获取通知设置失败: $e');
      return null;
    }
  }
  
  // 保存群组
  static Future<void> saveGroup(dynamic group) async {
    try {
      final String groupId = group.id;
      await saveChatData('group_$groupId', group.toJson());
      _logger.i('群组已保存到本地存储: $groupId');
    } catch (e) {
      _logger.e('保存群组失败: $e');
    }
  }
  
  // 获取群组
  static Future<dynamic> getGroup(String groupId) async {
    try {
      final data = getChatData('group_$groupId');
      if (data == null) return null;
      
      // 导入Group类并创建实例
      // 这里需要在使用的地方导入Group类并使用fromJson方法
      return data;
    } catch (e) {
      _logger.e('获取群组失败: $e');
      return null;
    }
  }
  
  // 获取所有群组
  static Future<List<dynamic>> getGroups() async {
    try {
      final List<dynamic> groups = [];
      final List<String> keys = _chatBox.keys
          .where((key) => key.toString().startsWith('group_'))
          .map((key) => key.toString())
          .toList();
      
      for (final key in keys) {
        final data = getChatData(key);
        if (data != null) {
          groups.add(data);
        }
      }
      
      return groups;
    } catch (e) {
      _logger.e('获取所有群组失败: $e');
      return [];
    }
  }
  
  // 删除群组
  static Future<void> removeGroup(String groupId) async {
    try {
      await _chatBox.delete('group_$groupId');
      _logger.i('群组已从本地存储删除: $groupId');
    } catch (e) {
      _logger.e('删除群组失败: $e');
    }
  }
  
  // 标记群组为已解散
  static Future<void> markGroupAsDissolved(String groupId) async {
    try {
      final data = await getGroup(groupId);
      if (data != null) {
        data['dissolved'] = true;
        await saveChatData('group_$groupId', data);
        _logger.i('群组已标记为已解散: $groupId');
      }
    } catch (e) {
      _logger.e('标记群组为已解散失败: $e');
    }
  }
  
  // 保存应用设置
  static Future<void> saveSettings(dynamic settings) async {
    try {
      await saveSetting('app_settings', settings.toJson());
      _logger.i('应用设置已保存到本地存储');
    } catch (e) {
      _logger.e('保存应用设置失败: $e');
    }
  }
  
  // 获取应用设置
  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final data = getSetting('app_settings');
      if (data == null) return null;
      
      // 确保返回的是Map<String, dynamic>类型
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        // 如果是其他类型的Map，转换为Map<String, dynamic>
        return Map<String, dynamic>.from(data);
      } else {
        _logger.w('应用设置数据类型不正确: ${data.runtimeType}');
        return null;
      }
    } catch (e) {
      _logger.e('获取应用设置失败: $e');
      return null;
    }
  }
  


  

  

  
  // 清除媒体缓存
  static Future<void> clearMediaCache() async {
    try {
      // 获取所有缓存键
      final List<String> mediaKeys = _cacheBox.keys
          .where((key) => key.toString().startsWith('media_'))
          .map((key) => key.toString())
          .toList();
      
      // 删除所有媒体缓存
      for (final key in mediaKeys) {
        await _cacheBox.delete(key);
      }
      
      _logger.i('媒体缓存已清除');
    } catch (e) {
      _logger.e('清除媒体缓存失败: $e');
    }
  }
}