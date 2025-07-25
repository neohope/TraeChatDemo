import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/group_model.dart';
import '../../viewmodels/group_viewmodel.dart';

/// 群组成员管理组件
class GroupMemberWidget extends StatefulWidget {
  final String groupId;
  final bool isManagementMode;

  const GroupMemberWidget({
    Key? key,
    required this.groupId,
    this.isManagementMode = false,
  }) : super(key: key);

  @override
  State<GroupMemberWidget> createState() => _GroupMemberWidgetState();
}

class _GroupMemberWidgetState extends State<GroupMemberWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GroupMemberRole? _selectedRole;
  bool _showOnlineOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().loadGroupMembers(widget.groupId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isManagementMode ? '成员管理' : '群组成员'),
        actions: [
          if (widget.isManagementMode)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showInviteMemberDialog,
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text('搜索成员'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text('筛选'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('导出成员列表'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<GroupViewModel>(builder: (context, viewModel, child) {
        final members = _getFilteredMembers(viewModel.currentMembers);
        
        if (viewModel.isLoading && members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildSearchAndFilter(),
            _buildMemberStats(members),
            Expanded(
              child: _buildMemberList(members, viewModel),
            ),
          ],
        );
      }),
      floatingActionButton: widget.isManagementMode
          ? FloatingActionButton(
              onPressed: _showInviteMemberDialog,
              child: const Icon(Icons.person_add),
            )
          : null,
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
              hintText: '搜索成员...',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '全部',
                  isSelected: _selectedRole == null,
                  onSelected: () {
                    setState(() {
                      _selectedRole = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '群主',
                  isSelected: _selectedRole == GroupMemberRole.owner,
                  onSelected: () {
                    setState(() {
                      _selectedRole = GroupMemberRole.owner;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '管理员',
                  isSelected: _selectedRole == GroupMemberRole.admin,
                  onSelected: () {
                    setState(() {
                      _selectedRole = GroupMemberRole.admin;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '成员',
                  isSelected: _selectedRole == GroupMemberRole.member,
                  onSelected: () {
                    setState(() {
                      _selectedRole = GroupMemberRole.member;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '仅在线',
                  isSelected: _showOnlineOnly,
                  onSelected: () {
                    setState(() {
                      _showOnlineOnly = !_showOnlineOnly;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildMemberStats(List<GroupMember> members) {
    final totalCount = members.length;
    final onlineCount = members.where((m) => m.isActive).length;
    final adminCount = members.where((m) => m.role == GroupMemberRole.admin).length;
    final mutedCount = members.where((m) => m.isMuted).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('总数', totalCount.toString(), Colors.blue),
          const SizedBox(width: 16),
          _buildStatItem('在线', onlineCount.toString(), Colors.green),
          const SizedBox(width: 16),
          _buildStatItem('管理员', adminCount.toString(), Colors.orange),
          const SizedBox(width: 16),
          _buildStatItem('禁言', mutedCount.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList(List<GroupMember> members, GroupViewModel viewModel) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '未找到匹配的成员' : '暂无成员',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadGroupMembers(widget.groupId),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return _buildMemberItem(member, viewModel);
        },
      ),
    );
  }

  Widget _buildMemberItem(GroupMember member, GroupViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: member.avatar != null
                  ? NetworkImage(member.avatar!)
                  : null,
              child: member.avatar == null
                  ? Text(
                      member.nickname.isNotEmpty ? member.nickname[0] : 'U',
                      style: const TextStyle(fontSize: 18),
                    )
                  : null,
            ),
            if (member.isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.nickname,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildRoleBadge(member.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.customData['title'] != null && member.customData['title'].toString().isNotEmpty)
              Text(
                member.customData['title'].toString(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            Row(
              children: [
                Text(
                  '加入时间: ${_formatDateTime(member.joinedAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (member.isMuted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '已禁言',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: widget.isManagementMode && member.role != GroupMemberRole.owner
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(value, member, viewModel),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('查看资料'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'message',
                    child: ListTile(
                      leading: Icon(Icons.message),
                      title: Text('发送消息'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'title',
                    child: ListTile(
                      leading: Icon(Icons.title),
                      title: Text('设置头衔'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: member.isMuted ? 'unmute' : 'mute',
                    child: ListTile(
                      leading: Icon(
                        member.isMuted ? Icons.volume_up : Icons.volume_off,
                        color: member.isMuted ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        member.isMuted ? '解除禁言' : '禁言',
                        style: TextStyle(
                          color: member.isMuted ? Colors.green : Colors.orange,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'role',
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings),
                      title: Text('设置角色'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'transfer',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Colors.blue),
                      title: Text('转让群主', style: TextStyle(color: Colors.blue)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.remove_circle, color: Colors.red),
                      title: Text('移除成员', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _showMemberDetail(member),
      ),
    );
  }

  Widget _buildRoleBadge(GroupMemberRole role) {
    Color color;
    String text;
    
    switch (role) {
      case GroupMemberRole.owner:
        color = Colors.red;
        text = '群主';
        break;
      case GroupMemberRole.admin:
        color = Colors.orange;
        text = '管理员';
        break;
      case GroupMemberRole.member:
        color = Colors.grey;
        text = '成员';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<GroupMember> _getFilteredMembers(List<GroupMember> members) {
    var filtered = members;

    // 按搜索关键词过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        return member.nickname.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (member.customData['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // 按角色过滤
    if (_selectedRole != null) {
      filtered = filtered.where((member) => member.role == _selectedRole).toList();
    }

    // 按在线状态过滤
    if (_showOnlineOnly) {
      filtered = filtered.where((member) => member.isActive).toList();
    }

    // 排序：群主 > 管理员 > 成员，同级别按加入时间排序
    filtered.sort((a, b) {
      // 首先按角色排序
      final roleOrder = {
        GroupMemberRole.owner: 0,
        GroupMemberRole.admin: 1,
        GroupMemberRole.member: 2,
      };
      
      final roleComparison = roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
      if (roleComparison != 0) return roleComparison;
      
      // 同级别按加入时间排序
      return a.joinedAt.compareTo(b.joinedAt);
    });

    return filtered;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        // 搜索功能已在界面中实现
        break;
      case 'filter':
        _showFilterDialog();
        break;
      case 'export':
        _exportMemberList();
        break;
    }
  }

  void _handleMemberAction(String action, GroupMember member, GroupViewModel viewModel) {
    switch (action) {
      case 'profile':
        _showMemberDetail(member);
        break;
      case 'message':
        // 跳转到私聊
        break;
      case 'title':
        _showSetTitleDialog(member, viewModel);
        break;
      case 'mute':
        _showMuteMemberDialog(member, viewModel);
        break;
      case 'unmute':
        viewModel.unmuteMember(member.groupId, member.userId);
        break;
      case 'role':
        _showSetRoleDialog(member, viewModel);
        break;
      case 'transfer':
        _showTransferOwnershipDialog(member, viewModel);
        break;
      case 'remove':
        _showRemoveMemberDialog(member, viewModel);
        break;
    }
  }

  void _showMemberDetail(GroupMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
                backgroundImage: member.avatar != null
                    ? NetworkImage(member.avatar!)
                    : null,
                child: member.avatar == null
                    ? Text(
                        member.nickname.isNotEmpty ? member.nickname[0] : 'U',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                member.nickname,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRoleBadge(member.role),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem('用户ID', member.userId),
                    _buildDetailItem('昵称', member.nickname),
                    if (member.customData['title'] != null && member.customData['title'].toString().isNotEmpty)
                      _buildDetailItem('群头衔', member.customData['title'].toString()),
                    _buildDetailItem('角色', _getRoleText(member.role)),
                    _buildDetailItem('在线状态', member.isActive ? '在线' : '离线'),
                    _buildDetailItem('禁言状态', member.isMuted ? '已禁言' : '正常'),
                    _buildDetailItem('加入时间', _formatDateTime(member.joinedAt)),
                  ],
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

  void _showInviteMemberDialog() {
    // 实现邀请成员对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请成员'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: '用户ID或昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 实现邀请逻辑
            },
            child: const Text('邀请'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 实现筛选选项
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSetTitleDialog(GroupMember member, GroupViewModel viewModel) {
    final controller = TextEditingController(text: member.customData['title']?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置群头衔'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '群头衔',
            border: OutlineInputBorder(),
            hintText: '为成员设置专属头衔',
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 实现设置头衔逻辑
              // viewModel.setMemberTitle(member.groupId, member.userId, controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showMuteMemberDialog(GroupMember member, GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('禁言成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要禁言成员"${member.nickname}"吗？'),
            const SizedBox(height: 16),
            // 可以添加禁言时长选择
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.muteMember(member.groupId, member.userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('禁言'),
          ),
        ],
      ),
    );
  }

  void _showSetRoleDialog(GroupMember member, GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置角色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GroupMemberRole.values
              .where((role) => role != GroupMemberRole.owner)
              .map((role) => RadioListTile<GroupMemberRole>(
                    title: Text(_getRoleText(role)),
                    value: role,
                    groupValue: member.role,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        viewModel.setMemberRole(member.groupId, member.userId, value);
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showTransferOwnershipDialog(GroupMember member, GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转让群主'),
        content: Text('确定要将群主转让给"${member.nickname}"吗？转让后您将成为普通成员。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.transferOwnership(member.groupId, member.userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('转让'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(GroupMember member, GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除成员'),
        content: Text('确定要移除成员"${member.nickname}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.removeMember(member.groupId, member.userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  void _exportMemberList() {
    // 实现导出成员列表功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中...')),
    );
  }

  String _getRoleText(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.owner:
        return '群主';
      case GroupMemberRole.admin:
        return '管理员';
      case GroupMemberRole.member:
        return '成员';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}