import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/viewmodels/conversation_viewmodel.dart';
import '../../../domain/viewmodels/notification_viewmodel.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../themes/app_theme.dart';
import 'tabs/chats_tab.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/discover_tab.dart';
import 'tabs/profile_tab.dart';

/// 应用首页，包含底部导航栏和主要功能入口
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 当前选中的底部导航栏索引
  int _currentIndex = 0;
  
  // 页面控制器
  final _pageController = PageController();
  
  // 底部导航栏项目
  final List<_BottomNavItem> _bottomNavItems = [
    const _BottomNavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: '聊天',
    ),
    const _BottomNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: '联系人',
    ),
    const _BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: '发现',
    ),
    const _BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '我的',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    
    // 加载数据
    _loadData();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // 加载初始数据
  Future<void> _loadData() async {
    // 获取当前用户信息
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await userViewModel.loadCurrentUser();
    
    if (!mounted) return;
    
    // 加载会话列表
    final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    await conversationViewModel.loadConversations();
    
    if (!mounted) return;
    
    // 加载未读通知数量
    final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
    await notificationViewModel.getUnreadCount();
  }
  
  // 切换底部导航栏
  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  // 页面切换
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取未读通知数量
    final notificationViewModel = Provider.of<NotificationViewModel>(context);
    final unreadNotificationCount = notificationViewModel.unreadCount;
    
    // 获取未读会话数量
    final conversationViewModel = Provider.of<ConversationViewModel>(context);
    final unreadConversationCount = conversationViewModel.totalUnreadCount;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动切换，只通过底部导航栏切换
        children: const [
          // 聊天列表页面
          ChatsTab(),
          // 联系人页面
          ContactsTab(),
          // 发现页面
          DiscoverTab(),
          // 个人资料页面
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          // 聊天标签（带未读消息数量）
          BottomNavigationBarItem(
            icon: _buildBottomNavIcon(
              _bottomNavItems[0].icon,
              _currentIndex == 0,
              unreadConversationCount,
            ),
            activeIcon: _buildBottomNavIcon(
              _bottomNavItems[0].activeIcon,
              _currentIndex == 0,
              unreadConversationCount,
            ),
            label: _bottomNavItems[0].label,
          ),
          // 联系人标签
          BottomNavigationBarItem(
            icon: Icon(_bottomNavItems[1].icon),
            activeIcon: Icon(_bottomNavItems[1].activeIcon),
            label: _bottomNavItems[1].label,
          ),
          // 发现标签
          BottomNavigationBarItem(
            icon: Icon(_bottomNavItems[2].icon),
            activeIcon: Icon(_bottomNavItems[2].activeIcon),
            label: _bottomNavItems[2].label,
          ),
          // 我的标签（带未读通知数量）
          BottomNavigationBarItem(
            icon: _buildBottomNavIcon(
              _bottomNavItems[3].icon,
              _currentIndex == 3,
              unreadNotificationCount,
            ),
            activeIcon: _buildBottomNavIcon(
              _bottomNavItems[3].activeIcon,
              _currentIndex == 3,
              unreadNotificationCount,
            ),
            label: _bottomNavItems[3].label,
          ),
        ],
      ),
    );
  }
  
  // 构建底部导航栏图标（带未读数量）
  Widget _buildBottomNavIcon(IconData iconData, bool isActive, int unreadCount) {
    if (unreadCount <= 0) {
      return Icon(iconData);
    }
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData),
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: unreadCount > 99 ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: unreadCount > 99 ? BorderRadius.circular(AppTheme.borderRadiusSmall) : null,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// 底部导航栏项目
class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}