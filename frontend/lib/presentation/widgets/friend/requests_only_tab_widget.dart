import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/friend_request_model.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/user_search_viewmodel.dart' as presentation;
import 'friend_list_widget.dart';

/// 请求专用标签页组件
class RequestsOnlyTabWidget extends StatefulWidget {
  const RequestsOnlyTabWidget({Key? key}) : super(key: key);

  @override
  State<RequestsOnlyTabWidget> createState() => _RequestsOnlyTabWidgetState();
}

class _RequestsOnlyTabWidgetState extends State<RequestsOnlyTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
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

  Future<void> _loadFriendRequests() async {
    try {
      final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
      await friendViewModel.loadFriendRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载好友请求失败: $e'),
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
            backgroundColor: Colors.blue,
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
}