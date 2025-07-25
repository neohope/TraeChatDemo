import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/group_model.dart';
import '../../viewmodels/group_viewmodel.dart';

/// 群组列表组件
class GroupListWidget extends StatefulWidget {
  final Function(Group)? onGroupTap;
  final bool showCreateButton;
  final EdgeInsets? padding;

  const GroupListWidget({
    Key? key,
    this.onGroupTap,
    this.showCreateButton = true,
    this.padding,
  }) : super(key: key);

  @override
  State<GroupListWidget> createState() => _GroupListWidgetState();
}

class _GroupListWidgetState extends State<GroupListWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<GroupViewModel>().loadMoreGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupViewModel>(builder: (context, viewModel, child) {
      return Column(
        children: [
          // 搜索栏
          _buildSearchBar(viewModel),
          
          // 过滤器
          _buildFilters(viewModel),
          
          // 群组列表
          Expanded(
            child: _buildGroupList(viewModel),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar(GroupViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索群组...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                viewModel.setSearchQuery(value);
                if (value.isNotEmpty) {
                  // 延迟搜索
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      viewModel.searchGroups(value);
                    }
                  });
                }
              },
            ),
          ),
          if (widget.showCreateButton) const SizedBox(width: 8),
          if (widget.showCreateButton) FloatingActionButton(
            mini: true,
            onPressed: () => _showCreateGroupDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(GroupViewModel viewModel) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 类型过滤
          Expanded(
            child: DropdownButtonFormField<GroupType?>(
              value: viewModel.filterType,
              decoration: const InputDecoration(
                labelText: '类型',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ...GroupType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getGroupTypeText(type)),
                    )),
              ],
              onChanged: (value) => viewModel.setFilterType(value),
            ),
          ),
          const SizedBox(width: 8),
          
          // 状态过滤
          Expanded(
            child: DropdownButtonFormField<GroupStatus?>(
              value: viewModel.filterStatus,
              decoration: const InputDecoration(
                labelText: '状态',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ...GroupStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_getGroupStatusText(status)),
                    )),
              ],
              onChanged: (value) => viewModel.setFilterStatus(value),
            ),
          ),
          const SizedBox(width: 8),
          
          // 清除过滤
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => viewModel.clearFilters(),
            tooltip: '清除过滤',
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(GroupViewModel viewModel) {
    if (viewModel.isLoading && viewModel.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.refreshGroups(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final groups = viewModel.filteredGroups;
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无群组',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (widget.showCreateButton) const SizedBox(height: 16),
            if (widget.showCreateButton) ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('创建群组'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshGroups(),
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding ?? const EdgeInsets.all(16),
        itemCount: groups.length + (viewModel.hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= groups.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final group = groups[index];
          return _buildGroupItem(group);
        },
      ),
    );
  }

  Widget _buildGroupItem(Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getGroupTypeColor(group.type),
          backgroundImage: group.avatar != null
              ? NetworkImage(group.avatar!)
              : null,
          child: group.avatar == null
              ? Icon(
                  _getGroupTypeIcon(group.type),
                  color: Colors.white,
                )
              : null,
        ),
        title: Text(
          group.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null && group.description!.isNotEmpty)
              Text(
                group.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${group.memberCount}人',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getGroupStatusColor(group.status),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getGroupStatusText(group.status),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleGroupAction(value, group),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('查看详情'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑信息'),
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
        onTap: () {
          if (widget.onGroupTap != null) {
            widget.onGroupTap!(group);
          } else {
            _handleGroupAction('view', group);
          }
        },
      ),
    );
  }

  void _handleGroupAction(String action, Group group) {
    final viewModel = context.read<GroupViewModel>();
    
    switch (action) {
      case 'view':
        viewModel.selectGroup(group.id);
        Navigator.pushNamed(context, '/group-detail', arguments: group.id);
        break;
      case 'edit':
        _showEditGroupDialog(context, group);
        break;
      case 'leave':
        _showLeaveGroupDialog(context, group);
        break;
      case 'dissolve':
        _showDissolveGroupDialog(context, group);
        break;
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }

  void _showEditGroupDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => EditGroupDialog(group: group),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, Group group) {
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
              final success = await context.read<GroupViewModel>().leaveGroup(group.id);
              if (success && mounted) {
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

  void _showDissolveGroupDialog(BuildContext context, Group group) {
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
              final success = await context.read<GroupViewModel>().dissolveGroup(group.id);
              if (success && mounted) {
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
}

/// 创建群组对话框
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({Key? key}) : super(key: key);

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  GroupType _selectedType = GroupType.normal;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建群组'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '群组名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入群组名称';
                }
                if (value.trim().length < 2) {
                  return '群组名称至少2个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '群组描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GroupType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '群组类型',
                border: OutlineInputBorder(),
              ),
              items: GroupType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(_getGroupTypeText(type)),
                  )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createGroup,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final group = await context.read<GroupViewModel>().createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            type: _selectedType,
          );

      if (group != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('群组"${group.name}"创建成功')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
}

/// 编辑群组对话框
class EditGroupDialog extends StatefulWidget {
  final Group group;

  const EditGroupDialog({Key? key, required this.group}) : super(key: key);

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑群组信息'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '群组名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入群组名称';
                }
                if (value.trim().length < 2) {
                  return '群组名称至少2个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '群组描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateGroup,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<GroupViewModel>().updateGroup(
            widget.group.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
          );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群组信息更新成功')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}