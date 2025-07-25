import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart' as presentation;
import '../../../core/utils/app_date_utils.dart';

/// 聊天列表组件
class ChatListWidget extends StatefulWidget {
  final Function(ConversationModel)? onChatTap;
  final Function(ConversationModel)? onChatLongPress;
  final bool showSearchBar;
  final bool showOnlineStatus;
  final ScrollController? scrollController;

  const ChatListWidget({
    Key? key,
    this.onChatTap,
    this.onChatLongPress,
    this.showSearchBar = true,
    this.showOnlineStatus = true,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadConversations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(builder: (context, chatViewModel, child) {
      return Column(
        children: [
          if (widget.showSearchBar) _buildSearchBar(),
          Expanded(
            child: _buildChatList(chatViewModel),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索聊天',
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

  Widget _buildChatList(ChatViewModel chatViewModel) {
    if (chatViewModel.isLoading && chatViewModel.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatViewModel.error != null) {
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
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chatViewModel.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final filteredChats = _getFilteredChats(chatViewModel.conversations);

    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? '未找到相关聊天' : '暂无聊天',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (!_isSearching) ...[
              const SizedBox(height: 8),
              Text(
                '开始一个新的对话吧',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await chatViewModel.loadConversations();
      },
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final conversation = filteredChats[index];
          return ChatListItemWidget(
            chat: conversation,
            onTap: () => widget.onChatTap?.call(conversation),
            onLongPress: () => widget.onChatLongPress?.call(conversation),
            showOnlineStatus: widget.showOnlineStatus,
          );
        },
      ),
    );
  }

  List<ConversationModel> _getFilteredChats(List<ConversationModel> conversations) {
    if (_searchQuery.isEmpty) {
      return conversations;
    }

    return conversations.where((conversation) {
      final query = _searchQuery.toLowerCase();
      return conversation.name.toLowerCase().contains(query) ||
             (conversation.lastMessage?.toLowerCase().contains(query) ?? false);
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

/// 聊天列表项组件
class ChatListItemWidget extends StatelessWidget {
  final ConversationModel chat;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showOnlineStatus;

  const ChatListItemWidget({
    Key? key,
    required this.chat,
    this.onTap,
    this.onLongPress,
    this.showOnlineStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<presentation.UserViewModel>(builder: (context, userViewModel, child) {
      final otherUser = _getOtherUser(userViewModel);
      
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(otherUser),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessage != null)
                          Text(
                            AppDateUtils.formatTime(chat.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLastMessage(),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
      );
    });
  }

  Widget _buildAvatar(UserModel? otherUser) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: _getAvatarImage(otherUser),
          child: _getAvatarImage(otherUser) == null
              ? Text(
                  _getAvatarText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (showOnlineStatus && otherUser != null && otherUser.status == UserStatus.online)
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

  Widget _buildLastMessage() {
    if (chat.lastMessage == null || chat.lastMessage!.isEmpty) {
      return Text(
        '暂无消息',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    String messageText;
    IconData? messageIcon;

    switch (chat.lastMessageType) {
      case MessageType.text:
        messageText = chat.lastMessage!;
        break;
      case MessageType.image:
        messageText = '[图片]';
        messageIcon = Icons.image;
        break;
      case MessageType.voice:
        messageText = '[语音]';
        messageIcon = Icons.mic;
        break;
      case MessageType.video:
        messageText = '[视频]';
        messageIcon = Icons.videocam;
        break;
      case MessageType.file:
        messageText = '[文件]';
        messageIcon = Icons.attach_file;
        break;
      case MessageType.location:
        messageText = '[位置]';
        messageIcon = Icons.location_on;
        break;
      case MessageType.system:
        messageText = chat.lastMessage!;
        messageIcon = Icons.info_outline;
        break;
      default:
        messageText = chat.lastMessage!;
        break;
    }

    return Row(
      children: [
        if (messageIcon != null) ...[
          Icon(
            messageIcon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            messageText,
            style: TextStyle(
              fontSize: 14,
              color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
              fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  ImageProvider? _getAvatarImage(UserModel? otherUser) {
    if (chat.isGroup) {
      return chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null;
    } else {
      return otherUser?.avatarUrl != null ? NetworkImage(otherUser!.avatarUrl!) : null;
    }
  }

  String _getAvatarText() {
    return chat.name.substring(0, 1).toUpperCase();
  }

  UserModel? _getOtherUser(presentation.UserViewModel userViewModel) {
    if (!chat.isGroup) {
      final currentUserId = userViewModel.currentUser?.id;
      if (chat.participantId != null && chat.participantId != currentUserId) {
        return userViewModel.getUserById(chat.participantId!);
      } else if (chat.participantIds != null && chat.participantIds!.length >= 2) {
        final otherUserId = chat.participantIds!.firstWhere(
          (userId) => userId != currentUserId,
          orElse: () => chat.participantIds!.first,
        );
        return userViewModel.getUserById(otherUserId);
      }
    }
    return null;
  }
}

/// 聊天列表搜索结果组件
class ChatSearchResultWidget extends StatelessWidget {
  final List<ConversationModel> searchResults;
  final String searchQuery;
  final Function(ConversationModel)? onChatTap;
  final VoidCallback? onClearSearch;

  const ChatSearchResultWidget({
    Key? key,
    required this.searchResults,
    required this.searchQuery,
    this.onChatTap,
    this.onClearSearch,
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
                    '未找到相关聊天',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final conversation = searchResults[index];
                    return ChatListItemWidget(
                      chat: conversation,
                      onTap: () => onChatTap?.call(conversation),
                      showOnlineStatus: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// 聊天操作菜单组件
class ChatActionMenuWidget extends StatelessWidget {
  final ConversationModel chat;
  final Function(ConversationModel)? onPin;
  final Function(ConversationModel)? onMute;
  final Function(ConversationModel)? onMarkAsRead;
  final Function(ConversationModel)? onDelete;
  final Function(ConversationModel)? onArchive;
  final Function(ConversationModel)? onBlock;

  const ChatActionMenuWidget({
    Key? key,
    required this.chat,
    this.onPin,
    this.onMute,
    this.onMarkAsRead,
    this.onDelete,
    this.onArchive,
    this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chat.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(chat.isPinned ? '取消置顶' : '置顶聊天'),
            onTap: () {
              Navigator.pop(context);
              onPin?.call(chat);
            },
          ),
          ListTile(
            leading: Icon(chat.isMuted ? Icons.notifications : Icons.notifications_off),
            title: Text(chat.isMuted ? '取消免打扰' : '免打扰'),
            onTap: () {
              Navigator.pop(context);
              onMute?.call(chat);
            },
          ),
          if (chat.unreadCount > 0)
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('标记为已读'),
              onTap: () {
                Navigator.pop(context);
                onMarkAsRead?.call(chat);
              },
            ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('归档聊天'),
            onTap: () {
              Navigator.pop(context);
              onArchive?.call(chat);
            },
          ),
          if (!chat.isGroup)
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('屏蔽用户', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                onBlock?.call(chat);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除聊天', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除聊天'),
        content: Text('确定要删除与 ${chat.name} 的聊天吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(chat);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}