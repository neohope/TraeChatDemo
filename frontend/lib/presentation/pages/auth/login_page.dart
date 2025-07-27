import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/viewmodels/auth_viewmodel.dart';
import '../../routes/app_router.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// 用户登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // 用户名或邮箱
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  
  @override
  void initState() {
    super.initState();
    // 移除自动登录功能，用户需要手动输入凭据
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  

  
  // 手动登录处理
  Future<void> _handleLogin() async {
    // 验证表单
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    
    print('开始登录: identifier=$identifier, password长度=${password.length}');
    
    // 获取AuthViewModel并调用登录方法
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final response = await authViewModel.login(identifier, password);

    if (!mounted) return;
    
    print('登录结果: success=${response.success}, isAuthenticated=${authViewModel.isAuthenticated}');
    print('错误信息: ${authViewModel.errorMessage}');

    if (response.success) {
      // 登录成功，等待状态更新后导航到首页
      print('登录成功，准备跳转到首页');
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted && authViewModel.isAuthenticated) {
        print('执行页面跳转到首页');
        AppRouter.router.go(AppRouter.home);
      } else {
        print('认证状态异常，无法跳转: isAuthenticated=${authViewModel.isAuthenticated}');
      }
    } else {
      // 登录失败，显示错误信息
      final errorMessage = authViewModel.errorMessage ?? response.message ?? '登录失败，请重试';
      print('登录失败，显示错误: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    return LoadingOverlay(
      isLoading: authViewModel.isLoading,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 应用图标和标题
                    Icon(
                      Icons.chat_rounded,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    Text(
                      '欢迎回来',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      '请登录您的账号',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // 用户名/邮箱输入框
                    CustomTextField(
                      controller: _identifierController,
                      labelText: '用户名/邮箱',
                      hintText: '请输入用户名或邮箱',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名或邮箱';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 密码输入框
                    CustomTextField(
                      controller: _passwordController,
                      labelText: '密码',
                      hintText: '请输入您的密码',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        if (value.length < 6) {
                          return '密码长度不能少于6位';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 记住我和忘记密码
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 记住我选项
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('记住我'),
                          ],
                        ),
                        
                        // 忘记密码链接
                        TextButton(
                          onPressed: () {
                            AppRouter.router.go(AppRouter.forgotPassword);
                          },
                          child: const Text('忘记密码？'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // 登录按钮
                    CustomButton(
                      text: '登录',
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 分隔线
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingNormal),
                          child: Text(
                            '或',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 社交媒体登录按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google登录
                        _buildSocialLoginButton(
                          icon: Icons.g_mobiledata,
                          color: Colors.red,
                          onPressed: () {
                            // 处理Google登录
                          },
                        ),
                        const SizedBox(width: AppTheme.spacingNormal),
                        
                        // Facebook登录
                        _buildSocialLoginButton(
                          icon: Icons.facebook,
                          color: Colors.blue,
                          onPressed: () {
                            // 处理Facebook登录
                          },
                        ),
                        const SizedBox(width: AppTheme.spacingNormal),
                        
                        // Twitter登录
                        _buildSocialLoginButton(
                          icon: Icons.apple,
                          color: Colors.black,
                          onPressed: () {
                            // 处理Apple登录
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // 注册链接
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('还没有账号？'),
                        TextButton(
                          onPressed: () {
                            AppRouter.router.go(AppRouter.register);
                          },
                          child: const Text('立即注册'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 构建社交媒体登录按钮
  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
      ),
    );
  }
}