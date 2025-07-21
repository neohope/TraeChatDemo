import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/viewmodels/conversation_viewmodel.dart';
import '../../../routes/app_router.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/chat/conversation_list_item.dart';
import '../../../widgets/common/custom_text_field.dart';

/// 聊天标签页，显示会话列表
class ChatsTab extends StatefulWidget {
  const ChatsTab({Key? key}) : super(key: key);

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  // 搜索内容变化
  void _onSearchChanged() {
    final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    final query = _searchController.text.trim();
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isNotEmpty) {
      // 执行搜索
      conversationViewModel.searchConversations(query);
    } else {
      // 清空搜索，显示所有会话
      conversationViewModel.clearSearch();
    }
  }
  
  // 刷新会话列表
  Future<void> _refreshConversations() async {
    final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    await conversationViewModel.loadConversations(forceRefresh: true);
  }
  
  // 创建新会话
  void _createNewChat() {
    // 导航到联系人选择页面
    // 这里可以实现导航到联系人选择页面的逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          // 更多选项按钮
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_group':
                  // 创建群聊
                  break;
                case 'settings':
                  // 导航到设置页面
                  AppRouter.router.go(AppRouter.settings);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'new_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: AppTheme.spacingSmall),
                    Text('创建群聊'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: AppTheme.spacingSmall),
                    Text('设置'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingNormal),
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: '搜索会话',
                    prefixIcon: Icons.search,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Consumer<ConversationViewModel>(  
        builder: (context, conversationViewModel, child) {
          // 获取会话列表
          final conversations = _isSearching
              ? conversationViewModel.searchResultModels
              : conversationViewModel.conversationModels;
          
          // 如果正在加载且没有数据，显示加载指示器
          if (conversationViewModel.isLoading && conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 如果没有会话，显示空状态
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppTheme.spacingNormal),
                  Text(
                    _isSearching ? '没有找到相关会话' : '暂无会话',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (!_isSearching) ...[  
                    const SizedBox(height: AppTheme.spacingLarge),
                    ElevatedButton.icon(
                      onPressed: _createNewChat,
                      icon: const Icon(Icons.add),
                      label: const Text('开始新的聊天'),
                    ),
                  ],
                ],
              ),
            );
          }
          
          // 显示会话列表
          return RefreshIndicator(
            onRefresh: _refreshConversations,
            child: ListView.separated(
              padding: const EdgeInsets.only(top: AppTheme.spacingSmall),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationListItem(
                  conversation: conversation,
                  onTap: () {
                    // 选择会话并导航到聊天页面
                    conversationViewModel.selectConversationByModel(conversation);
                    
                    if (conversation.isGroup) {
                      // 导航到群聊页面
                      AppRouter.router.go(
                        '${AppRouter.groupChat}/${conversation.id}',
                        extra: {'groupName': conversation.name},
                      );
                    } else {
                      // 导航到单聊页面
                      AppRouter.router.go(
                        '${AppRouter.chat}/${conversation.participantId}',
                        extra: {'userName': conversation.name},
                      );
                    }
                  },
                  onLongPress: () {
                    // 显示会话操作菜单
                    _showConversationOptions(conversation);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        child: const Icon(Icons.chat),
      ),
    );
  }
  
  // 显示会话操作菜单
  void _showConversationOptions(dynamic conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: Text(conversation.isPinned ? '取消置顶' : '置顶会话'),
                onTap: () {
                  Navigator.pop(context);
                  // 切换置顶状态
                  final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
                  conversationViewModel.updateConversation(
                    conversation.id,
                    isPinned: !conversation.isPinned,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: Text(conversation.isMuted ? '开启通知' : '静音会话'),
                onTap: () {
                  Navigator.pop(context);
                  // 切换静音状态
                  final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
                  conversationViewModel.updateConversation(
                    conversation.id,
                    isMuted: !conversation.isMuted,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除会话', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // 确认删除
                  _confirmDeleteConversation(conversation);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 确认删除会话
  void _confirmDeleteConversation(dynamic conversation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除会话'),
          content: const Text('确定要删除这个会话吗？聊天记录将会保留。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 删除会话
                final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
                conversationViewModel.deleteConversation(conversation.id);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}