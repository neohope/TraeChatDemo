import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../domain/services/auth_service.dart';
import '../../viewmodels/message_view_model.dart';
import 'reply_message_bubble.dart';
import 'enhanced_chat_input.dart';
import 'recalled_message_widget.dart';
import 'forward_selection_screen.dart';

/// 支持引用回复的聊天界面
class ChatScreenWithReply extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String conversationName;

  const ChatScreenWithReply({
    Key? key,
    required this.conversationId,
    required this.receiverId,
    required this.conversationName,
  }) : super(key: key);

  @override
  State<ChatScreenWithReply> createState() => _ChatScreenWithReplyState();
}

class _ChatScreenWithReplyState extends State<ChatScreenWithReply> {
  final ScrollController _scrollController = ScrollController();
  MessageModel? _replyToMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    final messageViewModel = context.read<MessageViewModel>();
    messageViewModel.setCurrentConversation(widget.conversationId);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final messageViewModel = context.read<MessageViewModel>();
      if (!_isLoading && messageViewModel.hasMoreMessages) {
        setState(() {
          _isLoading = true;
        });
        messageViewModel.loadMessages().then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversationName),
        actions: [
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
                  leading: Icon(Icons.delete),
                  title: Text('清空聊天记录'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _buildMessageList(),
          ),
          
          // 输入区域
          EnhancedChatInput(
            onSendText: _sendTextMessage,
            onSendReply: _sendReplyMessage,
            onSendImage: _sendImageMessage,
            onSendVoice: _sendVoiceMessage,
            replyToMessage: _replyToMessage,
            onCancelReply: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<MessageViewModel>(
      builder: (context, messageViewModel, child) {
        if (messageViewModel.isLoading && messageViewModel.messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (messageViewModel.errorMessage != null) {
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
                  '加载消息失败',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  messageViewModel.errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => messageViewModel.loadMessages(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final messages = messageViewModel.messages;
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无消息',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '发送第一条消息开始聊天吧',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
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

            // 添加索引边界检查，避免越界访问
            if (index >= messages.length || messages.length - 1 - index < 0) {
              return const SizedBox.shrink();
            }

            final message = messages[messages.length - 1 - index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(MessageModel message) {
    // 如果是撤回消息，显示撤回组件
    if (message.type == MessageType.recalled) {
      return RecalledMessageWidget(
        message: message,
        currentUserId: _getCurrentUserId(),
      );
    }

    // 普通消息气泡
    return ReplyMessageBubble(
      message: message,
      currentUserId: _getCurrentUserId(),
      onReply: () => _handleReplyToMessage(message),
      onForward: () => _handleForwardMessage(message),
      onDelete: () => _handleDeleteMessage(message),
      onRecall: () => _handleRecallMessage(message),
      onEdit: () => _handleEditMessage(message),
      onCopy: () => _handleCopyMessage(message),
      onQuotedMessageTap: _handleQuotedMessageTap,
    );
  }

  // 消息操作处理
  void _handleReplyToMessage(MessageModel message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _handleForwardMessage(MessageModel message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForwardSelectionScreen(
          messageToForward: message,
        ),
      ),
    );
  }

  void _handleDeleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MessageViewModel>().deleteMessage(message.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _handleRecallMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤回消息'),
        content: const Text('确定要撤回这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recallMessage(message.id);
            },
            child: const Text('撤回'),
          ),
        ],
      ),
    );
  }

  void _handleEditMessage(MessageModel message) {
    if (message.type != MessageType.text) {
      _showErrorSnackBar('只能编辑文本消息');
      return;
    }
    
    if (message.isRecalled || message.isDeleted) {
      _showErrorSnackBar('无法编辑已撤回或已删除的消息');
      return;
    }
    
    _showEditMessageDialog(message);
  }
  
  void _showEditMessageDialog(MessageModel message) {
    final TextEditingController controller = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: '输入新的消息内容...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isEmpty) {
                _showErrorSnackBar('消息内容不能为空');
                return;
              }
              
              Navigator.pop(context);
              _editMessage(message.id, newText);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _editMessage(String messageId, String newText) {
    context.read<MessageViewModel>().editMessage(messageId, newText)
        .then((result) {
      result.when(
        success: (_) => _showSuccessSnackBar('消息已编辑'),
        error: (error) => _showErrorSnackBar('编辑失败: $error'),
      );
    });
  }

  void _handleCopyMessage(MessageModel message) {
    String textToCopy = '';
    
    switch (message.type) {
      case MessageType.text:
        textToCopy = message.text ?? '';
        break;
      case MessageType.image:
        textToCopy = '[图片]';
        break;
      case MessageType.voice:
        textToCopy = '[语音消息]';
        break;
      case MessageType.video:
        textToCopy = '[视频]';
        break;
      case MessageType.file:
        final fileName = message.metadata?['fileName'] ?? '文件';
        textToCopy = '[文件: $fileName]';
        break;
      case MessageType.location:
        final address = message.metadata?['address'] ?? '位置信息';
        textToCopy = '[位置: $address]';
        break;
      case MessageType.system:
        textToCopy = message.text ?? '[系统消息]';
        break;
      case MessageType.recalled:
        textToCopy = '[已撤回的消息]';
        break;
      default:
        textToCopy = '[消息]';
    }
    
    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      _showSuccessSnackBar('已复制到剪贴板');
    } else {
      _showErrorSnackBar('无法复制此消息');
    }
  }

  void _handleQuotedMessageTap(MessageModel quotedMessage) {
    final messageViewModel = context.read<MessageViewModel>();
    final messages = messageViewModel.messages;
    
    // 查找被引用消息的索引
    final targetIndex = messages.indexWhere((m) => m.id == quotedMessage.id);
    
    if (targetIndex == -1) {
      _showErrorSnackBar('引用的消息不存在或已被删除');
      return;
    }
    
    // 计算在ListView中的实际位置（因为ListView是reverse的）
    final listViewIndex = messages.length - 1 - targetIndex;
    
    // 滚动到目标消息
    if (_scrollController.hasClients) {
      // 估算每个消息项的高度（这里使用一个平均值）
      const estimatedItemHeight = 80.0;
      final targetOffset = listViewIndex * estimatedItemHeight;
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        // 滚动完成后显示提示
        _showSuccessSnackBar('已定位到引用消息');
      });
    }
  }

