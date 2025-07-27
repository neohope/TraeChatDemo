import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/models/api_response.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service_impl.dart';
import '../models/conversation_model.dart'; // 导入 UserStatus 枚举
import '../models/user_model.dart';

/// 用户视图模型，用于管理用户相关的UI状态和业务逻辑
class UserViewModel extends ChangeNotifier {
  // 用户仓库实例
  final _userRepository = UserRepository.instance;
  
  // 当前用户
  User? _currentUser;
  // 联系人列表
  List<User> _contacts = [];
  // 搜索结果
  List<User> _searchResults = [];
  
  // 加载状态
  bool _isLoading = false;
  // 错误信息
  String? _errorMessage;
  
  /// 获取当前用户
  User? get currentUser => _currentUser;
  
  /// 获取联系人列表
  List<User> get contacts => _contacts;
  
  /// 获取搜索结果
  List<User> get searchResults => _searchResults;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 获取错误信息（兼容旧代码）
  String? get error => _errorMessage;
  
  /// 构造函数
  UserViewModel() {
    // 初始化时从AuthService获取当前用户，然后加载联系人列表
    _initializeCurrentUser();
    loadContacts();
  }
  
  /// 从AuthService初始化当前用户
  void _initializeCurrentUser() {
    final authUser = AuthServiceImpl.instance.currentUser;
    if (authUser != null) {
      // 将UserModel转换为User
       _currentUser = User(
         id: authUser.id,
         username: authUser.name,
         displayName: authUser.nickname ?? authUser.name,
         email: authUser.email ?? '',
         avatarUrl: authUser.avatarUrl,
         status: authUser.status ?? UserStatus.online, // 使用AuthUser的状态或默认在线
         bio: authUser.bio,
         phoneNumber: authUser.phone,
         isVerified: authUser.isVerified,
         createdAt: DateTime.now(), // 使用当前时间作为默认值
         lastActive: authUser.lastSeen ?? DateTime.now(),
         isFavorite: authUser.isFavorite,
         isBlocked: authUser.isBlocked,
       );
      notifyListeners();
    } else {
      // 如果AuthService中没有用户，尝试从API加载
      loadCurrentUser();
    }
  }
  
