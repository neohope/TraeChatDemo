import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/conversation_model.dart';
import '../../../domain/viewmodels/conversation_viewmodel.dart';
import '../../../presentation/pages/chat/chat_page.dart';
import 'conversation_list_item.dart';

/// 会话列表组件
/// 
/// 用于显示所有会话，支持下拉刷新、点击进入聊天、长按显示操作菜单等功能
class ConversationList extends StatefulWidget {
  const ConversationList({Key? key}) : super(key: key);

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    // 延迟加载会话列表，避免与页面构建冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshConversations();
    });
  }
  
  Future<void> _refreshConversations() async {
    final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    await conversationViewModel.loadConversations();
  }
  
  void _navigateToChatPage(ConversationModel conversation) {
    // 获取接收者ID
    String userId;
    if (conversation.isGroup) {
      // 群聊使用群ID作为接收者ID
      userId = conversation.id;
    } else {
      // 单聊使用参与者ID
      if (conversation.participantId != null) {
        // 优先使用 participantId
        userId = conversation.participantId!;
      } else if (conversation.participantIds != null && conversation.participantIds!.isNotEmpty) {
        // 如果有 participantIds，则查找非当前用户的ID
        String? currentUserId = Provider.of<ConversationViewModel>(context, listen: false).currentUserId;
        userId = conversation.participantIds!.firstWhere(
          (id) => id != currentUserId,
          orElse: () => conversation.participantIds!.first,
        );
      } else {
        // 如果都没有，使用会话ID
        userId = conversation.id;
      }
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          userId: userId,
          userName: conversation.name,
        ),
      ),
    );
  }
  
  void _showConversationOptions(ConversationModel conversation) {
    final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(conversation.isPinned ? '取消置顶' : '置顶'),
            onTap: () {
              conversationViewModel.togglePinConversation(conversation.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              conversation.isMuted ? Icons.volume_up : Icons.volume_off,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(conversation.isMuted ? '取消静音' : '静音'),
            onTap: () {
              conversationViewModel.toggleMuteConversation(conversation.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              conversation.isArchived ? Icons.unarchive : Icons.archive,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(conversation.isArchived ? '取消归档' : '归档'),
            onTap: () {
              conversationViewModel.toggleArchiveConversation(conversation.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text('删除'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(conversation);
            },
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(ConversationModel conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确定要删除这个会话吗？这将删除所有相关消息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
              conversationViewModel.deleteConversation(conversation.id);
              Navigator.pop(context);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationViewModel>(
      builder: (context, conversationViewModel, child) {
        if (conversationViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (conversationViewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败: ${conversationViewModel.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshConversations,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        
        final conversations = conversationViewModel.conversations;
        
        if (conversations.isEmpty) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshConversations,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 128), // 0.5 * 255 = 127.5 ≈ 128
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '没有会话',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withValues(alpha: 204), // 0.8 * 255 = 204
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '开始一个新的聊天吧',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withValues(alpha: 153), // 0.6 * 255 = 153
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // 将 Conversation 转换为 ConversationModel
        final conversationModels = conversations.map(
          (conversation) => conversationViewModel.convertToConversationModel(conversation)
        ).toList();
        
        // 分离置顶和非置顶会话
        final pinnedConversations = conversationModels.where((c) => c.isPinned).toList();
        final unpinnedConversations = conversationModels.where((c) => !c.isPinned).toList();
        
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshConversations,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // 置顶会话
              if (pinnedConversations.isNotEmpty) ...[                
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    '置顶会话',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ...pinnedConversations.map((conversation) => Column(
                  children: [
                    ConversationListItem(
                      conversation: conversation,
                      onTap: _navigateToChatPage,
                      onLongPress: _showConversationOptions,
                    ),
                    const Divider(height: 1, indent: 72),
                  ],
                )),
              ],
              
              // 其他会话
              if (unpinnedConversations.isNotEmpty) ...[                
                if (pinnedConversations.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text(
                      '全部会话',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ...unpinnedConversations.map((conversation) => Column(
                  children: [
                    ConversationListItem(
                      conversation: conversation,
                      onTap: _navigateToChatPage,
                      onLongPress: _showConversationOptions,
                    ),
                    const Divider(height: 1, indent: 72),
                  ],
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}