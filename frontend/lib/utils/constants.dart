/// 常量类
/// 
/// 存储应用中使用的常量
class Constants {
  // API相关
  static const String apiBaseUrl = 'https://api.chatapp.com/v1';
  static const int apiTimeout = 30; // 秒
  
  // 存储相关
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String settingsKey = 'app_settings';
  
  // 路由相关
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String chatRoute = '/chat';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  
  // 动画相关
  static const int splashDuration = 2000; // 毫秒
  static const int animationDuration = 300; // 毫秒
  
  // 消息相关
  static const int messagePageSize = 20;
  static const int typingTimeout = 3000; // 毫秒
  
  // 文件相关
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 20 * 1024 * 1024; // 20MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedFileExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
  
  // 正则表达式
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
  );
  
  // 错误消息
  static const String networkErrorMessage = '网络连接错误，请检查您的网络连接';
  static const String serverErrorMessage = '服务器错误，请稍后再试';
  static const String unknownErrorMessage = '发生未知错误，请稍后再试';
  
  // 验证错误消息
  static const String emailRequiredMessage = '请输入邮箱地址';
  static const String emailInvalidMessage = '请输入有效的邮箱地址';
  static const String passwordRequiredMessage = '请输入密码';
  static const String passwordInvalidMessage = '密码必须至少包含8个字符，包括字母和数字';
  static const String nameRequiredMessage = '请输入姓名';
  static const String confirmPasswordRequiredMessage = '请确认密码';
  static const String passwordsDoNotMatchMessage = '两次输入的密码不一致';
  
  // 成功消息
  static const String registerSuccessMessage = '注册成功，请登录';
  static const String resetPasswordEmailSentMessage = '重置密码邮件已发送，请查收';
  static const String passwordResetSuccessMessage = '密码重置成功，请使用新密码登录';
  
  // 其他
  static const int searchDebounceTime = 500; // 毫秒
  static const int maxRecentSearches = 10;
}