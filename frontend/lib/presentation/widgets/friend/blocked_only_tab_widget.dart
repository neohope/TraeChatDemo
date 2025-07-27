import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_model.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/user_search_viewmodel.dart' as presentation;
import 'friend_list_widget.dart';

/// 黑名单专用标签页组件
class BlockedOnlyTabWidget extends StatefulWidget {
  const BlockedOnlyTabWidget({Key? key}) : super(key: key);

  @override
  State<BlockedOnlyTabWidget> createState() => _BlockedOnlyTabWidgetState();
}

class _BlockedOnlyTabWidgetState extends State<BlockedOnlyTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
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
          ],
        ),
      ),
    );
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.loadBlockedUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载黑名单失败: $e'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已解除对 ${user.name} 的屏蔽'),
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