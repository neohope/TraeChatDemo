import 'package:flutter/foundation.dart';

import '../../data/models/api_response.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

/// 认证状态枚举
enum AuthStatus {
  /// 未认证
  unauthenticated,
  /// 已认证
  authenticated,
  /// 认证中
  authenticating,
  /// 认证失败
  failed,
}

/// 认证视图模型，用于管理用户登录、注册和认证相关的UI状态和业务逻辑
class AuthViewModel extends ChangeNotifier {
  // 认证仓库实例
  final _authRepository = AuthRepository.instance;
  
  // 当前用户
  User? _user;
  // 认证状态
  AuthStatus _status = AuthStatus.unauthenticated;
  // 错误信息
  String? _errorMessage;
  // 是否正在加载
  bool _isLoading = false;
  
  /// 获取当前用户
  User? get user => _user;
  
  /// 获取认证状态
  AuthStatus get status => _status;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 是否已认证
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  /// 构造函数
  AuthViewModel() {
    // 初始化时验证认证状态
    verifyAuthentication();
  }
  
  /// 用户登录
  Future<ApiResponse<User>> login(String username, String password) async {
    _setLoading(true);
    _setStatus(AuthStatus.authenticating);
    _clearError();
    
    try {
      final response = await _authRepository.login(username, password);
      
      if (response.success && response.data != null) {
        _user = response.data;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.failed);
        _setError(response.message ?? '登录失败');
      }
      
      return response;
    } catch (e) {
      _setStatus(AuthStatus.failed);
      _setError('登录失败: $e');
      return ApiResponse<User>.error('登录失败: $e');
    } finally {
      _setLoading(false);
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
    _setLoading(true);
    _setStatus(AuthStatus.authenticating);
    _clearError();
    
    try {
      final response = await _authRepository.register(
        username: username,
        password: password,
        email: email,
        displayName: displayName,
        phone: phone,
      );
      
      if (response.success && response.data != null) {
        _user = response.data;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.failed);
        _setError(response.message ?? '注册失败');
      }
      
      return response;
    } catch (e) {
      _setStatus(AuthStatus.failed);
      _setError('注册失败: $e');
      return ApiResponse<User>.error('注册失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 退出登录
  Future<ApiResponse<bool>> logout() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.logout();
      
      // 无论服务器响应如何，都清除本地用户信息并设置为未认证状态
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
      
      return response;
    } catch (e) {
      _setError('退出登录失败: $e');
      
      // 即使API调用失败，也清除本地用户信息并设置为未认证状态
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
      
      return ApiResponse<bool>.error('退出登录失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 验证当前认证状态
  Future<void> verifyAuthentication() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.verifyAuthentication();
      
      if (response.success && response.data == true) {
        // 如果认证有效，获取当前用户信息
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      _setError('验证认证状态失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 发送密码重置邮件
  Future<ApiResponse<bool>> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.sendPasswordResetEmail(email);
      
      if (!response.success) {
        _setError(response.message ?? '发送密码重置邮件失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送密码重置邮件失败: $e');
      return ApiResponse<bool>.error('发送密码重置邮件失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 重置密码
  Future<ApiResponse<bool>> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.resetPassword(token, newPassword);
      
      if (!response.success) {
        _setError(response.message ?? '重置密码失败');
      }
      
      return response;
    } catch (e) {
      _setError('重置密码失败: $e');
      return ApiResponse<bool>.error('重置密码失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更改密码
  Future<ApiResponse<bool>> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.changePassword(currentPassword, newPassword);
      
      if (!response.success) {
        _setError(response.message ?? '更改密码失败');
      }
      
      return response;
    } catch (e) {
      _setError('更改密码失败: $e');
      return ApiResponse<bool>.error('更改密码失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 发送验证邮件
  Future<ApiResponse<bool>> sendVerificationEmail() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.sendVerificationEmail();
      
      if (!response.success) {
        _setError(response.message ?? '发送验证邮件失败');
      }
      
      return response;
    } catch (e) {
      _setError('发送验证邮件失败: $e');
      return ApiResponse<bool>.error('发送验证邮件失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 验证邮箱
  Future<ApiResponse<bool>> verifyEmail(String token) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.verifyEmail(token);
      
      if (response.success && _user != null) {
        // 更新用户信息中的验证状态
        _user = _user!.copyWith(isVerified: true);
        notifyListeners();
      } else if (!response.success) {
        _setError(response.message ?? '验证邮箱失败');
      }
      
      return response;
    } catch (e) {
      _setError('验证邮箱失败: $e');
      return ApiResponse<bool>.error('验证邮箱失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 使用第三方服务登录（如Google、Facebook等）
  Future<ApiResponse<User>> socialLogin(String provider, String accessToken) async {
    _setLoading(true);
    _setStatus(AuthStatus.authenticating);
    _clearError();
    
    try {
      final response = await _authRepository.socialLogin(provider, accessToken);
      
      if (response.success && response.data != null) {
        _user = response.data;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.failed);
        _setError(response.message ?? '第三方登录失败');
      }
      
      return response;
    } catch (e) {
      _setStatus(AuthStatus.failed);
      _setError('第三方登录失败: $e');
      return ApiResponse<User>.error('第三方登录失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 刷新认证令牌
  Future<ApiResponse<String>> refreshToken() async {
    try {
      return await _authRepository.refreshToken();
    } catch (e) {
      return ApiResponse<String>.error('刷新令牌失败: $e');
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置认证状态
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 检查认证状态
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authRepository.getCurrentUser();
      
      if (response.success && response.data != null) {
        _user = response.data;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      _setError('检查认证状态失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}