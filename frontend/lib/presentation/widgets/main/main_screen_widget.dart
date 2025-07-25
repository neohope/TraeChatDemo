import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import '../../viewmodels/auth_viewmodel.dart';
// import '../../viewmodels/user_viewmodel.dart'; // Unused import
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../chat/chat_list_widget.dart';
// import '../user/user_list_widget.dart'; // Unused import
import '../friend/friend_list_widget.dart';
import '../group/group_list_widget.dart';
import '../notification/notification_widget.dart';
import '../settings/settings_widget.dart';
import '../../../core/utils/app_logger.dart';

/// 主屏幕组件
class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({Key? key}) : super(key: key);

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  final PageController _pageController = PageController();

  final List<MainTab> _tabs = [
    MainTab(
      title: '聊天',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
    ),
    MainTab(
      title: '联系人',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    MainTab(
      title: '发现',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    MainTab(
      title: '通知',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
    ),
    MainTab(
      title: '我的',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _tabController.animateTo(index);
        },
        children: [
          _buildChatPage(),
          _buildContactsPage(),
          _buildDiscoverPage(),
          _buildNotificationPage(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildChatPage() {
    return const ChatListWidget();
  }

  Widget _buildContactsPage() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('联系人'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: '好友'),
              Tab(text: '群组'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendListWidget(),
            GroupListWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          _buildDiscoverItem(
            icon: Icons.people_alt_outlined,
            title: '附近的人',
            subtitle: '发现附近的用户',
            onTap: () => _navigateToNearbyUsers(),
          ),
          _buildDiscoverItem(
            icon: Icons.group_add_outlined,
            title: '创建群组',
            subtitle: '创建新的群组聊天',
            onTap: () => _navigateToCreateGroup(),
          ),
          _buildDiscoverItem(
            icon: Icons.qr_code_scanner,
            title: '扫一扫',
            subtitle: '扫描二维码添加好友',
            onTap: () => _navigateToQRScanner(),
          ),
          _buildDiscoverItem(
            icon: Icons.share,
            title: '我的二维码',
            subtitle: '分享您的二维码',
            onTap: () => _navigateToMyQRCode(),
          ),
          const Divider(),
          _buildDiscoverItem(
            icon: Icons.trending_up,
            title: '热门话题',
            subtitle: '查看当前热门话题',
            onTap: () => _navigateToTrendingTopics(),
          ),
          _buildDiscoverItem(
            icon: Icons.public,
            title: '公共频道',
            subtitle: '加入公共聊天频道',
            onTap: () => _navigateToPublicChannels(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    return const NotificationWidget();
  }

  Widget _buildProfilePage() {
    return const SettingsWidget();
  }

  Widget _buildBottomNavigationBar() {
    return Consumer2<NotificationViewModel, ChatViewModel>(
      builder: (context, notificationViewModel, chatViewModel, child) {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          items: _tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isActive = index == _currentIndex;
            
            Widget icon = Icon(
              isActive ? tab.activeIcon : tab.icon,
              size: 24,
            );

            // 添加未读消息徽章
            if (index == 0) { // 聊天页面
              // 实现未读消息总数显示
               final unreadCount = chatViewModel.conversations
                   .fold<int>(0, (sum, conversation) => sum + conversation.unreadCount);
              if (unreadCount > 0) {
                icon = badges.Badge(
                  badgeContent: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(4),
                  ),
                  child: icon,
                );
              }
            } else if (index == 3) { // 通知页面
              final unreadCount = notificationViewModel.unreadCount;
              if (unreadCount > 0) {
                icon = badges.Badge(
                  badgeContent: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(4),
                  ),
                  child: icon,
                );
              }
            }

            return BottomNavigationBarItem(
              icon: icon,
              label: tab.title,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDiscoverItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _initializeData() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      // final userViewModel = Provider.of<UserViewModel>(context, listen: false); // Unused
      // final chatViewModel = Provider.of<ChatViewModel>(context, listen: false); // Unused
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      final groupViewModel = Provider.of<GroupViewModel>(context, listen: false);
      // final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false); // Unused

      // 检查登录状态
      if (!authViewModel.isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // 初始化用户数据
      // TODO: implement loadCurrentUser in UserViewModel
      // await userViewModel.loadCurrentUser();
      
      // 并行加载其他数据
      await Future.wait([
        // TODO: implement loadChats in ChatViewModel
        // chatViewModel.loadChats(),
        friendViewModel.loadFriends(),
        groupViewModel.loadGroups(),
        // TODO: implement loadNotifications in NotificationViewModel
        // notificationViewModel.loadNotifications(),
      ]);
      
      // 初始化未读消息总数
      // TODO: 实现ChatViewModel中的totalUnreadCount getter
    } catch (e) {
      AppLogger.instance.error('Failed to initialize main screen data: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载数据失败: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重试',
              onPressed: _initializeData,
            ),
          ),
        );
      }
    }
  }

  void _navigateToNearbyUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyUsersWidget(),
      ),
    );
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupWidget(),
      ),
    );
  }

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(),
      ),
    );
  }

  void _navigateToMyQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyQRCodeWidget(),
      ),
    );
  }

  void _navigateToTrendingTopics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrendingTopicsWidget(),
      ),
    );
  }

  void _navigateToPublicChannels() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicChannelsWidget(),
      ),
    );
  }
}

/// 主页面标签页数据模型
class MainTab {
  final String title;
  final IconData icon;
  final IconData activeIcon;