  /// 加载当前用户
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.getCurrentUser();
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载当前用户失败');
      }
    } catch (e) {
      _setError('加载当前用户失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 搜索联系人
  Future<void> searchContacts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.searchUsers(query);
      
      if (response.success && response.data != null) {
        _searchResults = response.data!;
      } else {
        _searchResults = [];
        _setError(response.message ?? '搜索失败');
      }
    } catch (e) {
      _searchResults = [];
      _setError('搜索失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 清除联系人搜索结果
  void clearContactSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// 加载联系人列表
  Future<void> loadContacts({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.getContacts();
      
      if (response.success && response.data != null) {
        _contacts = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '加载联系人列表失败');
      }
    } catch (e) {
      _setError('加载联系人列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 搜索用户
  Future<void> searchUsers(String keyword) async {
    if (keyword.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.searchUsers(keyword);
      
      if (response.success && response.data != null) {
        _searchResults = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? '搜索用户失败');
      }
    } catch (e) {
      _setError('搜索用户失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 从缓存中获取用户信息（同步方法）
  User? getCachedUserById(String userId) {
    // 首先检查是否是当前用户
    if (_currentUser != null && _currentUser!.id == userId) {
      return _currentUser;
    }
    
    // 然后检查联系人列表
    try {
      return _contacts.firstWhere((user) => user.id == userId);
    } catch (e) {
      // 用户不在联系人列表中
      return null;
    }
  }
  
  /// 获取用户详情（异步方法，从API获取）
  Future<ApiResponse<User>> getUserById(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.getUserById(userId);
      
      if (!response.success) {
        _setError(response.message ?? '获取用户详情失败');
      }
      
      return response;
    } catch (e) {
      _setError('获取用户详情失败: $e');
      return ApiResponse<User>.error('获取用户详情失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更新用户资料
  Future<ApiResponse<User>> updateProfile({
    String? displayName,
    String? bio,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.updateUserProfile(
        displayName: displayName,
        bio: bio,
        phoneNumber: phone,
      );
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新用户资料失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新用户资料失败: $e');
      return ApiResponse<User>.error('更新用户资料失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更新用户头像
  Future<ApiResponse<User>> updateAvatar(File avatarFile) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.updateAvatar(avatarFile);
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新用户头像失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新用户头像失败: $e');
      return ApiResponse<User>.error('更新用户头像失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更新用户状态
  Future<ApiResponse<User>> updateStatus(UserStatus status) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.updateUserProfile(status: status);
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      } else {
        _setError(response.message ?? '更新用户状态失败');
      }
      
      return response;
    } catch (e) {
      _setError('更新用户状态失败: $e');
      return ApiResponse<User>.error('更新用户状态失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 添加联系人
  Future<ApiResponse<bool>> addContact(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.addContact(userId);
      
      if (response.success && response.data == true) {
        // 重新加载联系人列表
        await loadContacts();
      } else {
        _setError(response.message ?? '添加联系人失败');
      }
      
      return response;
    } catch (e) {
      _setError('添加联系人失败: $e');
      return ApiResponse<bool>.error('添加联系人失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 删除联系人
  Future<ApiResponse<bool>> removeContact(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.removeContact(userId);
      
      if (response.success && response.data == true) {
        // 从联系人列表中移除
        _contacts.removeWhere((contact) => contact.id == userId);
        notifyListeners();
      } else {
        _setError(response.message ?? '删除联系人失败');
      }
      
      return response;
    } catch (e) {
      _setError('删除联系人失败: $e');
      return ApiResponse<bool>.error('删除联系人失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 拉黑联系人
  Future<ApiResponse<bool>> blockContact(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.blockContact(userId);
      
      if (response.success) {
        // 从联系人列表中移除被拉黑的用户
        _contacts.removeWhere((contact) => contact.id == userId);
        notifyListeners();
      } else {
        _setError(response.message ?? '拉黑失败');
      }
      
      return response;
    } catch (e) {
      _setError('拉黑失败: $e');
      return ApiResponse<bool>.error('拉黑失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 注销登录
  Future<ApiResponse<bool>> logout() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _userRepository.logout();
      
      if (response.success) {
        // 清除当前用户和联系人列表
        _currentUser = null;
        _contacts = [];
        notifyListeners();
      } else {
        _setError(response.message ?? '注销登录失败');
      }
      
      return response;
    } catch (e) {
      _setError('注销登录失败: $e');
      return ApiResponse<bool>.error('注销登录失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
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
  
  /// 将 User 转换为 UserModel
  UserModel convertToUserModel(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phoneNumber,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      status: user.status,
      lastSeen: user.lastActive,
      isFavorite: user.isFavorite,
      isBlocked: user.isBlocked,
    );
  }
  
  /// 将 User 列表转换为 UserModel 列表
  List<UserModel> convertToUserModelList(List<User> users) {
    return users.map((user) => convertToUserModel(user)).toList();
  }
  
  /// 切换联系人收藏状态（支持 UserModel）
  Future<void> toggleFavoriteContact(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 调用 UserRepository 的方法
      final response = await _userRepository.toggleFavoriteContact(userId);
      
      if (response.success) {
        // 重新加载联系人列表以获取更新后的状态
        await loadContacts();
        notifyListeners();
      } else {
        _setError(response.message ?? '操作失败');
      }
    } catch (e) {
      _setError('操作失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 切换联系人拉黑状态（支持 UserModel）
  Future<void> toggleBlockContact(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 调用 UserRepository 的方法
      final response = await _userRepository.blockContact(userId);
      
      if (response.success) {
        // 重新加载联系人列表以获取更新后的状态
        await loadContacts();
        notifyListeners();
      } else {
        _setError(response.message ?? '操作失败');
      }
    } catch (e) {
      _setError('操作失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 删除联系人（支持 UserModel）
  Future<void> deleteContact(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // 调用 UserRepository 的方法
      final response = await _userRepository.deleteContact(userId);
      
      if (response.success) {
        // 重新加载联系人列表
        await loadContacts();
        notifyListeners();
      } else {
        _setError(response.message ?? '操作失败');
      }
    } catch (e) {
      _setError('操作失败: $e');
    } finally {
      _setLoading(false);
    }
  }
}