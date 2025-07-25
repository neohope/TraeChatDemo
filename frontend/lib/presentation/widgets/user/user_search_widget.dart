import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_model.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/friend_viewmodel.dart';
import 'user_list_widget.dart';
import 'user_detail_widget.dart';

/// 用户搜索组件
class UserSearchWidget extends StatefulWidget {
  final Function(UserModel)? onUserSelected;
  final bool showAddFriendButton;
  final bool allowMultiSelect;
  final List<String>? excludeUserIds;

  const UserSearchWidget({
    Key? key,
    this.onUserSelected,
    this.showAddFriendButton = true,
    this.allowMultiSelect = false,
    this.excludeUserIds,
  }) : super(key: key);

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;
  List<UserModel> _searchResults = [];
  List<UserModel> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendedUsers();
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
        title: const Text('发现用户'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '搜索', icon: Icon(Icons.search)),
            Tab(text: '推荐', icon: Icon(Icons.recommend)),
            Tab(text: '附近', icon: Icon(Icons.location_on)),
          ],
        ),
        actions: [
          if (widget.allowMultiSelect && _selectedUsers.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text('确定(${_selectedUsers.length})'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildRecommendedTab(),
          _buildNearbyTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _isSearching
              ? _buildSearchResults()
              : _buildSearchSuggestions(),
        ),
      ],
    );
  }

  Widget _buildRecommendedTab() {
    return Consumer<UserViewModel>(builder: (context, userViewModel, child) {
      final recommendedUsers = userViewModel.recommendedUsers
          .where((user) => !_isUserExcluded(user.id))
          .toList();

      if (recommendedUsers.isEmpty) {
        return _buildEmptyState(
          icon: Icons.recommend,
          title: '暂无推荐用户',
          subtitle: '系统会根据您的兴趣推荐合适的用户',
          action: ElevatedButton(
            onPressed: _loadRecommendedUsers,
            child: const Text('刷新推荐'),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadRecommendedUsers,
        child: UserListWidget(
          users: recommendedUsers,
          onUserTap: _onUserTap,
          onUserLongPress: _onUserLongPress,
          showAddFriendButton: widget.showAddFriendButton,
          showSearchBar: false,
          emptyMessage: '暂无推荐用户',
        ),
      );
    });
  }

  Widget _buildNearbyTab() {
    return Consumer<UserViewModel>(builder: (context, userViewModel, child) {
      final nearbyUsers = userViewModel.nearbyUsers
          .where((user) => !_isUserExcluded(user.id))
          .toList();

      if (nearbyUsers.isEmpty) {
        return _buildEmptyState(
          icon: Icons.location_off,
          title: '附近暂无用户',
          subtitle: '开启位置权限以发现附近的用户',
          action: ElevatedButton(
            onPressed: _loadNearbyUsers,
            child: const Text('刷新附近'),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadNearbyUsers,
        child: UserListWidget(
          users: nearbyUsers,
          onUserTap: _onUserTap,
          onUserLongPress: _onUserLongPress,
          showAddFriendButton: widget.showAddFriendButton,
          showSearchBar: false,
          emptyMessage: '附近暂无用户',
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索用户名、昵称或邮箱',
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
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: '未找到相关用户',
        subtitle: '尝试使用其他关键词搜索',
      );
    }

    return UserSearchResultWidget(
      searchResults: _searchResults,
      searchQuery: _searchQuery,
      onUserTap: _onUserTap,
      onClearSearch: _clearSearch,
      showAddFriendButton: widget.showAddFriendButton,
    );
  }

  Widget _buildSearchSuggestions() {
    return Consumer2<UserViewModel, FriendViewModel>(
      builder: (context, userViewModel, friendViewModel, child) {
        final recentSearches = userViewModel.recentSearches
            .where((user) => !_isUserExcluded(user.id))
            .toList();
        // 添加热门用户属性到UserViewModel
        // 暂时使用模拟数据
        // final popularUsers = <UserModel>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recentSearches.isNotEmpty) ...[
                _buildSectionHeader(
                   '最近搜索',
                   onClear: () {
                     // 添加清除最近搜索方法到UserViewModel
                     print('清除最近搜索记录');
                     // userViewModel.clearRecentSearches();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('清除最近搜索功能待实现')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildHorizontalUserList(recentSearches),
                const SizedBox(height: 24),
              ],
              // 添加热门用户属性到UserViewModel
              // if (popularUsers.isNotEmpty) ...[
                // _buildSectionHeader('热门用户'),
                // const SizedBox(height: 8),
                // _buildHorizontalUserList(popularUsers),
                // const SizedBox(height: 24),
              // ],
              _buildSearchTips(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onClear}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: const Text('清除'),
          ),
      ],
    );
  }

  Widget _buildHorizontalUserList(List<UserModel> users) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isSelected = _selectedUsers.contains(user);
          
          return GestureDetector(
            onTap: () => _onUserTap(user),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
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
                      if (widget.allowMultiSelect && isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      if (user.isOnline)
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.nickname ?? user.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '搜索技巧',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• 输入用户名、昵称或邮箱进行搜索\n'
              '• 使用 @ 符号搜索用户名\n'
              '• 支持模糊搜索和拼音搜索\n'
              '• 长按用户头像查看更多操作',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
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

  bool _isUserExcluded(String? userId) {
    if (userId == null) return false;
    return widget.excludeUserIds?.contains(userId) ?? false;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.length >= 2) {
      _performSearch(query);
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      await userViewModel.searchUsers(query.trim());
      
      setState(() {
        _searchResults = userViewModel.searchResults
            .where((user) => !_isUserExcluded(user.id))
            .toList();
        _isLoading = false;
      });

      // 添加到最近搜索
      if (_searchResults.isNotEmpty) {
        userViewModel.addToRecentSearches(_searchResults.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchResults.clear();
    });
  }

  void _onUserTap(UserModel user) {
    if (widget.allowMultiSelect) {
      setState(() {
        if (_selectedUsers.contains(user)) {
          _selectedUsers.remove(user);
        } else {
          _selectedUsers.add(user);
        }
      });
    } else {
      widget.onUserSelected?.call(user);
      _navigateToUserDetail(user);
    }
  }

  void _onUserLongPress(UserModel user) {
    _showUserActionMenu(user);
  }

  void _navigateToUserDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailWidget(
          userId: user.id,
          showEditButton: false,
        ),
      ),
    );
  }

  void _showUserActionMenu(UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => UserActionMenuWidget(
        user: user,
        onSendMessage: (user) {
          Navigator.pop(context);
          widget.onUserSelected?.call(user);
        },
        onAddFriend: (user) {
          Navigator.pop(context);
        },
        onViewProfile: _navigateToUserDetail,
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedUsers.isNotEmpty) {
      Navigator.pop(context, _selectedUsers);
    }
  }

  Future<void> _loadRecommendedUsers() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      await userViewModel.loadRecommendedUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载推荐用户失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadNearbyUsers() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      await userViewModel.loadNearbyUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载附近用户失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}