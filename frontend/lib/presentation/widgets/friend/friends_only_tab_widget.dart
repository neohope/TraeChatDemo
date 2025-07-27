import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_model.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/user_search_viewmodel.dart' as presentation;
import '../user/user_search_widget.dart';
import 'friend_list_widget.dart';

/// 好友专用标签页组件
class FriendsOnlyTabWidget extends StatefulWidget {
  const FriendsOnlyTabWidget({Key? key}) : super(key: key);

  @override
  State<FriendsOnlyTabWidget> createState() => _FriendsOnlyTabWidgetState();
}

class _FriendsOnlyTabWidgetState extends State<FriendsOnlyTabWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriends();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
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
                      onTap: () => _onFriendTap(user),
                      onLongPress: () => _onFriendLongPress(user),
                      showOnlineStatus: true,
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

    return friends.where((friend) {
      return friend.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (friend.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  Future<void> _loadFriends() async {
    final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
    await friendViewModel.loadFriends();
  }

  void _navigateToUserSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserSearchWidget(),
    );
  }

  void _onFriendTap(UserModel user) {
    // 导航到聊天页面或用户详情页面
  }

  void _onFriendLongPress(UserModel user) {
    // 显示好友操作菜单
  }
}