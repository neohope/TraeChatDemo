import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

/// 附近的人页面
/// 
/// 显示附近的用户，支持筛选和搜索
class NearbyPeoplePage extends StatefulWidget {
  const NearbyPeoplePage({Key? key}) : super(key: key);

  @override
  State<NearbyPeoplePage> createState() => _NearbyPeoplePageState();
}

class _NearbyPeoplePageState extends State<NearbyPeoplePage> {
  bool _isLoading = false;
  List<NearbyUser> _nearbyUsers = [];
  String _selectedGender = '全部';
  double _maxDistance = 10.0; // 默认10公里
  
  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }
  
  // 加载附近的人
  Future<void> _loadNearbyUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    // 模拟从服务器加载数据
    await Future.delayed(const Duration(seconds: 1));
    
    // 生成测试数据
    final random = Random();
    final testUsers = List.generate(
      20,
      (index) => NearbyUser(
        id: 'user_$index',
        name: '用户${index + 1}',
        avatar: 'https://picsum.photos/200/200?random=$index',
        gender: random.nextBool() ? '男' : '女',
        distance: random.nextDouble() * 10.0, // 0-10公里
        lastActiveTime: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
      ),
    );
    
    setState(() {
      _nearbyUsers = testUsers;
      _isLoading = false;
    });
  }
  
  // 筛选用户
  List<NearbyUser> _filterUsers() {
    return _nearbyUsers.where((user) {
      // 按性别筛选
      if (_selectedGender != '全部' && user.gender != _selectedGender) {
        return false;
      }
      
      // 按距离筛选
      if (user.distance > _maxDistance) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  // 刷新附近的人
  Future<void> _refreshNearbyUsers() async {
    await _loadNearbyUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('附近的人'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshNearbyUsers,
            child: _buildUserList(),
          ),
          if (_isLoading)
            LoadingOverlay(
              isLoading: true,
              child: Container(),
            ),
        ],
      ),
    );
  }
  
  // 构建用户列表
  Widget _buildUserList() {
    final filteredUsers = _filterUsers();
    
    if (filteredUsers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingNormal),
            Text(
              '附近没有找到符合条件的人',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return NearbyUserCard(
          user: user,
          onTap: () => _viewUserProfile(user),
        );
      },
    );
  }
  
  // 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('筛选'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 性别筛选
                  const Text('性别'),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      _buildGenderFilterChip('全部', setState),
                      const SizedBox(width: AppTheme.spacingSmall),
                      _buildGenderFilterChip('男', setState),
                      const SizedBox(width: AppTheme.spacingSmall),
                      _buildGenderFilterChip('女', setState),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingNormal),
                  
                  // 距离筛选
                  Text('最大距离: ${_maxDistance.toStringAsFixed(1)}公里'),
                  Slider(
                    value: _maxDistance,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${_maxDistance.toStringAsFixed(1)}公里',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 应用筛选并刷新列表
                    this.setState(() {});
                  },
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 构建性别筛选芯片
  Widget _buildGenderFilterChip(String gender, StateSetter setState) {
    final isSelected = _selectedGender == gender;
    
    return FilterChip(
      label: Text(gender),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedGender = gender;
        });
      },
    );
  }
  
  // 查看用户资料
  void _viewUserProfile(NearbyUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusNormal)),
      ),
      builder: (context) {
        return Consumer<UserViewModel>(
          builder: (context, userViewModel, child) {
            
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingNormal),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 用户头像
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.avatar),
                  ),
                  const SizedBox(height: AppTheme.spacingNormal),
                  
                  // 用户名称
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  
                  // 用户信息
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        user.gender == '男' ? Icons.male : Icons.female,
                        color: user.gender == '男' ? Colors.blue : Colors.pink,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(user.gender),
                      const SizedBox(width: AppTheme.spacingNormal),
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text('${user.distance.toStringAsFixed(1)}公里'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  
                  // 最后活跃时间
                  Text(
                    '最后活跃: ${_formatLastActiveTime(user.lastActiveTime)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingNormal),
                  
                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 打招呼按钮
                      ElevatedButton.icon(
                        icon: const Icon(Icons.waving_hand),
                        label: const Text('打招呼'),
                        onPressed: () {
                          Navigator.pop(context);
                          _sayHello(user);
                        },
                      ),
                      
                      // 添加好友按钮
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('添加好友'),
                        onPressed: () {
                          Navigator.pop(context);
                          _addFriend(user);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // 打招呼
  void _sayHello(NearbyUser user) {
    // 导航到聊天页面
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'userId': user.id,
        'userName': user.name,
      },
    );
  }
  
  // 添加好友
  void _addFriend(NearbyUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加好友'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('你确定要添加 ${user.name} 为好友吗？'),
              const SizedBox(height: AppTheme.spacingNormal),
              const TextField(
                decoration: InputDecoration(
                  hintText: '验证消息',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 发送好友请求
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('好友请求已发送')),
                );
              },
              child: const Text('发送'),
            ),
          ],
        );
      },
    );
  }
  
  // 格式化最后活跃时间
  String _formatLastActiveTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}月${time.day}日 ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 附近的用户模型
class NearbyUser {
  final String id;
  final String name;
  final String avatar;
  final String gender;
  final double distance; // 单位：公里
  final DateTime lastActiveTime;
  
  NearbyUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.gender,
    required this.distance,
    required this.lastActiveTime,
  });
}

/// 附近用户卡片组件
class NearbyUserCard extends StatelessWidget {
  final NearbyUser user;
  final VoidCallback onTap;
  
  const NearbyUserCard({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingNormal),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingNormal),
          child: Row(
            children: [
              // 用户头像
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(user.avatar),
              ),
              const SizedBox(width: AppTheme.spacingNormal),
              
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户名和性别
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.fontSizeMedium,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Icon(
                          user.gender == '男' ? Icons.male : Icons.female,
                          size: 16,
                          color: user.gender == '男' ? Colors.blue : Colors.pink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 距离和最后活跃时间
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${user.distance.toStringAsFixed(1)}公里',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingNormal),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatLastActiveTime(user.lastActiveTime),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: onTap,
                tooltip: '打招呼',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 格式化最后活跃时间
  String _formatLastActiveTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}月${time.day}日';
    }
  }
}