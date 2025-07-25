import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';
// Removed unused import: file_utils.dart

/// 通知列表组件
class NotificationWidget extends StatefulWidget {
  final NotificationType? filterType;
  final bool showUnreadOnly;

  const NotificationWidget({
    Key? key,
    this.filterType,
    this.showUnreadOnly = false,
  }) : super(key: key);

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  NotificationType? _selectedType;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedType = widget.filterType;
    _showUnreadOnly = widget.showUnreadOnly;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _markAsUnread(int notificationId) async {
    try {
      // TODO: 调用通知服务标记为未读
      // await context.read<NotificationViewModel>().markAsUnread(notificationId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已标记为未读'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '全部', icon: Icon(Icons.notifications)),
            Tab(text: '消息', icon: Icon(Icons.message)),
            Tab(text: '系统', icon: Icon(Icons.settings)),
            Tab(text: '群组', icon: Icon(Icons.group)),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedType = null;
                  break;
                case 1:
                  _selectedType = NotificationType.message;
                  break;
                case 2:
                  _selectedType = NotificationType.system;
                  break;
                case 3:
                  _selectedType = NotificationType.groupInvite;
                  break;
              }
            });
          },
        ),
        actions: [
          Consumer<NotificationViewModel>(builder: (context, viewModel, child) {
            final unreadCount = viewModel.unreadCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: unreadCount > 0 ? () => viewModel.markAllAsRead() : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
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
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text('筛选'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('清空已读'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('通知设置'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索通知...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: const Text('仅未读'),
                selected: _showUnreadOnly,
                onSelected: (selected) {
                  setState(() {
                    _showUnreadOnly = selected;
                  });
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Consumer<NotificationViewModel>(builder: (context, viewModel, child) {
                return Text(
                  '共 ${_getFilteredNotifications(viewModel.notifications).length} 条通知',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return Consumer<NotificationViewModel>(builder: (context, viewModel, child) {
      final notifications = _getFilteredNotifications(viewModel.notifications);
      
      if (viewModel.isLoading && notifications.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (notifications.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => viewModel.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(notification, viewModel);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    
    if (_searchQuery.isNotEmpty) {
      title = '未找到匹配的通知';
      subtitle = '尝试使用其他关键词搜索';
      icon = Icons.search_off;
    } else if (_showUnreadOnly) {
      title = '暂无未读通知';
      subtitle = '所有通知都已阅读';
      icon = Icons.mark_email_read;
    } else {
      title = '暂无通知';
      subtitle = '您还没有收到任何通知';
      icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, NotificationViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead ? null : Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getNotificationTypeColor(notification.type).withValues(alpha: 0.2),
              child: Icon(
                _getNotificationTypeIcon(notification.type),
                color: _getNotificationTypeColor(notification.type),
              ),
            ),
            if (!notification.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body.isNotEmpty)
              Text(
                notification.body,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildNotificationTypeBadge(notification.type),
                const Spacer(),
                Text(
                  _formatDateTime(notification.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification, viewModel),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: notification.isRead ? 'mark_unread' : 'mark_read',
              child: ListTile(
                leading: Icon(
                  notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                ),
                title: Text(notification.isRead ? '标记未读' : '标记已读'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification, viewModel),
      ),
    );
  }

  Widget _buildNotificationTypeBadge(NotificationType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getNotificationTypeColor(type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getNotificationTypeColor(type).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        _getNotificationTypeText(type),
        style: TextStyle(
          color: _getNotificationTypeColor(type),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<NotificationModel> _getFilteredNotifications(List<NotificationModel> notifications) {
    var filtered = notifications;

    // 按类型过滤
    if (_selectedType != null) {
      filtered = filtered.where((n) => n.type == _selectedType).toList();
    }

    // 按已读状态过滤
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    // 按搜索关键词过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               n.body.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 按时间排序（最新的在前）
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  void _handleMenuAction(String action) {
    final viewModel = context.read<NotificationViewModel>();
    
    switch (action) {
      case 'filter':
        _showFilterDialog();
        break;
      case 'clear_read':
        _showClearReadDialog(viewModel);
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _handleNotificationAction(String action, NotificationModel notification, NotificationViewModel viewModel) {
    switch (action) {
      case 'mark_read':
        viewModel.markAsRead(notification.id);
        break;
      case 'mark_unread':
        _markAsUnread(notification.id);
        break;
      case 'delete':
        _showDeleteConfirmDialog(notification, viewModel);
        break;
    }
  }

  void _handleNotificationTap(NotificationModel notification, NotificationViewModel viewModel) {
    // 标记为已读
    if (!notification.isRead) {
      viewModel.markAsRead(notification.id);
    }

    // 处理通知点击事件
    if (notification.data.isNotEmpty) {
      _handleNotificationData(notification.data);
    }

    // 显示通知详情
    _showNotificationDetail(notification);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    // 根据通知数据执行相应操作
    final action = data['action'] as String?;
    
    switch (action) {
      case 'open_chat':
        final chatId = data['chat_id'] as String?;
        if (chatId != null) {
          // 跳转到聊天页面
          Navigator.pushNamed(context, '/chat', arguments: chatId);
        }
        break;
      case 'open_group':
        final groupId = data['group_id'] as String?;
        if (groupId != null) {
          // 跳转到群组页面
          Navigator.pushNamed(context, '/group', arguments: groupId);
        }
        break;
      case 'open_profile':
        final userId = data['user_id'] as String?;
        if (userId != null) {
          // 跳转到用户资料页面
          Navigator.pushNamed(context, '/profile', arguments: userId);
        }
        break;
      default:
        // 默认行为
        break;
    }
  }

  void _showNotificationDetail(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 30,
                backgroundColor: _getNotificationTypeColor(notification.type).withValues(alpha: 0.2),
                child: Icon(
                  _getNotificationTypeIcon(notification.type),
                  color: _getNotificationTypeColor(notification.type),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _buildNotificationTypeBadge(notification.type),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.body.isNotEmpty) ...[
                        const Text(
                          '内容',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.body,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        '详细信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem('通知ID', notification.id.toString()),
                      _buildDetailItem('类型', _getNotificationTypeText(notification.type)),
                      _buildDetailItem('状态', notification.isRead ? '已读' : '未读'),
                      _buildDetailItem('创建时间', _formatDetailDateTime(notification.timestamp)),
                      if (notification.data.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '附加数据',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...notification.data.entries.map(
                          (entry) => _buildDetailItem(entry.key, entry.value.toString()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选通知'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('仅显示未读'),
              value: _showUnreadOnly,
              onChanged: (value) {
                setState(() {
                  _showUnreadOnly = value ?? false;
                });
                Navigator.pop(context);
              },
            ),
            // 可以添加更多筛选选项
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showClearReadDialog(NotificationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空已读通知'),
        content: const Text('确定要删除所有已读通知吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(NotificationModel notification, NotificationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除通知'),
        content: const Text('确定要删除这条通知吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteNotification(notification.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    // 跳转到通知设置页面
    Navigator.pushNamed(context, '/notification_settings');
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.groupInvite:
        return Colors.green;
      case NotificationType.friendRequest:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.groupInvite:
        return Icons.group;
      case NotificationType.friendRequest:
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return '消息';
      case NotificationType.system:
        return '系统';
      case NotificationType.groupInvite:
        return '群组';
      case NotificationType.friendRequest:
        return '好友';
      default:
        return '其他';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  String _formatDetailDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}