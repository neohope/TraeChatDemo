import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/conversation_model.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../themes/app_theme.dart';

/// 聊天页面的应用栏
/// 
/// 显示聊天对象的信息，包括头像、名称、在线状态等
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userId;
  final String? userName;
  
  const ChatAppBar({
    Key? key,
    required this.userId,
    this.userName,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userViewModel, child) {
        // 获取用户信息
        final user = userViewModel.getCachedUserById(userId);
        final displayName = userName ?? user?.name ?? '未知用户';
        final userStatus = user?.status ?? UserStatus.offline;
        
        return AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              // 用户头像
              _buildUserAvatar(context, user?.avatarUrl),
              
              const SizedBox(width: AppTheme.spacingSmall),
              
              // 用户名称和状态
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 用户名称
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 用户状态
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(userStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(userStatus),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // 语音通话按钮
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                _showCallDialog(context, false);
              },
            ),
            
            // 视频通话按钮
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                _showCallDialog(context, true);
              },
            ),
            
            // 更多选项按钮
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showMoreOptions(context);
              },
            ),
          ],
        );
      },
    );
  }
  
  /// 构建用户头像
  Widget _buildUserAvatar(BuildContext context, String? avatarUrl) {
    return Container(
      width: AppTheme.avatarSizeNormal,
      height: AppTheme.avatarSizeNormal,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withAlpha(50),
      ),
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.avatarSizeNormal / 2),
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person);
                },
              ),
            )
          : const Icon(Icons.person),
    );
  }
  
  /// 获取状态颜色
  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return AppTheme.onlineStatusColor;
      case UserStatus.offline:
        return AppTheme.offlineStatusColor;
      case UserStatus.busy:
        return AppTheme.busyStatusColor;
      case UserStatus.away:
        return AppTheme.awayStatusColor;
      default:
        return AppTheme.offlineStatusColor;
    }
  }
  
  /// 获取状态文本
  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return '在线';
      case UserStatus.offline:
        return '离线';
      case UserStatus.busy:
        return '忙碌';
      case UserStatus.away:
        return '离开';
      default:
        return '离线';
    }
  }
  
  /// 显示更多选项
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('搜索聊天记录'),
                onTap: () {
                  Navigator.pop(context);
                  _showSearchDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('静音通知'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleMute(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('清空聊天记录'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmClearChat(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('屏蔽用户'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmBlockUser(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 确认清空聊天记录
  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空聊天记录'),
          content: const Text('确定要清空与该用户的所有聊天记录吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 实现清空聊天记录功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('清空聊天记录功能尚未实现')),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
  
  /// 确认屏蔽用户
  void _confirmBlockUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('屏蔽用户'),
          content: const Text('确定要屏蔽该用户吗？屏蔽后将不再收到该用户的消息。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 实现屏蔽用户功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('屏蔽用户功能尚未实现')),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示通话对话框
  void _showCallDialog(BuildContext context, bool isVideo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isVideo ? '视频通话' : '语音通话'),
          content: Text('确定要与该用户进行${isVideo ? '视频' : '语音'}通话吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startCall(context, isVideo);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
  
  /// 开始通话
  void _startCall(BuildContext context, bool isVideo) {
    // TODO: 实现实际的通话功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在发起${isVideo ? '视频' : '语音'}通话...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('搜索聊天记录'),
          content: const TextField(
            decoration: InputDecoration(
              hintText: '请输入搜索关键词',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 实现搜索功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('搜索功能尚未实现')),
                );
              },
              child: const Text('搜索'),
            ),
          ],
        );
      },
    );
  }
  
  /// 切换静音状态
  void _toggleMute(BuildContext context) {
    // TODO: 实现静音功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('静音功能尚未实现')),
    );
  }
  
  /// 显示屏蔽用户对话框
  void _showBlockUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('屏蔽用户'),
          content: const Text('确定要屏蔽该用户吗？屏蔽后将不会收到该用户的消息。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('屏蔽'),
            ),
          ],
        );
      },
    );
  }
  
  /// 屏蔽用户
  void _blockUser(BuildContext context) {
    // TODO: 实现屏蔽用户功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('用户已屏蔽'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}