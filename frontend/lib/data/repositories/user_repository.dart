import 'dart:io';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/conversation_model.dart'; // 导入 UserStatus 枚举
import '../models/api_response.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// 用户仓库类，用于管理用户数据的存取
class UserRepository {
  // 单例模式
  static final UserRepository _instance = UserRepository._internal();
  static UserRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  UserRepository._internal();
  
  /// 获取当前用户信息
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      // 先尝试从本地存储获取
      final cachedUser = await LocalStorage.getCurrentUser();
      if (cachedUser != null) {
        return ApiResponse<User>.success(cachedUser);
      }
      
      // 从服务器获取
      final response = await _apiService.get<Map<String, dynamic>>('/api/v1/users/me');
      
      if (response.success && response.data != null) {
        final user = User.fromJson(response.data!);
        // 保存到本地存储
        await LocalStorage.saveCurrentUser(user);
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '获取用户信息失败');
      }
    } catch (e) {
      _logger.e('获取当前用户信息失败: $e');
      return ApiResponse<User>.error('获取用户信息失败: $e');
    }
  }
  
  /// 获取用户信息
  Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/v1/users/$userId');
      
      if (response.success && response.data != null) {
        final user = User.fromJson(response.data!);
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '获取用户信息失败');
      }
    } catch (e) {
      _logger.e('获取用户信息失败: $e');
      return ApiResponse<User>.error('获取用户信息失败: $e');
    }
  }
  
  /// 更新用户信息
  Future<ApiResponse<User>> updateUserProfile({
    String? displayName,
    String? bio,
    String? phoneNumber,
    UserStatus? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (displayName != null) data['display_name'] = displayName;
      if (bio != null) data['bio'] = bio;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (status != null) data['status'] = status.toString().split('.').last;
      
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/v1/users/me',
        data: data,
      );
      
      if (response.success && response.data != null) {
        final user = User.fromJson(response.data!);
        // 更新本地存储
        await LocalStorage.saveCurrentUser(user);
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '更新用户信息失败');
      }
    } catch (e) {
      _logger.e('更新用户信息失败: $e');
      return ApiResponse<User>.error('更新用户信息失败: $e');
    }
  }
  
  /// 更新用户头像
  Future<ApiResponse<User>> updateAvatar(File imageFile) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/api/v1/users/me/avatar',
        imageFile,
      );
      
      if (response.success && response.data != null) {
        final user = User.fromJson(response.data!);
        // 更新本地存储
        await LocalStorage.saveCurrentUser(user);
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '更新头像失败');
      }
    } catch (e) {
      _logger.e('更新头像失败: $e');
      return ApiResponse<User>.error('更新头像失败: $e');
    }
  }
  
  /// 更新用户状态
  Future<ApiResponse<bool>> updateUserStatus(UserStatus status) async {
    try {
      final data = {
        'status': status.toString().split('.').last,
      };
      
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/v1/users/me/status',
        data: data,
      );
      
      if (response.success) {
        // 更新本地用户状态
        final currentUser = await LocalStorage.getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(status: status);
          await LocalStorage.saveCurrentUser(updatedUser);
        }
        
        return ApiResponse<bool>.success(true);
      } else {
        return ApiResponse<bool>.error(response.message ?? '更新状态失败');
      }
    } catch (e) {
      _logger.e('更新用户状态失败: $e');
      return ApiResponse<bool>.error('更新状态失败: $e');
    }
  }
  
  /// 根据关键词搜索用户
  Future<ApiResponse<List<User>>> searchUsersByKeyword(String keyword) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/v1/users/search',
        queryParameters: {'keyword': keyword},
      );
      
      if (response.success) {
        if (response.data != null && response.data is List) {
          final users = response.data!.map((json) => User.fromJson(json)).toList();
          return ApiResponse<List<User>>.success(users);
        } else {
          // API返回null或非List类型，返回空列表
          return ApiResponse<List<User>>.success([]);
        }
      } else {
        return ApiResponse<List<User>>.error(response.message ?? '搜索用户失败');
      }
    } catch (e) {
      _logger.e('搜索用户失败: $e');
      return ApiResponse<List<User>>.error('搜索用户失败: $e');
    }
  }
  
  /// 获取联系人列表
  Future<ApiResponse<List<User>>> getContacts() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/api/v1/users/contacts');
      
      if (response.success && response.data != null) {
        final contacts = response.data!.map((json) => User.fromJson(json)).toList();
        return ApiResponse<List<User>>.success(contacts);
      } else {
        return ApiResponse<List<User>>.error(response.message ?? '获取联系人列表失败');
      }
    } catch (e) {
      _logger.e('获取联系人列表失败: $e');
      return ApiResponse<List<User>>.error('获取联系人列表失败: $e');
    }
  }

  /// 搜索用户
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/v1/users/search',
        queryParameters: {'q': query},
      );
      
      if (response.success) {
        if (response.data != null && response.data is List) {
          final users = response.data!.map((json) => User.fromJson(json)).toList();
          return ApiResponse<List<User>>.success(users);
        } else {
          // API返回null或非List类型，返回空列表
          return ApiResponse<List<User>>.success([]);
        }
      } else {
        return ApiResponse<List<User>>.error(response.message ?? '搜索用户失败');
      }
    } catch (e) {
      _logger.e('搜索用户失败: $e');
      return ApiResponse<List<User>>.error('搜索用户失败: $e');
    }
  }
  
  /// 添加联系人
  Future<ApiResponse<bool>> addContact(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/users/contacts',
        data: {'user_id': userId},
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('添加联系人失败: $e');
      return ApiResponse<bool>.error('添加联系人失败: $e');
    }
  }
  
  /// 删除联系人
  Future<ApiResponse<bool>> removeContact(String userId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/api/v1/users/contacts/$userId',
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('删除联系人失败: $e');
      return ApiResponse<bool>.error('删除联系人失败: $e');
    }
  }

  /// 切换联系人收藏状态
  Future<ApiResponse<bool>> toggleFavoriteContact(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/users/contacts/$userId/favorite',
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('切换收藏状态失败: $e');
      return ApiResponse<bool>.error('切换收藏状态失败: $e');
    }
  }

  /// 拉黑联系人
  Future<ApiResponse<bool>> blockContact(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/users/contacts/$userId/block',
      );
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('拉黑联系人失败: $e');
      return ApiResponse<bool>.error('拉黑联系人失败: $e');
    }
  }

  /// 删除联系人（别名方法，与removeContact功能相同）
  Future<ApiResponse<bool>> deleteContact(String userId) async {
    return removeContact(userId);
  }
  
  /// 注销登录
  Future<ApiResponse<bool>> logout() async {
    try {
      
      // 无论服务器响应如何，都清除本地存储
      await LocalStorage.clearAuthData();
      
      return ApiResponse<bool>.success(true);
    } catch (e) {
      _logger.e('注销登录失败: $e');
      // 即使API调用失败，也清除本地存储
      await LocalStorage.clearAuthData();
      return ApiResponse<bool>.success(true);
    }
  }
}