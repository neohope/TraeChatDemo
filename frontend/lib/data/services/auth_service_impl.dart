import '../../domain/models/user_model.dart';
import '../../domain/services/auth_service.dart';
import '../../utils/result.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/network/http_client.dart';

/// AuthService的具体实现
class AuthServiceImpl implements AuthService {
  static final AuthServiceImpl _instance = AuthServiceImpl._internal();
  static AuthServiceImpl get instance => _instance;
  
  final HttpClient _httpClient = HttpClient.instance;
  final AppLogger _logger = AppLogger.instance;
  
  UserModel? _currentUser;
  
  AuthServiceImpl._internal();
  
  /// 初始化AuthService，从本地存储恢复用户状态
  Future<void> initialize() async {
    try {
      final user = await LocalStorage.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _logger.info('从本地存储恢复用户状态: ${user.name}');
      }
    } catch (e) {
      _logger.error('从本地存储初始化用户状态失败: $e');
    }
  }
  
  @override
  UserModel? get currentUser => _currentUser;
  
  @override
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('尝试登录: $email');
      final response = await _httpClient.dio.post(
        '/api/v1/users/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final user = UserModel.fromJson(data['user']);

        await LocalStorage.saveAuthToken(token);
        await LocalStorage.saveCurrentUser(user);
        _currentUser = user;

        _logger.info('登录成功: ${user.name}');
        return Result.success(user);
      } else {
        _logger.error('登录失败: ${response.data}');
        return Result.error('登录失败: ${response.data?['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _logger.error('登录失败: $e');
      return Result.error('登录失败: $e');
    }
  }
  
  @override
  Future<Result<UserModel>> loginWithPhone({
    required String phone,
    required String code,
  }) async {
    try {
      _logger.info('尝试手机号登录: $phone');
      return Result.error('手机号登录功能尚未实现');
    } catch (e) {
      _logger.error('手机号登录失败: $e');
      return Result.error('手机号登录失败: $e');
    }
  }
  
  @override
  Future<Result<UserModel>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('尝试注册: $email');
      return Result.error('注册功能尚未实现');
    } catch (e) {
      _logger.error('注册失败: $e');
      return Result.error('注册失败: $e');
    }
  }
  
  @override
  Future<Result<void>> logout() async {
    try {
      _currentUser = null;
      await LocalStorage.clearAuthInfo();
      _logger.info('用户已登出');
      return Result.success(null);
    } catch (e) {
      _logger.error('登出失败: $e');
      return Result.error('登出失败: $e');
    }
  }
  
  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      _logger.info('尝试重置密码: $email');
      return Result.error('重置密码功能尚未实现');
    } catch (e) {
      _logger.error('重置密码失败: $e');
      return Result.error('重置密码失败: $e');
    }
  }
  
  @override
  Future<Result<UserModel>> updateUserInfo(UserModel user) async {
    try {
      _logger.info('尝试更新用户信息: ${user.id}');
      return Result.error('更新用户信息功能尚未实现');
    } catch (e) {
      _logger.error('更新用户信息失败: $e');
      return Result.error('更新用户信息失败: $e');
    }
  }
  
  @override
  Future<Result<String>> updateAvatar(String imagePath) async {
    try {
      _logger.info('尝试更新头像: $imagePath');
      return Result.error('更新头像功能尚未实现');
    } catch (e) {
      _logger.error('更新头像失败: $e');
      return Result.error('更新头像失败: $e');
    }
  }
  
  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      _logger.error('检查登录状态失败: $e');
      return false;
    }
  }
  
  @override
  Future<String?> getAuthToken() async {
    try {
      return await LocalStorage.getAuthToken();
    } catch (e) {
      _logger.error('获取认证令牌失败: $e');
      return null;
    }
  }
  
  @override
  Future<Result<String>> refreshToken() async {
    try {
      _logger.info('尝试刷新令牌');
      return Result.error('刷新令牌功能尚未实现');
    } catch (e) {
      _logger.error('刷新令牌失败: $e');
      return Result.error('刷新令牌失败: $e');
    }
  }
}