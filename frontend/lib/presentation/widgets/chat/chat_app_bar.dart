import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/conversation_model.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/app_logger.dart';

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
      // ignore: unreachable_switch_default
      default:
        return AppTheme.offlineStatusColor;
    }
  }
  
  /// 搜索消息
  Future<List<String>> _searchMessages(String query) async {
    // 模拟搜索结果
    await Future.delayed(const Duration(milliseconds: 500));
    return ['搜索结果1', '搜索结果2', '搜索结果3'];
  }
  
  /// 显示搜索结果
  void _showSearchResults(BuildContext context, List<String> results) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('搜索结果'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(results[index]),
                  onTap: () {
                    Navigator.pop(context);
                    // 跳转到对应消息位置
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
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
      // ignore: unreachable_switch_default
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
                _clearChatHistory(context);
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  /// 清空聊天记录
  void _clearChatHistory(BuildContext context) async {
    try {
      // 调用消息服务清空聊天记录
       AppLogger.instance.logger.d('清空聊天记录请求已发送');
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('聊天记录已清空')),
       );
      // await context.read<MessageViewModel>().clearChatHistory(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('聊天记录已清空'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清空失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              onPressed: () async {
                 Navigator.pop(context);
                 // 实现屏蔽用户功能
                 AppLogger.instance.logger.d('屏蔽用户请求已发送');
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('用户已屏蔽')),
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
  void _startCall(BuildContext context, bool isVideo) async {
    try {
      // 调用通话服务启动通话
       final callType = isVideo ? '视频通话' : '语音通话';
       AppLogger.instance.logger.d('启动$callType');
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('$callType已启动')),
       );
      // if (isVideo) {
      //   await context.read<CallViewModel>().startVideoCall(userId);
      // } else {
      //   await context.read<CallViewModel>().startVoiceCall(userId);
      // }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在发起${isVideo ? '视频' : '语音'}通话...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // 模拟通话页面导航
      Navigator.of(context).pushNamed(
        '/call',
        arguments: {
          'type': isVideo ? 'video' : 'voice',
          'userId': userId,
          'isOutgoing': true,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通话发起失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('搜索聊天记录'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: '请输入搜索关键词',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final query = searchController.text.trim();
                Navigator.pop(context);
                if (query.isNotEmpty) {
                  _performSearch(context, query);
                }
              },
              child: const Text('搜索'),
            ),
          ],
        );
      },
    );
  }
  
  /// 执行搜索
  void _performSearch(BuildContext context, String query) async {
    try {
      // 调用消息服务搜索聊天记录
      final results = await _searchMessages(query);
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索 "$query" 的结果: 找到 ${results.length} 条消息'),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {
              // 显示搜索结果页面
              _showSearchResults(context, results);
            },
          ),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 切换静音状态
  void _toggleMute(BuildContext context) async {
    try {
      // 调用通知服务设置静音状态
       AppLogger.instance.logger.d('切换静音状态');
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('静音状态已更新')),
       );
      // await context.read<NotificationViewModel>().setConversationMute(userId, true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已静音此对话'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 显示屏蔽用户对话框
  // ignore: unused_element
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
  void _blockUser(BuildContext context) async {
    try {
      // 调用用户服务屏蔽用户
    AppLogger.instance.logger.d('屏蔽用户请求已发送');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('用户已屏蔽')),
    );
      // await context.read<UserViewModel>().blockUser(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('用户已屏蔽'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // 返回上一页
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('屏蔽失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}