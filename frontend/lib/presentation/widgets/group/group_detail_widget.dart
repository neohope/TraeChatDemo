import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/group_model.dart';
import '../../viewmodels/group_viewmodel.dart';

/// 群组详情组件
class GroupDetailWidget extends StatefulWidget {
  final String groupId;

  const GroupDetailWidget({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDetailWidget> createState() => _GroupDetailWidgetState();
}

class _GroupDetailWidgetState extends State<GroupDetailWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().selectGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupViewModel>(builder: (context, viewModel, child) {
      final group = viewModel.currentGroup;
      
      if (viewModel.isLoading && group == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (group == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('群组详情')),
          body: const Center(
            child: Text('群组不存在或已被删除'),
          ),
        );
      }

      return Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(group, viewModel),
          ],
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(group, viewModel),
                    _buildMembersTab(viewModel),
                    _buildSettingsTab(group, viewModel),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(group, viewModel),
      );
    });
  }

  Widget _buildSliverAppBar(Group group, GroupViewModel viewModel) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          group.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getGroupTypeColor(group.type),
                _getGroupTypeColor(group.type).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              if (group.avatar != null)
                Positioned.fill(
                  child: Image.network(
                    group.avatar!,
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getGroupTypeIcon(group.type),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getGroupTypeText(group.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getGroupStatusColor(group.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getGroupStatusText(group.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount}人',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleAction(value, group, viewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑信息'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'invite',
              child: ListTile(
                leading: Icon(Icons.person_add),
                title: Text('邀请成员'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.orange),
                title: Text('退出群组', style: TextStyle(color: Colors.orange)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (group.ownerId == 'current_user_id') // 需要从用户服务获取当前用户ID
              const PopupMenuItem(
                value: 'dissolve',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('解散群组', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '信息', icon: Icon(Icons.info_outline)),
          Tab(text: '成员', icon: Icon(Icons.people_outline)),
          Tab(text: '设置', icon: Icon(Icons.settings_outlined)),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Group group, GroupViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: '基本信息',
            children: [
              _buildInfoRow('群组名称', group.name),
              if (group.description != null && group.description!.isNotEmpty)
                _buildInfoRow('群组描述', group.description!),
              _buildInfoRow('群组类型', _getGroupTypeText(group.type)),
              _buildInfoRow('群组状态', _getGroupStatusText(group.status)),
              _buildInfoRow('成员数量', '${group.memberCount}人'),
              _buildInfoRow('创建时间', _formatDateTime(group.createdAt)),
              _buildInfoRow('更新时间', _formatDateTime(group.updatedAt)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: '群组设置',
            children: [
              _buildInfoRow(
                '允许成员邀请',
                group.settings.allowMemberInvite ? '是' : '否',
              ),
              _buildInfoRow(
                '允许成员修改信息',
                group.settings.allowMemberModifyInfo ? '是' : '否',
              ),
              _buildInfoRow(
                '全员禁言',
                group.settings.muteAll ? '是' : '否',
              ),
              _buildInfoRow(
                '加群需要审批',
                group.settings.requireApprovalToJoin ? '是' : '否',
              ),
              _buildInfoRow(
                '允许搜索',
                group.settings.allowSearchByGroupId ? '是' : '否',
              ),
              _buildInfoRow(
                '最大成员数',
                '${group.settings.maxMembers}人',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(GroupViewModel viewModel) {
    final members = viewModel.currentMembers;
    
    if (viewModel.isLoading && members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无成员',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // 按角色分组
    final owners = members.where((m) => m.role == GroupMemberRole.owner).toList();
    final admins = members.where((m) => m.role == GroupMemberRole.admin).toList();
    final normalMembers = members.where((m) => m.role == GroupMemberRole.member).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (owners.isNotEmpty) _buildMemberSection('群主', owners),
        if (owners.isNotEmpty) const SizedBox(height: 16),
        if (admins.isNotEmpty) _buildMemberSection('管理员', admins),
        if (admins.isNotEmpty) const SizedBox(height: 16),
        if (normalMembers.isNotEmpty)
          _buildMemberSection('成员', normalMembers),
      ],
    );
  }

  Widget _buildSettingsTab(Group group, GroupViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsCard(
          title: '成员管理',
          children: [
            SwitchListTile(
              title: const Text('允许成员邀请'),
              subtitle: const Text('允许普通成员邀请其他用户加入群组'),
              value: group.settings.allowMemberInvite,
              onChanged: (value) => _updateGroupSettings(
                group,
                viewModel,
                group.settings.copyWith(allowMemberInvite: value),
              ),
            ),
            SwitchListTile(
              title: const Text('允许成员修改信息'),
              subtitle: const Text('允许普通成员修改群组名称和描述'),
              value: group.settings.allowMemberModifyInfo,
              onChanged: (value) => _updateGroupSettings(
                group,
                viewModel,
                group.settings.copyWith(allowMemberModifyInfo: value),
              ),
            ),
            SwitchListTile(
              title: const Text('加群需要审批'),
              subtitle: const Text('新成员加入需要管理员审批'),
              value: group.settings.requireApprovalToJoin,
              onChanged: (value) => _updateGroupSettings(
                group,
                viewModel,
                group.settings.copyWith(requireApprovalToJoin: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '消息管理',
          children: [
            SwitchListTile(
              title: const Text('全员禁言'),
              subtitle: const Text('禁止所有成员发送消息'),
              value: group.settings.muteAll,
              onChanged: (value) => _updateGroupSettings(
                group,
                viewModel,
                group.settings.copyWith(muteAll: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '隐私设置',
          children: [
            SwitchListTile(
              title: const Text('允许搜索'),
              subtitle: const Text('允许其他用户通过群号搜索到此群组'),
              value: group.settings.allowSearchByGroupId,
              onChanged: (value) => _updateGroupSettings(
                group,
                viewModel,
                group.settings.copyWith(allowSearchByGroupId: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '群组限制',
          children: [
            ListTile(
              title: const Text('最大成员数'),
              subtitle: Text('当前设置: ${group.settings.maxMembers}人'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMaxMembersDialog(group, viewModel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(Group group, GroupViewModel viewModel) {
    return FloatingActionButton(
      onPressed: () => _showInviteMemberDialog(group, viewModel),
      child: const Icon(Icons.person_add),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildMemberSection(String title, List<GroupMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${members.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...members.map((member) => _buildMemberItem(member)),
      ],
    );
  }

  Widget _buildMemberItem(GroupMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.avatar != null
              ? NetworkImage(member.avatar!)
              : null,
          child: member.avatar == null
              ? Text(member.nickname.isNotEmpty ? member.nickname[0] : 'U')
              : null,
        ),
        title: Text(member.nickname),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getMemberRoleText(member.role)),
            if (member.isMuted)
              Text(
                '已禁言',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMemberAction(value, member),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('查看资料'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (member.role != GroupMemberRole.owner) PopupMenuItem(
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
            if (member.role != GroupMemberRole.owner) const PopupMenuItem(
              value: 'role',
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings),
                title: Text('设置角色'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (member.role != GroupMemberRole.owner) const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text('移除成员', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _handleAction(String action, Group group, GroupViewModel viewModel) {
    switch (action) {
      case 'edit':
        _showEditGroupDialog(group, viewModel);
        break;
      case 'invite':
        _showInviteMemberDialog(group, viewModel);
        break;
      case 'leave':
        _showLeaveGroupDialog(group, viewModel);
        break;
      case 'dissolve':
        _showDissolveGroupDialog(group, viewModel);
        break;
    }
  }

  void _handleMemberAction(String action, GroupMember member) {
    final viewModel = context.read<GroupViewModel>();
    
    switch (action) {
      case 'profile':
        // 显示用户资料
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
      case 'remove':
        _showRemoveMemberDialog(member, viewModel);
        break;
    }
  }

  void _updateGroupSettings(Group group, GroupViewModel viewModel, GroupSettings newSettings) {
    viewModel.updateGroup(group.id, settings: newSettings);
  }

  // 对话框方法
  void _showEditGroupDialog(Group group, GroupViewModel viewModel) {
    // 实现编辑群组对话框
  }

  void _showInviteMemberDialog(Group group, GroupViewModel viewModel) {
    // 实现邀请成员对话框
  }

  void _showLeaveGroupDialog(Group group, GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出群组'),
        content: Text('确定要退出群组"${group.displayName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.leaveGroup(group.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已退出群组')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showDissolveGroupDialog(Group group, GroupViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解散群组'),
        content: Text('确定要解散群组"${group.displayName}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.dissolveGroup(group.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('群组已解散')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('解散'),
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
                    title: Text(_getMemberRoleText(role)),
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

  void _showMaxMembersDialog(Group group, GroupViewModel viewModel) {
    final controller = TextEditingController(
      text: group.settings.maxMembers.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置最大成员数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '最大成员数',
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
              final maxMembers = int.tryParse(controller.text);
              if (maxMembers != null && maxMembers > 0) {
                Navigator.pop(context);
                viewModel.updateGroup(
                  group.id,
                  settings: group.settings.copyWith(maxMembers: maxMembers),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 辅助方法
  String _getGroupTypeText(GroupType type) {
    switch (type) {
      case GroupType.normal:
        return '普通群组';
      case GroupType.broadcast:
        return '广播群组';
      case GroupType.channel:
        return '频道';
    }
  }

  String _getGroupStatusText(GroupStatus status) {
    switch (status) {
      case GroupStatus.active:
        return '活跃';
      case GroupStatus.archived:
        return '已归档';
      case GroupStatus.dissolved:
        return '已解散';
    }
  }

  String _getMemberRoleText(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.owner:
        return '群主';
      case GroupMemberRole.admin:
        return '管理员';
      case GroupMemberRole.member:
        return '成员';
    }
  }

  Color _getGroupTypeColor(GroupType type) {
    switch (type) {
      case GroupType.normal:
        return Colors.blue;
      case GroupType.broadcast:
        return Colors.green;
      case GroupType.channel:
        return Colors.purple;
    }
  }

  Color _getGroupStatusColor(GroupStatus status) {
    switch (status) {
      case GroupStatus.active:
        return Colors.green;
      case GroupStatus.archived:
        return Colors.orange;
      case GroupStatus.dissolved:
        return Colors.red;
    }
  }

  IconData _getGroupTypeIcon(GroupType type) {
    switch (type) {
      case GroupType.normal:
        return Icons.group;
      case GroupType.broadcast:
        return Icons.campaign;
      case GroupType.channel:
        return Icons.tv;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}