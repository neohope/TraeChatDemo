import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_model.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../../core/utils/app_date_utils.dart';

/// 用户列表组件
class UserListWidget extends StatefulWidget {
  final List<UserModel> users;
  final Function(UserModel)? onUserTap;
  final Function(UserModel)? onUserLongPress;
  final bool showOnlineStatus;
  final bool showAddFriendButton;
  final bool showSearchBar;
  final String? emptyMessage;
  final ScrollController? scrollController;

  const UserListWidget({
    Key? key,
    required this.users,
    this.onUserTap,
    this.onUserLongPress,
    this.showOnlineStatus = true,
    this.showAddFriendButton = false,
    this.showSearchBar = true,
    this.emptyMessage,
    this.scrollController,
  }) : super(key: key);

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearchBar) _buildSearchBar(),
        Expanded(
          child: _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索用户',
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

  Widget _buildUserList() {
    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching
                  ? '未找到相关用户'
                  : widget.emptyMessage ?? '暂无用户',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return UserListItemWidget(
          user: user,
          onTap: () => widget.onUserTap?.call(user),
          onLongPress: () => widget.onUserLongPress?.call(user),
          showOnlineStatus: widget.showOnlineStatus,
          showAddFriendButton: widget.showAddFriendButton,
        );
      },
    );
  }

  List<UserModel> _getFilteredUsers() {
    if (_searchQuery.isEmpty) {
      return widget.users;
    }

    return widget.users.where((user) {
      final query = _searchQuery.toLowerCase();
      return (user.nickname?.toLowerCase().contains(query) ?? false) ||
             user.name.toLowerCase().contains(query) ||
             (user.email?.toLowerCase().contains(query) ?? false);
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
}

/// 用户列表项组件
class UserListItemWidget extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showOnlineStatus;
  final bool showAddFriendButton;
  final bool showLastSeen;

  const UserListItemWidget({
    Key? key,
    required this.user,
    this.onTap,
    this.onLongPress,
    this.showOnlineStatus = true,
    this.showAddFriendButton = false,
    this.showLastSeen = true,
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
                        child: Text(
                          user.nickname ?? user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // TODO: Add isVerified property to UserModel
                      // if (user.isVerified)
                      //   Container(
                      //     margin: const EdgeInsets.only(left: 4),
                      //     child: Icon(
                      //       Icons.verified,
                      //       size: 16,
                      //       color: Theme.of(context).primaryColor,
                      //     ),
                      //   ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.name}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (showLastSeen && !user.isOnline && user.lastSeenAt != null)
                    Text(
                      '最后在线 ${AppDateUtils.formatLastSeen(user.lastSeenAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (showAddFriendButton)
              _buildAddFriendButton(context)
            else
              _buildStatusIndicator(),
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
              ? Text(
                  (user.nickname ?? user.name).substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildAddFriendButton(BuildContext context) {
    return Consumer<FriendViewModel>(builder: (context, friendViewModel, child) {
      final isFriend = friendViewModel.isFriend(user.id);
      final hasPendingRequest = friendViewModel.hasPendingFriendRequest(user.id);
      
      if (isFriend) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: 14,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                '已添加',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
      
      if (hasPendingRequest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '待确认',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      
      return ElevatedButton(
        onPressed: () => _sendFriendRequest(context, friendViewModel),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          '添加',
          style: TextStyle(fontSize: 12),
        ),
      );
    });
  }

  Widget _buildStatusIndicator() {
    if (!showOnlineStatus) return const SizedBox.shrink();
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: user.isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  void _sendFriendRequest(BuildContext context, FriendViewModel friendViewModel) async {
    try {
      await friendViewModel.sendFriendRequest(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已向 ${user.nickname} 发送好友请求'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送好友请求失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 用户搜索结果组件
class UserSearchResultWidget extends StatelessWidget {
  final List<UserModel> searchResults;
  final String searchQuery;
  final Function(UserModel)? onUserTap;
  final VoidCallback? onClearSearch;
  final bool showAddFriendButton;

  const UserSearchResultWidget({
    Key? key,
    required this.searchResults,
    required this.searchQuery,
    this.onUserTap,
    this.onClearSearch,
    this.showAddFriendButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '搜索 "$searchQuery" 的结果 (${searchResults.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearSearch,
                child: const Text('清除'),
              ),
            ],
          ),
        ),
        Expanded(
          child: searchResults.isEmpty
              ? const Center(
                  child: Text(
                    '未找到相关用户',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final user = searchResults[index];
                    return UserListItemWidget(
                      user: user,
                      onTap: () => onUserTap?.call(user),
                      showOnlineStatus: true,
                      showAddFriendButton: showAddFriendButton,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// 在线用户列表组件
class OnlineUserListWidget extends StatelessWidget {
  final List<UserModel> onlineUsers;
  final Function(UserModel)? onUserTap;
  final ScrollController? scrollController;

  const OnlineUserListWidget({
    Key? key,
    required this.onlineUsers,
    this.onUserTap,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onlineUsers.isEmpty) {
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
              '暂无在线用户',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '在线用户 (${onlineUsers.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: onlineUsers.length,
            itemBuilder: (context, index) {
              final user = onlineUsers[index];
              return UserListItemWidget(
                user: user,
                onTap: () => onUserTap?.call(user),
                showOnlineStatus: true,
                showLastSeen: false,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 用户操作菜单组件
class UserActionMenuWidget extends StatelessWidget {
  final UserModel user;
  final Function(UserModel)? onSendMessage;
  final Function(UserModel)? onAddFriend;
  final Function(UserModel)? onRemoveFriend;
  final Function(UserModel)? onBlock;
  final Function(UserModel)? onReport;
  final Function(UserModel)? onViewProfile;

  const UserActionMenuWidget({
    Key? key,
    required this.user,
    this.onSendMessage,
    this.onAddFriend,
    this.onRemoveFriend,
    this.onBlock,
    this.onReport,
    this.onViewProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('查看资料'),
            onTap: () {
              Navigator.pop(context);
              onViewProfile?.call(user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('发送消息'),
            onTap: () {
              Navigator.pop(context);
              onSendMessage?.call(user);
            },
          ),
          Consumer<FriendViewModel>(builder: (context, friendViewModel, child) {
            final isFriend = friendViewModel.isFriend(user.id);
            
            if (isFriend) {
              return ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.orange),
                title: const Text('删除好友', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  onRemoveFriend?.call(user);
                },
              );
            } else {
              return ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('添加好友'),
                onTap: () {
                  Navigator.pop(context);
                  onAddFriend?.call(user);
                },
              );
            }
          }),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('屏蔽用户', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onBlock?.call(user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text('举报用户', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onReport?.call(user);
            },
          ),
        ],
      ),
    );
  }
}