  const MainTab({
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}

/// 附近的人组件
class NearbyUsersWidget extends StatefulWidget {
  const NearbyUsersWidget({Key? key}) : super(key: key);

  @override
  State<NearbyUsersWidget> createState() => _NearbyUsersWidgetState();
}

class _NearbyUsersWidgetState extends State<NearbyUsersWidget> {
  bool _isLoading = true;
  List<dynamic> _nearbyUsers = [];
  double _searchRadius = 5.0; // 搜索半径（公里）

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('附近的人'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchRadiusSlider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _nearbyUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRadiusSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '搜索半径: ${_searchRadius.toStringAsFixed(1)} 公里',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _searchRadius,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            onChanged: (value) {
              setState(() {
                _searchRadius = value;
              });
            },
            onChangeEnd: (value) {
              _loadNearbyUsers();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '附近没有发现其他用户',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试扩大搜索范围',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: _nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = _nearbyUsers[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildUserItem(dynamic user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user['avatarUrl'] != null
            ? NetworkImage(user['avatarUrl'])
            : null,
        child: user['avatarUrl'] == null
            ? Text(
                user['nickname'].substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user['nickname'],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '距离 ${user['distance'].toStringAsFixed(1)} 公里',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _addFriend(user),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => _startChat(user),
          ),
        ],
      ),
      onTap: () => _viewUserProfile(user),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选条件'),
        content: const Text('筛选功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNearbyUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟加载附近用户
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _nearbyUsers = [
          {
            'id': '1',
            'nickname': '张三',
            'avatarUrl': null,
            'distance': 2.3,
          },
          {
            'id': '2',
            'nickname': '李四',
            'avatarUrl': null,
            'distance': 4.1,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载附近用户失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addFriend(dynamic user) {
    // 添加好友逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已向 ${user['nickname']} 发送好友请求'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _startChat(dynamic user) {
    // 开始聊天逻辑
    Navigator.pop(context);
  }

  void _viewUserProfile(dynamic user) {
    // 查看用户资料逻辑
  }
}

/// 创建群组组件
class CreateGroupWidget extends StatefulWidget {
  const CreateGroupWidget({Key? key}) : super(key: key);

  @override
  State<CreateGroupWidget> createState() => _CreateGroupWidgetState();
}

class _CreateGroupWidgetState extends State<CreateGroupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;
  int _maxMembers = 100;
  List<dynamic> _selectedFriends = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建群组'),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text('创建'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGroupAvatar(),
            const SizedBox(height: 24),
            _buildGroupName(),
            const SizedBox(height: 16),
            _buildGroupDescription(),
            const SizedBox(height: 16),
            _buildPrivacySettings(),
            const SizedBox(height: 16),
            _buildMaxMembersSlider(),
            const SizedBox(height: 24),
            _buildMemberSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupAvatar() {
    return Center(
      child: GestureDetector(
        onTap: _selectGroupAvatar,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 32,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupName() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '群组名称',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入群组名称';
        }
        return null;
      },
    );
  }

  Widget _buildGroupDescription() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: '群组描述（可选）',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildPrivacySettings() {
    return SwitchListTile(
      title: const Text('私有群组'),
      subtitle: const Text('只有受邀请的用户才能加入'),
      value: _isPrivate,
      onChanged: (value) {
        setState(() {
          _isPrivate = value;
        });
      },
    );
  }

  Widget _buildMaxMembersSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最大成员数: $_maxMembers',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: _maxMembers.toDouble(),
          min: 10,
          max: 500,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _maxMembers = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildMemberSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '选择成员',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _selectMembers,
              child: const Text('选择'),
            ),
          ],
        ),
        if (_selectedFriends.isNotEmpty)
          Container(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFriends.length,
              itemBuilder: (context, index) {
                final friend = _selectedFriends[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(
                          friend['nickname'].substring(0, 1).toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend['nickname'],
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _selectGroupAvatar() {
    // 选择群组头像逻辑
  }

  void _selectMembers() {
    // 选择成员逻辑
  }

  void _createGroup() {
    if (_formKey.currentState!.validate()) {
      // 创建群组逻辑
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('群组创建成功'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// 二维码扫描组件
class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({Key? key}) : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫一扫'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          '二维码扫描功能开发中...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// 我的二维码组件
class MyQRCodeWidget extends StatefulWidget {
  const MyQRCodeWidget({Key? key}) : super(key: key);

  @override
  State<MyQRCodeWidget> createState() => _MyQRCodeWidgetState();
}

class _MyQRCodeWidgetState extends State<MyQRCodeWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的二维码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQRCode,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Center(
                child: Text(
                  '二维码\n生成中...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '扫描上方二维码，添加我为好友',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareQRCode() {
    // 分享二维码逻辑
  }
}

/// 热门话题组件
class TrendingTopicsWidget extends StatefulWidget {
  const TrendingTopicsWidget({Key? key}) : super(key: key);

  @override
  State<TrendingTopicsWidget> createState() => _TrendingTopicsWidgetState();
}

class _TrendingTopicsWidgetState extends State<TrendingTopicsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('热门话题'),
      ),
      body: const Center(
        child: Text(
          '热门话题功能开发中...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// 公共频道组件
class PublicChannelsWidget extends StatefulWidget {
  const PublicChannelsWidget({Key? key}) : super(key: key);

  @override
  State<PublicChannelsWidget> createState() => _PublicChannelsWidgetState();
}

class _PublicChannelsWidgetState extends State<PublicChannelsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('公共频道'),
      ),
      body: const Center(
        child: Text(
          '公共频道功能开发中...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}