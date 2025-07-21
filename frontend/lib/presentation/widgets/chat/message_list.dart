import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grouped_list/grouped_list.dart';

import '../../../domain/models/message_model.dart';
import '../../../presentation/viewmodels/message_view_model.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../../utils/date_formatter.dart';
import '../../../domain/models/conversation_model.dart';
import 'message_bubble.dart';

/// 消息列表组件
/// 
/// 用于显示聊天消息列表，支持分组、加载更多、滚动到底部等功能
class MessageList extends StatefulWidget {
  final String conversationId;
  final bool isGroup;
  final ScrollController scrollController;
  final Function() onLoadMore;
  
  const MessageList({
    Key? key,
    required this.conversationId,
    this.isGroup = false,
    required this.scrollController,
    required this.onLoadMore,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }
  
  void _scrollListener() {
    if (widget.scrollController.position.pixels == widget.scrollController.position.minScrollExtent) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        
        widget.onLoadMore().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }
  
  String _getDateString(DateTime dateTime) {
    return DateFormatter.formatMessageTime(dateTime);
  }
  
  @override
  Widget build(BuildContext context) {
    final messageViewModel = Provider.of<MessageViewModel>(context);
    final userViewModel = Provider.of<UserViewModel>(context);
    final currentUser = userViewModel.currentUser;
    
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final messages = messageViewModel.messages;
    
    if (messages.isEmpty) {
      return _buildEmptyMessages();
    }
    
    return Column(
      children: [
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        Expanded(
          child: GroupedListView<MessageModel, DateTime>(
            elements: messages,
            controller: widget.scrollController,
            reverse: true,
            order: GroupedListOrder.DESC,
            floatingHeader: true,
            useStickyGroupSeparators: true,
            groupBy: (message) => DateTime(
              message.timestamp.year,
              message.timestamp.month,
              message.timestamp.day,
            ),
            groupHeaderBuilder: (MessageModel message) => _buildDateSeparator(
              _getDateString(message.timestamp),
            ),
            itemBuilder: (context, MessageModel message) {
              final isMe = message.senderId == currentUser.id;
              String? senderName;
              
              if (widget.isGroup && !isMe) {
                final sender = userViewModel.getCachedUserById(message.senderId);
                senderName = sender?.displayName;
              }
              
              return MessageBubble(
                message: message,
                isMe: isMe,
                senderName: senderName,
                onLongPress: () => _showMessageOptions(message),
                onTap: (msg) {
                  // 点击消息的处理逻辑
                  if (msg.type == MessageType.image) {
                    _showFullImage(msg.mediaUrl ?? '');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateSeparator(String date) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          date,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
  
  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '没有消息',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '发送一条消息开始聊天吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showMessageOptions(MessageModel message) {
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final currentUser = userViewModel.currentUser;
    
    if (currentUser == null) return;
    
    final isMe = message.senderId == currentUser.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('复制'),
            onTap: () {
              if (message.type == MessageType.text) {
                // 复制文本消息
                // TODO: 实现复制功能
              }
              Navigator.pop(context);
            },
          ),
          if (isMe && message.status != MessageStatus.failed)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除'),
              onTap: () {
                messageViewModel.deleteMessage(message.id);
                Navigator.pop(context);
              },
            ),
          if (isMe && message.status == MessageStatus.failed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('重新发送'),
              onTap: () {
                messageViewModel.resendMessage(message.id);
                Navigator.pop(context);
              },
            ),
          if (!isMe && !message.isRead)
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('标记为已读'),
              onTap: () {
                messageViewModel.markMessageAsRead(message.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
  
  void _showFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}