  // 发送消息方法
  void _sendTextMessage(String text) {
    context.read<MessageViewModel>().sendTextMessage(text, widget.receiverId)
        .then((result) {
      result.when(
        success: (_) => _scrollToBottom(),
        error: (error) => _showErrorSnackBar('发送失败: $error'),
      );
    });
  }

  void _sendReplyMessage(String text, MessageModel replyToMessage) {
    context.read<MessageViewModel>().sendReplyMessage(
      text: text,
      replyToMessage: replyToMessage,
    ).then((result) {
      result.when(
        success: (_) {
          setState(() {
            _replyToMessage = null;
          });
          _scrollToBottom();
        },
        error: (error) => _showErrorSnackBar('发送回复失败: $error'),
      );
    });
  }

  void _sendImageMessage(String imagePath) {
    context.read<MessageViewModel>().sendImageMessage(imagePath, widget.receiverId)
        .then((result) {
      result.when(
        success: (_) => _scrollToBottom(),
        error: (error) => _showErrorSnackBar('发送图片失败: $error'),
      );
    });
  }

  void _sendVoiceMessage(String voicePath, int duration) {
    context.read<MessageViewModel>().sendVoiceMessage(
      voicePath,
      duration,
      widget.receiverId,
    ).then((result) {
      result.when(
        success: (_) => _scrollToBottom(),
        error: (error) => _showErrorSnackBar('发送语音失败: $error'),
      );
    });
  }

  void _recallMessage(String messageId) {
    context.read<MessageViewModel>().recallMessage(messageId)
        .then((result) {
      result.when(
        success: (_) => _showSuccessSnackBar('消息已撤回'),
        error: (error) => _showErrorSnackBar('撤回失败: $error'),
      );
    });
  }

  // 辅助方法
  String _getCurrentUserId() {
    final authService = context.read<AuthService>();
    return authService.currentUser?.id ?? 'unknown_user';
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 菜单操作
  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('视频通话功能尚未实现')),
    );
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音通话功能尚未实现')),
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
    }
  }

  void _showChatInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('聊天信息功能尚未实现')),
    );
  }

  void _showSearchMessages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('搜索消息功能尚未实现')),
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
            onPressed: () {
              Navigator.pop(context);
              context.read<MessageViewModel>().clearMessages();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}