import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/viewmodels/user_viewmodel.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/custom_list_tile.dart';

/// 发现标签页，显示朋友圈和附近的人等功能
class DiscoverTab extends StatelessWidget {
  const DiscoverTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
      ),
      body: ListView(
        children: [
          // 朋友圈
          _buildSection(
            context,
            [
              CustomListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('朋友圈'),
                subtitle: const Text('分享生活，发现精彩'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToMoments(context),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingNormal),
          
          // 社交功能
          _buildSection(
            context,
            [
              CustomListTile(
                leading: const Icon(Icons.people),
                title: const Text('附近的人'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToNearbyPeople(context),
              ),
              const Divider(height: 1),
              CustomListTile(
                leading: const Icon(Icons.search),
                title: const Text('搜一搜'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToSearch(context),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingNormal),
          
          // 小程序和游戏
          _buildSection(
            context,
            [
              CustomListTile(
                leading: const Icon(Icons.apps),
                title: const Text('小程序'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToMiniPrograms(context),
              ),
              const Divider(height: 1),
              CustomListTile(
                leading: const Icon(Icons.sports_esports),
                title: const Text('游戏'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToGames(context),
              ),
            ],
          ),
        ],
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
  
  // 导航到朋友圈
  void _navigateToMoments(BuildContext context) {
    // 检查用户是否已登录
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (userViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 导航到朋友圈页面
    // 这里可以实现导航到朋友圈页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('朋友圈功能即将上线')),
    );
  }
  
  // 导航到附近的人
  void _navigateToNearbyPeople(BuildContext context) {
    // 检查用户是否已登录
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (userViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 导航到附近的人页面
    // 这里可以实现导航到附近的人页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('附近的人功能即将上线')),
    );
  }
  
  // 导航到搜一搜
  void _navigateToSearch(BuildContext context) {
    // 导航到搜一搜页面
    // 这里可以实现导航到搜一搜页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('搜一搜功能即将上线')),
    );
  }
  
  // 导航到小程序
  void _navigateToMiniPrograms(BuildContext context) {
    // 导航到小程序页面
    // 这里可以实现导航到小程序页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('小程序功能即将上线')),
    );
  }
  
  // 导航到游戏
  void _navigateToGames(BuildContext context) {
    // 导航到游戏页面
    // 这里可以实现导航到游戏页面的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('游戏功能即将上线')),
    );
  }
}