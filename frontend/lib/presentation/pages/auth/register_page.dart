import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/viewmodels/auth_viewmodel.dart';
import '../../routes/app_router.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// 用户注册页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // 处理注册
  Future<void> _handleRegister() async {
    // 验证表单
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // 检查是否同意条款
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请同意用户协议和隐私政策'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    // 获取AuthViewModel并调用注册方法
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final result = await authViewModel.register(
      username: name,
      email: email,
      password: password,
      displayName: name,
    );
    
    if (!mounted) return;
    
    if (result.success) {
      // 注册成功，显示成功消息并导航到登录页面
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('注册成功，请登录'),
          backgroundColor: Colors.green,
        ),
      );
      AppRouter.router.go(AppRouter.login);
    } else {
      // 注册失败，显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? '注册失败，请重试'),
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
        appBar: AppBar(
          title: const Text('注册'),
          elevation: 0,
        ),
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
                    // 标题
                    Text(
                      '创建新账号',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      '请填写以下信息完成注册',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // 姓名输入框
                    CustomTextField(
                      controller: _nameController,
                      labelText: '姓名',
                      hintText: '请输入您的姓名',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入姓名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 邮箱输入框
                    CustomTextField(
                      controller: _emailController,
                      labelText: '邮箱',
                      hintText: '请输入您的邮箱',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 密码输入框
                    CustomTextField(
                      controller: _passwordController,
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.next,
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
                    
                    // 确认密码输入框
                    CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: '确认密码',
                      hintText: '请再次输入密码',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingNormal),
                    
                    // 同意条款复选框
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text('我已阅读并同意'),
                              TextButton(
                                onPressed: () {
                                  // 显示用户协议
                                },
                                child: const Text('用户协议'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              ),
                              const Text('和'),
                              TextButton(
                                onPressed: () {
                                  // 显示隐私政策
                                },
                                child: const Text('隐私政策'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // 注册按钮
                    CustomButton(
                      text: '注册',
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // 登录链接
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('已有账号？'),
                        TextButton(
                          onPressed: () {
                            AppRouter.router.go(AppRouter.login);
                          },
                          child: const Text('立即登录'),
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
}