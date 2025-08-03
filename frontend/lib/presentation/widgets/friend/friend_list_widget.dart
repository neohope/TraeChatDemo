import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../domain/models/user_model.dart';
import '../../../domain/models/friend_request_model.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/user_search_viewmodel.dart' as presentation;
import '../../viewmodels/chat_viewmodel.dart';
import '../../../core/utils/app_date_utils.dart';
import '../user/user_detail_widget.dart';
import '../user/user_search_widget.dart';

/// 好友列表组件
class FriendListWidget extends StatefulWidget {
  final Function(UserModel)? onFriendTap;
  final Function(UserModel)? onFriendLongPress;
  final bool showOnlineStatus;
  final bool showSearchBar;
  final String? emptyMessage;

  const FriendListWidget({
    Key? key,
    this.onFriendTap,
    this.onFriendLongPress,
    this.showOnlineStatus = true,
    this.showSearchBar = true,
    this.emptyMessage,
  }) : super(key: key);

  @override
  State<FriendListWidget> createState() => _FriendListWidgetState();
}

class _FriendListWidgetState extends State<FriendListWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 延迟到build完成后再加载数据，避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriends();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<FriendViewModel>(builder: (context, friendViewModel, child) {
              final pendingCount = friendViewModel.pendingFriendRequests.length;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('好友'),
                    if (pendingCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pendingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const Tab(text: '请求'),
            const Tab(text: '黑名单'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToUserSearch,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildBlockedTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        if (widget.showSearchBar) _buildSearchBar(),
        Expanded(
          child: Consumer2<FriendViewModel, presentation.UserSearchViewModel>(
            builder: (context, friendViewModel, userViewModel, child) {
              final friends = _getFilteredFriends(
                friendViewModel.friends,
                friendViewModel,
              );

              if (friends.isEmpty) {
                return _buildEmptyState(
                  icon: _isSearching ? Icons.search_off : Icons.people_outline,
                  title: _isSearching ? '未找到相关好友' : '暂无好友',
                  subtitle: _isSearching
                      ? '尝试使用其他关键词搜索'
                      : '点击右上角添加好友',
                  action: !_isSearching
                      ? ElevatedButton.icon(
                          onPressed: _navigateToUserSearch,
                          icon: const Icon(Icons.person_add),
                          label: const Text('添加好友'),
                        )
                      : null,
                );
              }

              return RefreshIndicator(
                onRefresh: _loadFriends,
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final user = friends[index];

                    return FriendListItemWidget(
                      user: user,
                      onTap: () => widget.onFriendTap?.call(user),
                      onLongPress: () => widget.onFriendLongPress?.call(user),
                      showOnlineStatus: widget.showOnlineStatus,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return Consumer2<FriendViewModel, presentation.UserSearchViewModel>(
      builder: (context, friendViewModel, userViewModel, child) {
        final pendingRequests = friendViewModel.pendingFriendRequests;
        final sentRequests = friendViewModel.sentFriendRequests;

        if (pendingRequests.isEmpty && sentRequests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_disabled,
            title: '暂无好友请求',
            subtitle: '收到的好友请求会显示在这里',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pendingRequests.isNotEmpty) ...[
                _buildSectionHeader('收到的请求 (${pendingRequests.length})'),
                const SizedBox(height: 8),
                ...pendingRequests.map((request) {
                  final user = userViewModel.getUserById(request.senderId);
                  if (user == null) return const SizedBox.shrink();
                  
                  return FriendRequestItemWidget(
                    request: request,
                    user: user,
                    isReceived: true,
                    onAccept: () => _acceptFriendRequest(request),
                    onReject: () => _rejectFriendRequest(request),
                    onCancel: null,
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],
              if (sentRequests.isNotEmpty) ...[
                _buildSectionHeader('发出的请求 (${sentRequests.length})'),
                const SizedBox(height: 8),
                ...sentRequests.map((request) {
                  final user = userViewModel.getUserById(request.receiverId);
                  if (user == null) return const SizedBox.shrink();
                  
                  return FriendRequestItemWidget(
                    request: request,
                    user: user,
                    isReceived: false,
                    onAccept: null,
                    onReject: null,
                    onCancel: () => _cancelFriendRequest(request),
                  );
                }).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedTab() {
    return Consumer2<FriendViewModel, presentation.UserSearchViewModel>(
      builder: (context, friendViewModel, userViewModel, child) {
        final blockedUsers = friendViewModel.blockedUsers;

        if (blockedUsers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.block,
            title: '暂无黑名单用户',
            subtitle: '被屏蔽的用户会显示在这里',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: blockedUsers.length,
          itemBuilder: (context, index) {
            final user = blockedUsers[index];
            return BlockedUserItemWidget(
              user: user,
              onUnblock: () => _unblockUser(user),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索好友',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                fontWeight: FontWeight.w600,
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
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  List<UserModel> _getFilteredFriends(
    List<UserModel> friends,
    FriendViewModel friendViewModel,
  ) {
    if (_searchQuery.isEmpty) {
      return friends;
    }

    return friends.where((user) {
      final query = _searchQuery.toLowerCase();
      final remark = friendViewModel.getFriendRemark(user.id);
      return (user.nickname?.toLowerCase().contains(query) ?? false) ||
             user.name.toLowerCase().contains(query) ||
             (remark?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _navigateToUserSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserSearchWidget(),
      ),
    );
  }

  Future<void> _loadFriends() async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.loadFriends();
      await friendViewModel.loadFriendRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载好友列表失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.acceptFriendRequest(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已接受好友请求'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('接受好友请求失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectFriendRequest(FriendRequest request) async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.rejectFriendRequest(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已拒绝好友请求'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拒绝好友请求失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelFriendRequest(FriendRequest request) async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.cancelFriendRequest(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已取消好友请求'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取消好友请求失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(UserModel user) async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.unblockUser(user.id);
      
      if (mounted) {
        final displayName = user.nickname ?? user.name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已解除对 $displayName 的屏蔽'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解除屏蔽失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 好友列表项组件
class FriendListItemWidget extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showOnlineStatus;

  const FriendListItemWidget({
    Key? key,
    required this.user,
    this.onTap,
    this.onLongPress,
    this.showOnlineStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<FriendViewModel>(
                          builder: (context, friendViewModel, child) {
                            final remark = friendViewModel.getFriendRemark(user.id);
                            return Text(
                              remark ?? user.nickname ?? user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      // Removed isVerified check as it's not available in UserModel
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.isOnline
                        ? '在线'
                        : (user.lastSeenAt != null
                            ? '最后在线 ${AppDateUtils.formatLastSeen(user.lastSeenAt!)}'
                            : '离线'),
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isOnline ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Consumer<FriendViewModel>(
                  builder: (context, friendViewModel, child) {
                    final remark = friendViewModel.getFriendRemark(user.id);
                    final displayName = remark ?? user.nickname ?? user.name;
                    return Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                )
              : null,
        ),
        if (showOnlineStatus && user.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
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
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.message, size: 20),
          onPressed: () => _sendMessage(context),
          tooltip: '发送消息',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) => _handleMenuAction(context, value),
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
              value: 'remark',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('设置备注'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.person_remove, color: Colors.red),
                title: Text('删除好友', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage(BuildContext context) async {
    try {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.createConversation(participantId: user.id);
      // 导航到聊天界面
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建聊天失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailWidget(
              userId: user.id,
              showEditButton: false,
            ),
          ),
        );
        break;
      case 'remark':
        _showRemarkDialog(context);
        break;
      case 'remove':
        _showRemoveFriendDialog(context);
        break;
    }
  }

  void _showRemarkDialog(BuildContext context) {
    final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
    final currentRemark = friendViewModel.getFriendRemark(user.id);
    final controller = TextEditingController(text: currentRemark ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置备注'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注名称',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await friendViewModel.updateFriendRemark(
                  user.id,
                  controller.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('备注设置成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('设置备注失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendDialog(BuildContext context) {
    final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
    final remark = friendViewModel.getFriendRemark(user.id);
    final displayName = remark ?? user.nickname ?? user.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友 $displayName 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final friendViewModel = Provider.of<FriendViewModel>(
                  context,
                  listen: false,
                );
                await friendViewModel.removeFriend(user.id);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除好友 $displayName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除好友失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 好友请求项组件
class FriendRequestItemWidget extends StatelessWidget {
  final FriendRequest request;
  final UserModel user;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const FriendRequestItemWidget({
    Key? key,
    required this.request,
    required this.user,
    required this.isReceived,
    this.onAccept,
    this.onReject,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      (user.nickname ?? user.name).substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname ?? user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (request.message != null && request.message!.isNotEmpty)
                    Text(
                      request.message!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.getRelativeTime(request.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (isReceived) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onReject,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('拒绝'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAccept,
            child: const Text('接受'),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: onCancel,
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
        ),
        child: const Text('取消'),
      );
    }
  }
}

/// 黑名单用户项组件
class BlockedUserItemWidget extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onUnblock;

  const BlockedUserItemWidget({
    Key? key,
    required this.user,
    this.onUnblock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      (user.nickname ?? user.name).substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname ?? user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                      '@${user.name}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onUnblock,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
              child: const Text('解除屏蔽'),
            ),
          ],
        ),
      ),
    );
  }
}