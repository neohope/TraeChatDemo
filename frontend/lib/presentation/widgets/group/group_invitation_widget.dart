import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/group_model.dart';
import '../../viewmodels/group_viewmodel.dart';

/// 群组邀请管理组件
class GroupInvitationWidget extends StatefulWidget {
  final String? groupId;
  final bool showSentInvitations;

  const GroupInvitationWidget({
    Key? key,
    this.groupId,
    this.showSentInvitations = false,
  }) : super(key: key);

  @override
  State<GroupInvitationWidget> createState() => _GroupInvitationWidgetState();
}

class _GroupInvitationWidgetState extends State<GroupInvitationWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.groupId != null ? 2 : 1,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<GroupViewModel>();
      viewModel.loadReceivedInvitations();
      if (widget.groupId != null) {
        viewModel.loadSentInvitations(widget.groupId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('群组邀请'),
        bottom: widget.groupId != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '收到的邀请', icon: Icon(Icons.inbox)),
                  Tab(text: '发出的邀请', icon: Icon(Icons.outbox)),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInvitations,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('清空已处理'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('全部标记已读'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: widget.groupId != null
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReceivedInvitations(),
                      _buildSentInvitations(),
                    ],
                  )
                : _buildReceivedInvitations(),
          ),
        ],
      ),
      floatingActionButton: widget.groupId != null
          ? FloatingActionButton(
              onPressed: _showCreateInvitationDialog,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索邀请...',
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
    );
  }

  Widget _buildReceivedInvitations() {
    return Consumer<GroupViewModel>(builder: (context, viewModel, child) {
      final invitations = _getFilteredReceivedInvitations(viewModel.receivedInvitations);
      
      if (viewModel.isLoading && invitations.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (invitations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: '暂无收到的邀请',
          subtitle: _searchQuery.isNotEmpty ? '未找到匹配的邀请' : '您还没有收到任何群组邀请',
        );
      }

      return RefreshIndicator(
        onRefresh: () => viewModel.loadReceivedInvitations(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _buildReceivedInvitationItem(invitation, viewModel);
          },
        ),
      );
    });
  }

  Widget _buildSentInvitations() {
    return Consumer<GroupViewModel>(builder: (context, viewModel, child) {
      final invitations = _getFilteredSentInvitations(viewModel.sentInvitations);
      
      if (viewModel.isLoading && invitations.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (invitations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.outbox_outlined,
          title: '暂无发出的邀请',
          subtitle: _searchQuery.isNotEmpty ? '未找到匹配的邀请' : '您还没有发出任何群组邀请',
        );
      }

      return RefreshIndicator(
        onRefresh: () => viewModel.loadSentInvitations(widget.groupId!),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _buildSentInvitationItem(invitation, viewModel);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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

  Widget _buildReceivedInvitationItem(GroupInvitation invitation, GroupViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              child: const Icon(Icons.group),
            ),
            if (!invitation.isRead)
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
          'Group ${invitation.groupId}',
          style: TextStyle(
            fontWeight: invitation.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('邀请人: ${invitation.inviterId}'),
            if (invitation.message != null && invitation.message!.isNotEmpty)
              Text(
                invitation.message!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _formatDateTime(invitation.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: _buildInvitationStatusBadge(invitation.status),
        onTap: () => _showInvitationDetail(invitation, viewModel),
      ),
    );
  }

  Widget _buildSentInvitationItem(GroupInvitation invitation, GroupViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(Icons.person),
        ),
        title: Text(invitation.inviteeId),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (invitation.message != null && invitation.message!.isNotEmpty)
              Text(
                invitation.message!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _formatDateTime(invitation.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            // Note: expiresAt not available in current model
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInvitationStatusBadge(invitation.status),
            if (invitation.status == GroupInvitationStatus.pending)
              PopupMenuButton<String>(
                onSelected: (value) => _handleSentInvitationAction(value, invitation, viewModel),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'resend',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('重新发送'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: Icon(Icons.cancel, color: Colors.red),
                      title: Text('取消邀请', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        onTap: () => _showSentInvitationDetail(invitation, viewModel),
      ),
    );
  }

  Widget _buildInvitationStatusBadge(GroupInvitationStatus status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status) {
      case GroupInvitationStatus.pending:
        color = Colors.orange;
        text = '待处理';
        icon = Icons.schedule;
        break;
      case GroupInvitationStatus.accepted:
        color = Colors.green;
        text = '已接受';
        icon = Icons.check_circle;
        break;
      case GroupInvitationStatus.rejected:
        color = Colors.red;
        text = '已拒绝';
        icon = Icons.cancel;
        break;
      case GroupInvitationStatus.expired:
        color = Colors.grey;
        text = '已过期';
        icon = Icons.access_time;
        break;
      // Note: cancelled status not available in current model
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showInvitationDetail(GroupInvitation invitation, GroupViewModel viewModel) {
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
                radius: 40,
                child: const Icon(Icons.group, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Group ${invitation.groupId}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInvitationStatusBadge(invitation.status),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem('群组ID', invitation.groupId),
                    _buildDetailItem('群组名称', 'Group ${invitation.groupId}'),
                    _buildDetailItem('邀请人', invitation.inviterId),
                    if (invitation.message != null && invitation.message!.isNotEmpty)
                      _buildDetailItem('邀请消息', invitation.message!),
                    _buildDetailItem('邀请时间', _formatDateTime(invitation.createdAt)),
                    // Note: expiresAt not available in current model
                    _buildDetailItem('状态', _getStatusText(invitation.status)),
                  ],
                ),
              ),
              if (invitation.status == GroupInvitationStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleInvitationAction('reject', invitation, viewModel);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('拒绝'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleInvitationAction('accept', invitation, viewModel);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('接受'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSentInvitationDetail(GroupInvitation invitation, GroupViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.7,
        minChildSize: 0.3,
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
                radius: 40,
                child: const Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                invitation.inviteeId,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInvitationStatusBadge(invitation.status),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem('被邀请人', invitation.inviteeId),
                    if (invitation.message != null && invitation.message!.isNotEmpty)
                      _buildDetailItem('邀请消息', invitation.message!),
                    _buildDetailItem('邀请时间', _formatDateTime(invitation.createdAt)),
                    // Note: expiresAt not available in current model
                    _buildDetailItem('状态', _getStatusText(invitation.status)),
                  ],
                ),
              ),
              if (invitation.status == GroupInvitationStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleSentInvitationAction('cancel', invitation, viewModel);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('取消邀请'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleSentInvitationAction('resend', invitation, viewModel);
                        },
                        child: const Text('重新发送'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateInvitationDialog() {
    final messageController = TextEditingController();
    final userController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: '用户ID或昵称',
                border: OutlineInputBorder(),
                hintText: '输入要邀请的用户',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: '邀请消息（可选）',
                border: OutlineInputBorder(),
                hintText: '添加邀请消息...',
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (userController.text.isNotEmpty) {
                Navigator.pop(context);
                context.read<GroupViewModel>().inviteToGroup(
                  widget.groupId!,
                  userController.text,
                  message: messageController.text.isNotEmpty ? messageController.text : null,
                );
              }
            },
            child: const Text('发送邀请'),
          ),
        ],
      ),
    );
  }

  List<GroupInvitation> _getFilteredReceivedInvitations(List<GroupInvitation> invitations) {
    if (_searchQuery.isEmpty) return invitations;
    
    return invitations.where((invitation) {
      return invitation.groupId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             invitation.inviterId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (invitation.message?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<GroupInvitation> _getFilteredSentInvitations(List<GroupInvitation> invitations) {
    if (_searchQuery.isEmpty) return invitations;
    
    return invitations.where((invitation) {
      return invitation.inviteeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (invitation.message?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _refreshInvitations() {
    final viewModel = context.read<GroupViewModel>();
    viewModel.loadReceivedInvitations();
    if (widget.groupId != null) {
      viewModel.loadSentInvitations(widget.groupId!);
    }
  }

  void _handleMenuAction(String action) {
    final viewModel = context.read<GroupViewModel>();
    
    switch (action) {
      case 'clear_all':
        _showClearAllDialog(viewModel);
        break;
      case 'mark_all_read':
        viewModel.markAllInvitationsAsRead();
        break;
    }
  }

  void _handleInvitationAction(String action, GroupInvitation invitation, GroupViewModel viewModel) {
    switch (action) {
      case 'accept':
        viewModel.respondToInvitation(invitation.id, true);
        break;
      case 'reject':
        viewModel.respondToInvitation(invitation.id, false);
        break;
    }
  }

  void _handleSentInvitationAction(String action, GroupInvitation invitation, GroupViewModel viewModel) {
    switch (action) {
      case 'resend':
        // TODO: Implement resend invitation functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重新发送功能暂未实现')),
        );
        break;
      case 'cancel':
        // TODO: Implement cancel invitation functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('取消邀请功能暂未实现')),
        );
        break;
    }
  }

  void _showClearAllDialog(GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空已处理邀请'),
        content: const Text('确定要清空所有已接受、已拒绝和已过期的邀请吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear processed invitations functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('清空功能暂未实现')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(GroupInvitationStatus status) {
    switch (status) {
      case GroupInvitationStatus.pending:
        return '待处理';
      case GroupInvitationStatus.accepted:
        return '已接受';
      case GroupInvitationStatus.rejected:
        return '已拒绝';
      case GroupInvitationStatus.expired:
        return '已过期';
      // Note: cancelled status not available in current model
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
}