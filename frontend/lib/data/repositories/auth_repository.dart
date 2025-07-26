import 'package:dio/dio.dart';

import '../../core/network/http_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// 认证仓库类，用于管理用户登录、注册和认证相关功能
class AuthRepository {
  // 单例模式
  static final AuthRepository _instance = AuthRepository._internal();
  static AuthRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  // HTTP客户端
  final _httpClient = HttpClient.instance;
  
  // 私有构造函数
  AuthRepository._internal();
  
  /// 用户登录
  Future<ApiResponse<User>> login(String username, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/users/login',
        data: {
          'email': username,
          'password': password,
        },
      );
      
      if (response.success && response.data != null) {
        // 后端直接返回 {token, user} 格式，不是包装在 data 字段中
        final responseData = response.data!;
        
        // 保存认证令牌
        final token = responseData['token'] as String;
        await LocalStorage.saveAuthToken(token);
        
        // 设置HTTP客户端的认证令牌
        _httpClient.setAuthToken(token);
        
        // 解析并返回用户信息
        final userData = responseData['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        // 保存当前用户到本地存储
        await LocalStorage.saveCurrentUser(user);
        
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '登录失败');
      }
    } catch (e) {
      _logger.e('登录失败: $e');
      return ApiResponse<User>.error('登录失败: $e');
    }
  }
  
  /// 用户注册
  Future<ApiResponse<User>> register({
    required String username,
    required String password,
    required String email,
    String? displayName,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{
        'username': username,
        'password': password,
        'email': email,
        'full_name': displayName ?? username,
      };
      
      if (phone != null) data['phone'] = phone;
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/users/register',
        data: data,
      );
      
      if (response.success && response.data != null) {
        // 保存认证令牌
        final token = response.data!['token'] as String;
        await LocalStorage.saveAuthToken(token);
        
        // 设置HTTP客户端的认证令牌
        _httpClient.setAuthToken(token);
        
        // 解析并返回用户信息
        final userData = response.data!['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        // 保存当前用户到本地存储
        await LocalStorage.saveCurrentUser(user);
        
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '注册失败');
      }
    } catch (e) {
      _logger.e('注册失败: $e');
      return ApiResponse<User>.error('注册失败: $e');
    }
  }
  
  /// 退出登录
  Future<ApiResponse<bool>> logout() async {
    try {
      await _apiService.post<Map<String, dynamic>>('/api/v1/users/logout');
      
      // 无论服务器响应如何，都清除本地存储的认证信息
      await LocalStorage.clearAuthData();
      _httpClient.clearAuthToken();
      
      return ApiResponse<bool>.success(true);
    } catch (e) {
      _logger.e('退出登录失败: $e');
      
      // 即使API调用失败，也清除本地存储的认证信息
      await LocalStorage.clearAuthData();
      _httpClient.clearAuthToken();
      
      return ApiResponse<bool>.success(true, message: '已清除本地认证信息');
    }
  }
  
  /// 刷新认证令牌
  Future<ApiResponse<String>> refreshToken() async {
    try {
      // 获取当前令牌
      final currentToken = await LocalStorage.getAuthToken();
      if (currentToken == null) {
        return ApiResponse<String>.error('无认证令牌');
      }
      
      final options = Options(headers: {'Authorization': 'Bearer $currentToken'});
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh-token',
        options: options,
      );
      
      if (response.success && response.data != null) {
        final newToken = response.data!['token'] as String;
        
        // 保存新令牌
        await LocalStorage.saveAuthToken(newToken);
        _httpClient.setAuthToken(newToken);
        
        return ApiResponse<String>.success(newToken);
      } else {
        return ApiResponse<String>.error(response.message ?? '刷新令牌失败');
      }
    } catch (e) {
      _logger.e('刷新令牌失败: $e');
      return ApiResponse<String>.error('刷新令牌失败: $e');
    }
  }
  
  /// 验证当前认证状态
  Future<ApiResponse<bool>> verifyAuthentication() async {
    try {
      // 获取当前令牌
      final currentToken = await LocalStorage.getAuthToken();
      if (currentToken == null) {
        return ApiResponse<bool>.error('无认证令牌');
      }
      
      final response = await _apiService.get<Map<String, dynamic>>('/api/v1/auth/verify');
      
      return ApiResponse<bool>.success(response.success);
    } catch (e) {
      _logger.e('验证认证状态失败: $e');
      return ApiResponse<bool>.error('验证认证状态失败: $e');
    }
  }
  
  /// 发送密码重置邮件
  Future<ApiResponse<bool>> sendPasswordResetEmail(String email) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/auth/forgot-password',
        data: {'email': email},
      );
      
      return ApiResponse<bool>.success(response.success, message: response.message);
    } catch (e) {
      _logger.e('发送密码重置邮件失败: $e');
      return ApiResponse<bool>.error('发送密码重置邮件失败: $e');
    }
  }
  
  /// 重置密码
  Future<ApiResponse<bool>> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/auth/reset-password',
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );
      
      return ApiResponse<bool>.success(response.success, message: response.message);
    } catch (e) {
      _logger.e('重置密码失败: $e');
      return ApiResponse<bool>.error('重置密码失败: $e');
    }
  }
  
  /// 更改密码
  Future<ApiResponse<bool>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      
      return ApiResponse<bool>.success(response.success, message: response.message);
    } catch (e) {
      _logger.e('更改密码失败: $e');
      return ApiResponse<bool>.error('更改密码失败: $e');
    }
  }
  
  /// 发送验证邮件
  Future<ApiResponse<bool>> sendVerificationEmail() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/auth/send-verification-email',
      );
      
      return ApiResponse<bool>.success(response.success, message: response.message);
    } catch (e) {
      _logger.e('发送验证邮件失败: $e');
      return ApiResponse<bool>.error('发送验证邮件失败: $e');
    }
  }
  
  /// 验证邮箱
  Future<ApiResponse<bool>> verifyEmail(String token) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-email',
        data: {'token': token},
      );
      
      if (response.success) {
        // 更新本地用户信息
        final currentUser = await LocalStorage.getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(isVerified: true);
          await LocalStorage.saveCurrentUser(updatedUser);
        }
      }
      
      return ApiResponse<bool>.success(response.success, message: response.message);
    } catch (e) {
      _logger.e('验证邮箱失败: $e');
      return ApiResponse<bool>.error('验证邮箱失败: $e');
    }
  }
  
  /// 使用第三方服务登录（如Google、Facebook等）
  Future<ApiResponse<User>> socialLogin(String provider, String accessToken) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/users/social-login',
        data: {
          'provider': provider,
          'access_token': accessToken,
        },
      );
      
      if (response.success && response.data != null) {
        // 保存认证令牌
        final token = response.data!['token'] as String;
        await LocalStorage.saveAuthToken(token);
        
        // 设置HTTP客户端的认证令牌
        _httpClient.setAuthToken(token);
        
        // 解析并返回用户信息
        final userData = response.data!['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        // 保存当前用户到本地存储
        await LocalStorage.saveCurrentUser(user);
        
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error(response.message ?? '第三方登录失败');
      }
    } catch (e) {
      _logger.e('第三方登录失败: $e');
      return ApiResponse<User>.error('第三方登录失败: $e');
    }
  }
  
  /// 获取当前用户信息
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      // 从本地存储获取当前用户
      final user = await LocalStorage.getCurrentUser();
      
      if (user != null) {
        return ApiResponse<User>.success(user);
      } else {
        return ApiResponse<User>.error('未找到当前用户信息');
      }
    } catch (e) {
      _logger.e('获取当前用户信息失败: $e');
      return ApiResponse<User>.error('获取当前用户信息失败: $e');
    }
  }
}