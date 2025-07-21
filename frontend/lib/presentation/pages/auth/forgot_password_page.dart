import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/viewmodels/auth_viewmodel.dart';
import '../../routes/app_router.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// 忘记密码页面
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  // 处理发送重置密码邮件
  Future<void> _handleSendResetEmail() async {
    // 验证表单
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    final email = _emailController.text.trim();
    
    // 获取AuthViewModel并调用发送重置密码邮件方法
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final result = await authViewModel.sendPasswordResetEmail(email);
    
    if (!mounted) return;
    
    if (result.success) {
      // 发送成功，更新状态
      setState(() {
        _emailSent = true;
      });
    } else {
      // 发送失败，显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? '发送重置密码邮件失败，请重试'),
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
          title: const Text('忘记密码'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }
  
  // 构建表单视图
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 图标
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: AppTheme.spacingNormal),
          
          // 标题
          Text(
            '忘记密码',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            '请输入您的邮箱，我们将发送重置密码链接',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // 邮箱输入框
          CustomTextField(
            controller: _emailController,
            labelText: '邮箱',
            hintText: '请输入您的邮箱',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
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
          const SizedBox(height: AppTheme.spacingLarge),
          
          // 发送按钮
          CustomButton(
            text: '发送重置链接',
            onPressed: _handleSendResetEmail,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // 返回登录页面
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('记起密码了？'),
              TextButton(
                onPressed: () {
                  AppRouter.router.go(AppRouter.login);
                },
                child: const Text('返回登录'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 构建成功视图
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 成功图标
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: AppTheme.spacingNormal),
        
        // 成功标题
        Text(
          '邮件已发送',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          '重置密码链接已发送到您的邮箱\n${_emailController.text}',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingNormal),
        Text(
          '请检查您的邮箱并点击链接重置密码',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        
        // 返回登录按钮
        CustomButton(
          text: '返回登录',
          onPressed: () {
            AppRouter.router.go(AppRouter.login);
          },
        ),
        const SizedBox(height: AppTheme.spacingNormal),
        
        // 重新发送按钮
        CustomButton(
          text: '重新发送',
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          isOutlined: true,
        ),
      ],
    );
  }
}