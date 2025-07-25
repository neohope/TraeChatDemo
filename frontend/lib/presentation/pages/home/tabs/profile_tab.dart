import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/viewmodels/auth_viewmodel.dart';
import '../../../../domain/viewmodels/user_viewmodel.dart';
import '../../../routes/app_router.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/custom_list_tile.dart';

/// 我的标签页，显示用户个人信息和设置选项
class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          final user = userViewModel.currentUser;
          
          return ListView(
            children: [
              // 用户信息卡片
              _buildUserInfoCard(context, user),
              
              const SizedBox(height: AppTheme.spacingNormal),
              
              // 个人功能区
              _buildSection(
                context,
                [
                  CustomListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('收藏'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToFavorites(context),
                  ),
                  const Divider(height: 1),
                  CustomListTile(
                    leading: const Icon(Icons.photo_album),
                    title: const Text('相册'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToAlbum(context),
                  ),
                  const Divider(height: 1),
                  CustomListTile(
                    leading: const Icon(Icons.file_copy),
                    title: const Text('文件'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToFiles(context),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingNormal),
              
              // 支付和钱包
              _buildSection(
                context,
                [
                  CustomListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('钱包'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToWallet(context),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingNormal),
              
              // 设置和帮助
              _buildSection(
                context,
                [
                  CustomListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('设置'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToSettings(context),
                  ),
                  const Divider(height: 1),
                  CustomListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('帮助与反馈'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToHelp(context),
                  ),
                  const Divider(height: 1),
                  CustomListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('关于'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToAbout(context),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingLarge),
              
              // 退出登录按钮
              if (user != null) ...[  
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                    vertical: AppTheme.spacingNormal,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _confirmLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
              ],
              
              const SizedBox(height: AppTheme.spacingLarge),
            ],
          );
        },
      ),
    );
  }
  
  // 构建用户信息卡片
  Widget _buildUserInfoCard(BuildContext context, dynamic user) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingNormal),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToUserProfile(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingNormal),
          child: Row(
            children: [
              // 用户头像
              CircleAvatar(
                radius: AppTheme.avatarSizeLarge / 2,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl)
                    : null,
                child: user?.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: AppTheme.avatarSizeLarge / 2,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingNormal),
              
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '未登录',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '点击登录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 右侧箭头
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建分区
  Widget _buildSection(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingNormal),
      child: Column(children: children),
    );
  }
  
  // 导航到用户个人资料页面
  void _navigateToUserProfile(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;
    
    if (user != null) {
      // 导航到个人资料页面
      AppRouter.router.go(
        '${AppRouter.profile}/${user.id}',
        extra: {'userName': user.name, 'isCurrentUser': true},
      );
    } else {
      // 导航到登录页面
      AppRouter.router.go(AppRouter.login);
    }
  }
  
  // 导航到设置页面
  void _navigateToSettings(BuildContext context) {
    AppRouter.router.go(AppRouter.settings);
  }
  
  // 导航到收藏页面
  void _navigateToFavorites(BuildContext context) {
    // 检查用户是否已登录
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (userViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 导航到收藏页面
    // 这里可以实现导航到收藏页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('收藏功能即将上线')),
    );
  }
  
  // 导航到相册页面
  void _navigateToAlbum(BuildContext context) {
    // 检查用户是否已登录
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (userViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 导航到相册页面
    // 这里可以实现导航到相册页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('相册功能即将上线')),
    );
  }
  
  // 导航到文件页面
  void _navigateToFiles(BuildContext context) {
    // 检查用户是否已登录
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (userViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 导航到文件页面
    // 这里可以实现导航到文件页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件功能即将上线')),
    );
  }
  
  // 导航到钱包页面
  void _navigateToWallet(BuildContext context) {
    // 检查用户是否已登录
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (userViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 导航到钱包页面
    // 这里可以实现导航到钱包页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('钱包功能即将上线')),
    );
  }
  
  // 导航到帮助与反馈页面
  void _navigateToHelp(BuildContext context) {
    // 导航到帮助与反馈页面
    // 这里可以实现导航到帮助与反馈页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('帮助与反馈功能即将上线')),
    );
  }
  
  // 导航到关于页面
  void _navigateToAbout(BuildContext context) {
    // 导航到关于页面
    // 这里可以实现导航到关于页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('关于功能即将上线')),
    );
  }
  
  // 确认退出登录
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 退出登录
                final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                authViewModel.logout().then((_) {
                  // 导航到登录页面
                  AppRouter.router.go(AppRouter.login);
                });
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}