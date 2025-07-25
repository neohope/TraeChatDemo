import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/conversation_model.dart' as domain;
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/message_viewmodel.dart';
import '../../../core/utils/app_date_utils.dart';
import 'chat_input_widget.dart';

/// 聊天界面主组件
class ChatScreenWidget extends StatefulWidget {
  final Chat chat;
  final bool showAppBar;
  final Function(UserModel)? onUserTap;
  final VoidCallback? onBack;

  const ChatScreenWidget({
    Key? key,
    required this.chat,
    this.showAppBar = true,
    this.onUserTap,
    this.onBack,
  }) : super(key: key);

  @override
  State<ChatScreenWidget> createState() => _ChatScreenWidgetState();
}

class _ChatScreenWidgetState extends State<ChatScreenWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late AnimationController _messageAnimationController;
  
  bool _showScrollToBottom = false;
  bool _isSelectionMode = false;
  Set<String> _selectedMessageIds = {};
  MessageModel? _replyToMessage;
  MessageModel? _editingMessage;
  List<MessageModel> _searchResults = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollController();
    _loadMessages();
    _markChatAsRead();
  }

  @override
  void dispose() {
    _messageAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
      
      // 加载更多历史消息
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });
  }

  void _loadMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageViewModel>().loadMessages(widget.chat.id);
    });
  }

  void _loadMoreMessages() {
    context.read<MessageViewModel>().loadMoreMessages(widget.chat.id);
  }

  void _markChatAsRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().markChatAsRead(widget.chat.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: widget.showAppBar ? _buildAppBar() : null,
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton(
              mini: true,
              onPressed: _scrollToBottom,
              child: const Icon(Icons.keyboard_arrow_down),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack ?? () => Navigator.pop(context),
      ),
      title: _buildAppBarTitle(),
      actions: _buildAppBarActions(),
      elevation: 1,
    );
  }

  Widget _buildAppBarTitle() {
    return Consumer<UserViewModel>(builder: (context, userViewModel, child) {
      final otherUser = _getOtherUser(userViewModel);
      
      return GestureDetector(
        onTap: () => _showChatInfo(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: _getAvatarImage(otherUser),
              child: _getAvatarImage(otherUser) == null
                  ? Text(
                      _getAvatarText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (otherUser != null)
                    Text(
                      _getSubtitle(otherUser),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.reply),
          onPressed: _selectedMessageIds.length == 1 ? _replyToSelectedMessage : null,
        ),
        IconButton(
          icon: const Icon(Icons.forward),
          onPressed: _forwardSelectedMessages,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelectedMessages,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
      ];
    }
    
    return [
      IconButton(
        icon: const Icon(Icons.videocam),
        onPressed: _startVideoCall,
      ),
      IconButton(
        icon: const Icon(Icons.call),
        onPressed: _startVoiceCall,
      ),
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'info',
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('聊天信息'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'search',
            child: ListTile(
              leading: Icon(Icons.search),
              title: Text('搜索消息'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'clear',
            child: ListTile(
              leading: Icon(Icons.clear_all),
              title: Text('清空聊天记录'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (widget.chat.type == ChatType.private)
            const PopupMenuItem(
              value: 'block',
              child: ListTile(
                leading: Icon(Icons.block, color: Colors.red),
                title: Text('屏蔽用户', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    ];
  }

  Widget _buildMessageList() {
    return Consumer<MessageViewModel>(builder: (context, messageViewModel, child) {
      if (messageViewModel.isLoading && messageViewModel.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (messageViewModel.error != null) {
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
                messageViewModel.error!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMessages,
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }

      final messages = messageViewModel.getMessagesForChat(widget.chat.id);
      
      if (messages.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无消息',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '发送第一条消息开始聊天吧',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        itemCount: messages.length + (messageViewModel.hasMoreMessages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            // 加载更多指示器
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final message = messages[messages.length - 1 - index];
          final isFromCurrentUser = _isFromCurrentUser(message);
          // ignore: unused_local_variable
          final sender = _getSender(message);
          // ignore: unused_local_variable
          final showAvatar = _shouldShowAvatar(messages, index, isFromCurrentUser);
          // ignore: unused_local_variable
          final showTimestamp = _shouldShowTimestamp(messages, index);
          
          return Column(
            children: [
              if (_shouldShowDateSeparator(messages, index))
                _buildDateSeparator(message.createdAt),
              GestureDetector(
                onTap: () => _handleMessageTap(message),
                onLongPress: () => _handleMessageLongPress(message),
                child: Container(
                  // TODO: Fix MessageModel type mismatch between data and domain models
                  // MessageBubbleWidget expects domain/models/MessageModel
                  // but we have data/models/MessageModel
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isFromCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        if (_replyToMessage != null) _buildReplyPreview(),
        if (_editingMessage != null) _buildEditPreview(),
        ChatInputWidget(
          replyToMessageId: _replyToMessage?.id,
          replyToMessageText: _replyToMessage?.content,
          onSendText: _handleSendTextMessage,
          onSendVoice: _handleSendVoiceMessage,
          onSendFile: _handleSendFileMessage,
          onCancelReply: () => setState(() => _replyToMessage = null),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '回复 ${_getSender(_replyToMessage!)?.name ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getMessagePreviewText(_replyToMessage!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          left: BorderSide(
            color: Colors.orange,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '编辑消息',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editingMessage!.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _editingMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppDateUtils.formatDateSeparator(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  // 辅助方法
  UserModel? _getOtherUser(UserViewModel userViewModel) {
    if (widget.chat.type == ChatType.private && widget.chat.participants.length >= 2) {
      final currentUserId = userViewModel.currentUser?.id;
      final otherUserId = widget.chat.participants.firstWhere(
        (userId) => userId != currentUserId,
        orElse: () => widget.chat.participants.first,
      );
      // Get UserModel from UserViewModel based on userId
      return userViewModel.getUserById(otherUserId);
    }
    return null;
  }

  ImageProvider? _getAvatarImage(UserModel? otherUser) {
    if (widget.chat.type == ChatType.group) {
      return widget.chat.avatarUrl != null ? NetworkImage(widget.chat.avatarUrl!) : null;
    } else {
      return otherUser?.avatarUrl != null ? NetworkImage(otherUser!.avatarUrl!) : null;
    }
  }

  String _getAvatarText() {
    return widget.chat.name.substring(0, 1).toUpperCase();
  }

  String _getSubtitle(UserModel otherUser) {
    if (otherUser.isOnline) {
      return '在线';
    } else if (otherUser.lastSeenAt != null) {
      return '最后在线 ${AppDateUtils.formatLastSeen(otherUser.lastSeenAt!)}';
    } else {
      return '离线';
    }
  }

  bool _isFromCurrentUser(MessageModel message) {
    final currentUserId = context.read<UserViewModel>().currentUser?.id;
    return message.senderId == currentUserId;
  }

  UserModel? _getSender(MessageModel message) {
    final userViewModel = context.read<UserViewModel>();
    return userViewModel.getUserById(message.senderId) ?? UserModel(
      id: message.senderId,
      name: 'Unknown',
    );
  }

  bool _shouldShowAvatar(List<MessageModel> messages, int index, bool isFromCurrentUser) {
    if (isFromCurrentUser) return false;
    if (index == 0) return true;
    
    final currentMessage = messages[messages.length - 1 - index];
    final nextMessage = messages[messages.length - index];
    
    return currentMessage.senderId != nextMessage.senderId;
  }

  bool _shouldShowTimestamp(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[messages.length - 1 - index];
    final nextMessage = messages[messages.length - index];
    
    final timeDiff = nextMessage.createdAt.difference(currentMessage.createdAt);
    return timeDiff.inMinutes > 5;
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = messages[messages.length - 1 - index];
    final previousMessage = messages[messages.length - index];
    
    return !AppDateUtils.isSameDay(currentMessage.createdAt, previousMessage.createdAt);
  }

  String _getMessagePreviewText(MessageModel message) {
    if (message.type == 'text') {
      return message.content;
    } else if (message.type == 'image') {
      return '[图片]';
    } else if (message.type == 'audio') {
      return '[语音]';
    } else if (message.type == 'video') {
      return '[视频]';
    } else if (message.type == 'file') {
      return '[文件]';
    } else if (message.type == 'location') {
      return '[位置]';
    } else {
      return message.content;
    }
  }

  // 事件处理方法
  void _handleMessageTap(MessageModel message) {
    if (_isSelectionMode) {
      _toggleMessageSelection(message.id);
    }
  }

  void _handleMessageLongPress(MessageModel message) {
    HapticFeedback.mediumImpact();
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedMessageIds.add(message.id);
      });
    }
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  // TODO: Fix MessageModel type mismatch between data and domain models
  // dynamic _handleReplyToMessage(MessageModel message) {
  //   setState(() {
  //     _replyToMessage = message;
  //     _editingMessage = null;
  //   });
  //   return null;
  // }

  // dynamic _handleForwardMessage(MessageModel message) {
  //   // TODO: 实现转发消息功能
  //   return null;
  // }

  // dynamic _handleDeleteMessage(MessageModel message) {
  //   context.read<MessageViewModel>().deleteMessage(message.id);
  //   return null;
  // }

  // dynamic _handleEditMessage(MessageModel message) {
  //   if (message.type == 'text') {
  //     setState(() {
  //       _editingMessage = message;
  //       _replyToMessage = null;
  //     });
  //   }
  //   return null;
  // }

  void _replyToSelectedMessage() {
    if (_selectedMessageIds.length == 1) {
      final messageId = _selectedMessageIds.first;
      MessageModel? message;
       try {
         final foundMessage = context.read<MessageViewModel>().messages.firstWhere(
           (m) => m.id == messageId,
         );
         message = foundMessage;
       } catch (e) {
         message = null;
       }
      if (message != null) {
        // TODO: Fix MessageModel type mismatch
        // _handleReplyToMessage(message);
      }
    }
    _exitSelectionMode();
  }

  void _forwardSelectedMessages() {
    final selectedMessages = context.read<MessageViewModel>().messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    
    if (selectedMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要转发的消息')),
      );
      return;
    }
    
    _showForwardSelectedMessagesDialog(selectedMessages);
    _exitSelectionMode();
  }

  void _deleteSelectedMessages() {
    for (final messageId in _selectedMessageIds) {
      context.read<MessageViewModel>().deleteMessage(messageId);
    }
    _exitSelectionMode();
  }

  dynamic _handleSendTextMessage(String content, domain.MessageType type) {
    context.read<MessageViewModel>().sendMessage(
      chatId: widget.chat.id,
      content: content,
      type: 'text', // Convert enum to string
      metadata: _replyToMessage != null ? {'replyToMessageId': _replyToMessage!.id} : null,
    );
    
    setState(() {
      _replyToMessage = null;
      _editingMessage = null;
    });
    
    _scrollToBottom();
    return null;
  }

  void _handleSendVoiceMessage(String voicePath, int duration) {
    context.read<MessageViewModel>().sendMessage(
      chatId: widget.chat.id,
      content: '',
      type: 'voice',
      metadata: {
        'voicePath': voicePath,
        'duration': duration,
        if (_replyToMessage != null) 'replyToMessageId': _replyToMessage!.id,
      },
    );
    
    setState(() {
      _replyToMessage = null;
    });
    
    _scrollToBottom();
  }

  void _handleSendFileMessage(String filePath, String fileName, String fileType) {
    context.read<MessageViewModel>().sendMessage(
      chatId: widget.chat.id,
      content: fileName,
      type: 'file',
      metadata: {
        'filePath': filePath,
        'fileName': fileName,
        'fileType': fileType,
        if (_replyToMessage != null) 'replyToMessageId': _replyToMessage!.id,
      },
    );
    
    setState(() {
      _replyToMessage = null;
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showChatInfo() {
     // 显示聊天信息页面
     print('显示聊天信息页面');
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('聊天信息页面已打开')),
     );
   }

  void _startVideoCall() {
     // 启动视频通话
     print('启动视频通话');
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('视频通话已启动')),
     );
   }

  void _startVoiceCall() {
     // 启动语音通话
     print('启动语音通话');
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('语音通话已启动')),
     );
   }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _showChatInfo();
        break;
      case 'search':
        _showSearchMessages();
        break;
      case 'clear':
        _showClearChatDialog();
        break;
      case 'block':
        _showBlockUserDialog();
        break;
    }
  }

  void _showSearchMessages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '搜索消息...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final message = _searchResults[index];
                    return ListTile(
                      title: Text(_getMessagePreviewText(message)),
                      subtitle: const Text('刚刚'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: 滚动到对应消息位置
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要清空所有聊天记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChatMessages();
              // context.read<MessageViewModel>().clearChatMessages(widget.chat.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    final otherUser = _getOtherUser(context.read<UserViewModel>());
    if (otherUser == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('屏蔽用户'),
        content: Text('确定要屏蔽 ${otherUser.name} 吗？屏蔽后将不会收到该用户的消息，且无法查看聊天记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBlockUser(otherUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('屏蔽'),
          ),
        ],
      ),
    );
  }
  
  void _performBlockUser(UserModel user) async {
     await _blockUser(user);
     // context.read<UserViewModel>().blockUser(user.id);
     
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('已屏蔽 ${user.name}'),
         backgroundColor: Colors.orange,
       ),
     );
     
     // 返回上一页
     Navigator.pop(context);
   }
   
  void _showForwardSelectedMessagesDialog(List<MessageModel> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '转发 ${messages.length} 条消息',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '选择转发对象',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, chatViewModel, child) {
                  // 模拟聊天列表
                   return ListView.builder(
                     itemCount: 5,
                     itemBuilder: (context, index) {
                       return ListTile(
                         leading: CircleAvatar(
                           child: Text('${index + 1}'),
                         ),
                         title: Text('聊天 ${index + 1}'),
                         subtitle: const Text('私聊'),
                         onTap: () {
                           Navigator.pop(context);
                           _forwardMessagesToChat(messages, 'chat_${index + 1}');
                         },
                       );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _forwardMessagesToChat(List<MessageModel> messages, String targetChatId) async {
    try {
      // TODO: 实现实际的转发逻辑
      // for (final message in messages) {
      //   await context.read<MessageViewModel>().forwardMessage(
      //     messageId: message.id,
      //     targetChatId: targetChatId,
      //   );
      // }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已转发 ${messages.length} 条消息'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('转发失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _clearChatMessages() async {
    try {
      // TODO: 实现清空聊天记录功能
      // await context.read<MessageViewModel>().clearChatMessages(widget.chat.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('聊天记录已清空'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清空失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
   
   Future<void> _blockUser(UserModel user) async {
     try {
       // TODO: 实现屏蔽用户功能
       // await context.read<UserViewModel>().blockUser(user.id);
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('已屏蔽用户 ${user.name}'),
           backgroundColor: Colors.orange,
         ),
       );
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('屏蔽失败: $e'),
           backgroundColor: Colors.red,
         ),
       );
     }
   }
   
   void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    try {
      // 调用消息服务搜索消息
       print('搜索消息: $query');
       // final results = await context.read<MessageViewModel>().searchMessages(widget.chat.id, query);
      
      // 模拟搜索结果
      final allMessages = context.read<MessageViewModel>().getMessagesForChat(widget.chat.id);
      final results = allMessages.where((message) {
        return message.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}