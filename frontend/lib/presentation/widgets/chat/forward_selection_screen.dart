import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../viewmodels/message_view_model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../../utils/result.dart';
import 'forwarded_message_widget.dart';

/// 转发选择界面
class ForwardSelectionScreen extends StatefulWidget {
  final MessageModel messageToForward;

  const ForwardSelectionScreen({
    Key? key,
    required this.messageToForward,
  }) : super(key: key);

  @override
  State<ForwardSelectionScreen> createState() => _ForwardSelectionScreenState();
}

class _ForwardSelectionScreenState extends State<ForwardSelectionScreen> {
  final Set<String> _selectedConversationIds = {};
  final TextEditingController _searchController = TextEditingController();
  List<ConversationModel> _filteredConversations = [];
  bool _isForwarding = false;

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
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.loadConversations();
  }

  void _filterConversations(String query) {
    final chatViewModel = context.read<ChatViewModel>();
    final allConversations = chatViewModel.conversations;
    
    if (query.isEmpty) {
      _filteredConversations = allConversations;
    } else {
      _filteredConversations = allConversations
          .where((conversation) => 
              conversation.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择转发对象'),
        actions: [
          if (_selectedConversationIds.isNotEmpty)
            TextButton(
              onPressed: _isForwarding ? null : _forwardMessage,
              child: _isForwarding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '转发(${_selectedConversationIds.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 转发消息预览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '要转发的消息:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                _buildMessagePreview(),
              ],
            ),
          ),
          
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索聊天',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterConversations('');
                        },
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
              onChanged: _filterConversations,
            ),
          ),
          
          // 会话列表
          Expanded(
            child: _buildConversationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePreview() {
    switch (widget.messageToForward.type) {
      case MessageType.text:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            widget.messageToForward.text ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                _getMessageTypeIcon(widget.messageToForward.type),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getMessageTypeText(widget.messageToForward.type),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildConversationList() {
    return Consumer<ChatViewModel>(
      builder: (context, chatViewModel, child) {
        if (chatViewModel.isLoading && chatViewModel.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final conversations = _filteredConversations.isEmpty 
            ? chatViewModel.conversations 
            : _filteredConversations;

        if (conversations.isEmpty) {
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
                  _searchController.text.isNotEmpty ? '未找到相关聊天' : '暂无聊天',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final isSelected = _selectedConversationIds.contains(conversation.id);
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: conversation.avatarUrl != null
                    ? NetworkImage(conversation.avatarUrl!)
                    : null,
                child: conversation.avatarUrl == null
                    ? Text(
                        conversation.name.isNotEmpty
                            ? conversation.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                conversation.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                conversation.isGroup ? '群聊' : '私聊',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey,
                    ),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedConversationIds.remove(conversation.id);
                  } else {
                    _selectedConversationIds.add(conversation.id);
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.voice:
        return Icons.mic;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.location:
        return Icons.location_on;
      default:
        return Icons.message;
    }
  }

  String _getMessageTypeText(MessageType type) {
    switch (type) {
      case MessageType.text:
        return '文本消息';
      case MessageType.image:
        return '[图片]';
      case MessageType.voice:
        return '[语音]';
      case MessageType.video:
        return '[视频]';
      case MessageType.file:
        return '[文件]';
      case MessageType.location:
        return '[位置]';
      case MessageType.system:
        return '[系统消息]';
      case MessageType.recalled:
        return '[已撤回的消息]';
      default:
        return '[消息]';
    }
  }

  void _forwardMessage() async {
    if (_selectedConversationIds.isEmpty) return;

    setState(() {
      _isForwarding = true;
    });

    try {
      final messageViewModel = context.read<MessageViewModel>();
      
      if (_selectedConversationIds.length == 1) {
        // 单个转发
        final conversationId = _selectedConversationIds.first;
        final result = await messageViewModel.forwardMessage(
          messageToForward: widget.messageToForward,
          receiverId: '', // 需要根据会话类型确定接收者ID
          conversationId: conversationId,
        );
        
        result.when(
          success: (_) {
            _showSuccessMessage('消息转发成功');
            Navigator.pop(context);
          },
          error: (error) {
            _showErrorMessage('转发失败: $error');
          },
        );
      } else {
        // 批量转发
        final result = await messageViewModel.forwardMessageToMultiple(
          messageToForward: widget.messageToForward,
          conversationIds: _selectedConversationIds.toList(),
        );
        
        result.when(
          success: (forwardedMessages) {
            _showSuccessMessage('消息已转发到 ${forwardedMessages.length} 个聊天');
            Navigator.pop(context);
          },
          error: (error) {
            _showErrorMessage('转发失败: $error');
          },
        );
      }
    } finally {
      setState(() {
        _isForwarding = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}