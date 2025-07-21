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
                // TODO: 实现语音通话功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('语音通话功能尚未实现')),
                );
              },
            ),
            
            // 视频通话按钮
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                // TODO: 实现视频通话功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('视频通话功能尚未实现')),
                );
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
                  // TODO: 实现搜索聊天记录功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('搜索聊天记录功能尚未实现')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('静音通知'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 实现静音通知功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('静音通知功能尚未实现')),
                  );
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
}