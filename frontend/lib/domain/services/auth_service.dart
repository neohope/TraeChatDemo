import '../models/user_model.dart';
import '../../utils/result.dart';

/// 认证服务接口
/// 
/// 定义了用户认证相关的方法和属性
abstract class AuthService {
  /// 获取当前登录用户
  UserModel? get currentUser;
  
  /// 登录
  /// 
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// 返回登录结果
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  });
  
  /// 使用手机号登录
  /// 
  /// [phone] 手机号
  /// [code] 验证码
  /// 返回登录结果
  Future<Result<UserModel>> loginWithPhone({
    required String phone,
    required String code,
  });
  
  /// 注册
  /// 
  /// [name] 用户名
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// 返回注册结果
  Future<Result<UserModel>> register({
    required String name,
    required String email,
    required String password,
  });
  
  /// 退出登录
  Future<Result<void>> logout();
  
  /// 重置密码
  /// 
  /// [email] 用户邮箱
  Future<Result<void>> resetPassword(String email);
  
  /// 更新用户信息
  /// 
  /// [user] 更新后的用户信息
  Future<Result<UserModel>> updateUserInfo(UserModel user);
  
  /// 更新用户头像
  /// 
  /// [imagePath] 头像图片路径
  Future<Result<String>> updateAvatar(String imagePath);
  
  /// 检查用户是否已登录
  Future<bool> isLoggedIn();
  
  /// 获取认证令牌
  Future<String?> getAuthToken();
  
  /// 刷新认证令牌
  Future<Result<String>> refreshToken();
}