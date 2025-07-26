import 'package:flutter/foundation.dart';
import '../../domain/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final AppLogger _logger = AppLogger.instance;

  AuthViewModel(this._apiService) {
    initializeAuth();
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _setError(null);
  }

  /// 初始化认证状态
  Future<void> initializeAuth() async {
    _logger.logger.i('开始初始化认证状态...');
    try {
      _setLoading(true);
      
      // 检查本地存储的token
      final token = await LocalStorage.getAuthToken();
      _logger.logger.i('从本地存储获取的Token: ${token != null && token.isNotEmpty ? '存在' : '不存在'}');

      if (token != null && token.isNotEmpty) {
        // 验证token有效性
        final isValid = await _validateToken(token);
        _logger.logger.i('Token验证结果: ${isValid ? '有效' : '无效'}');

        if (isValid) {
          // 获取当前用户信息
          await _loadCurrentUser();
          _isAuthenticated = true;
          _logger.logger.i('用户已通过Token认证并登录');
        } else {
          // token无效，清除本地数据
          _logger.logger.w('Token无效或已过期，清除认证数据');
          await _clearAuthData();
        }
      } else {
        _logger.logger.i('没有可用的Token，用户需要登录');
      }
    } catch (e) {
      _logger.logger.e('初始化认证状态时发生错误: $e');
      await _clearAuthData();
    } finally {
      _setLoading(false);
      _logger.logger.i('认证状态初始化完成');
    }
  }

  /// 用户登录
  Future<bool> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      _logger.logger.i('开始登录请求: email=$username, rememberMe=$rememberMe');

      final response = await _apiService.post('/api/v1/users/login', data: {
        'email': username,
        'password': password,
        'rememberMe': rememberMe,
      });
      
      _logger.logger.i('登录API响应: $response');

      // 检查响应格式 - 后端直接返回 {token, user} 格式
      if (response != null && response['token'] != null && response['user'] != null) {
        final token = response['token'];
        final refreshToken = response['refreshToken']; // 可能为null
        final user = UserModel.fromJson(response['user']);
        
        _logger.logger.i('解析登录响应成功: token=${token != null && token.length > 20 ? token.substring(0, 20) + '...' : token}, user=${user.name}');

        // 保存认证信息
        await LocalStorage.saveAuthToken(token);
        if (refreshToken != null) {
          await LocalStorage.saveRefreshToken(refreshToken);
        }
        await LocalStorage.saveCurrentUser(user);

        _currentUser = user;
        _isAuthenticated = true;
        
        _logger.logger.i('登录成功并保存认证信息: ${user.name}');
        return true;
      } else {
        // 处理错误响应
        final errorMessage = response?['error'] ?? response?['message'] ?? '登录失败';
        _logger.logger.w('登录失败: $errorMessage');
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      _logger.logger.e('登录异常: $e');
      _setError('登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
      _logger.logger.i('登录请求完成');
    }
  }

  /// 用户注册
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? nickname,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.post('/api/v1/users/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'full_name': nickname ?? username,
        'phone': phone,
      });

      if (response['success'] == true) {
        _logger.logger.i('注册成功');
        return true;
      } else {
        _setError(response['message'] ?? '注册失败');
        return false;
      }
    } catch (e) {
      _logger.logger.e('注册失败: $e');
      _setError('注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // 调用登出API
      try {
        await _apiService.post('/api/v1/users/logout', data: {});
      } catch (e) {
        _logger.logger.w('登出API调用失败: $e');
      }
      
      // 清除本地数据
      await _clearAuthData();
      
      _logger.logger.i('用户已登出');
    } catch (e) {
      _logger.logger.e('登出失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _apiService.post('/api/v1/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response['success'] == true) {
        final data = response['data'];
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        await LocalStorage.saveAuthToken(newToken);
        if (newRefreshToken != null) {
          await LocalStorage.saveRefreshToken(newRefreshToken);
        }

        _logger.logger.i('Token刷新成功');
        return true;
      } else {
        _logger.logger.w('Token刷新失败');
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      _logger.logger.e('Token刷新异常: $e');
      await _clearAuthData();
      return false;
    }
  }

  /// 更新用户信息
  Future<bool> updateProfile({
    String? nickname,
    String? bio,
    String? avatar,
    String? email,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (bio != null) updateData['bio'] = bio;
      if (avatar != null) updateData['avatar'] = avatar;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;

      final response = await _apiService.put('/api/v1/users/me', data: updateData);

      if (response['success'] == true) {
        final updatedUser = UserModel.fromJson(response['data']);
        _currentUser = updatedUser;
        await LocalStorage.saveCurrentUser(updatedUser);
        
        _logger.logger.i('用户信息更新成功');
        return true;
      } else {
        _setError(response['message'] ?? '更新失败');
        return false;
      }
    } catch (e) {
      _logger.logger.e('更新用户信息失败: $e');
      _setError('更新失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 修改密码
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.put('/api/v1/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response['success'] == true) {
        _logger.logger.i('密码修改成功');
        return true;
      } else {
        _setError(response['message'] ?? '密码修改失败');
        return false;
      }
    } catch (e) {
      _logger.logger.e('密码修改失败: $e');
      _setError('密码修改失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 验证token有效性
  Future<bool> _validateToken(String token) async {
    try {
      final response = await _apiService.get('/api/v1/auth/validate');
      return response['success'] == true;
    } catch (e) {
      _logger.logger.w('Token验证失败: $e');
      return false;
    }
  }

  /// 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      // 先从本地存储获取
      final localUser = await LocalStorage.getCurrentUser();
      if (localUser != null) {
        _currentUser = localUser;
        notifyListeners();
      }

      // 从服务器获取最新信息
      final response = await _apiService.get('/api/v1/users/me');
      if (response['success'] == true) {
        final user = UserModel.fromJson(response['data']);
        _currentUser = user;
        await LocalStorage.saveCurrentUser(user);
        notifyListeners();
      }
    } catch (e) {
      _logger.logger.e('加载用户信息失败: $e');
    }
  }

  /// 清除认证数据
  Future<void> _clearAuthData() async {
    await LocalStorage.clearAuthInfo();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// 检查用户名是否可用
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await _apiService.get('/api/v1/auth/check-username?username=$username');
      return response['available'] == true;
    } catch (e) {
      _logger.logger.e('检查用户名可用性失败: $e');
      return false;
    }
  }

  /// 检查邮箱是否可用
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await _apiService.get('/api/v1/auth/check-email?email=$email');
      return response['available'] == true;
    } catch (e) {
      _logger.logger.e('检查邮箱可用性失败: $e');
      return false;
    }
  }

  /// 发送验证码
  Future<bool> sendVerificationCode(String email) async {
    try {
      _setLoading(true);
      final response = await _apiService.post('/api/v1/auth/send-code', data: {
        'email': email,
      });
      
      if (response['success'] == true) {
        _logger.logger.i('验证码发送成功');
        return true;
      } else {
        _setError(response['message'] ?? '验证码发送失败');
        return false;
      }
    } catch (e) {
      _logger.logger.e('发送验证码失败: $e');
      _setError('发送验证码失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}