import 'package:flutter/material.dart';
import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../utils/date_formatter.dart';
import 'quoted_message_widget.dart';
import 'message_action_menu.dart';

/// 支持引用回复的消息气泡组件
class ReplyMessageBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onRecall;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final Function(MessageModel)? onQuotedMessageTap;

  const ReplyMessageBubble({
    Key? key,
    required this.message,
    required this.currentUserId,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onRecall,
    this.onEdit,
    this.onCopy,
    this.onQuotedMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 发送者头像（左侧，非自己的消息）
            if (!isMe && showAvatar)
              _buildAvatar(context),
            
            if (!isMe && showAvatar)
              const SizedBox(width: 8),
            
            // 消息内容
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 消息气泡
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 引用消息
                        if (message.isReply && message.replyToMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: QuotedMessageWidget(
                              quotedMessage: message.replyToMessage!,
                              isCompact: true,
                              onTap: () => onQuotedMessageTap?.call(message.replyToMessage!),
                            ),
                          ),
                        
                        // 消息内容
                        _buildMessageContent(context, isMe),
                      ],
                    ),
                  ),
                  
                  // 时间戳和状态
                  if (showTimestamp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormatter.formatMessageTime(message.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildMessageStatus(context),
                          ]
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            if (isMe && showAvatar)
              const SizedBox(width: 8),
            
            // 发送者头像（右侧，自己的消息）
            if (isMe && showAvatar)
              _buildAvatar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isMe) {
    final theme = Theme.of(context);
    final textColor = isMe 
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
          ),
        );
        
      case MessageType.image:
        return _buildImageContent(context);
        
      case MessageType.voice:
        return _buildVoiceContent(context, textColor);
        
      case MessageType.video:
        return _buildVideoContent(context, textColor);
        
      case MessageType.file:
        return _buildFileContent(context, textColor);
        
      case MessageType.location:
        return _buildLocationContent(context, textColor);
        
      case MessageType.system:
        return Text(
          message.text ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        );
        
      default:
        return Text(
          message.text ?? '[消息]',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
          ),
        );
    }
  }

  Widget _buildImageContent(BuildContext context) {
    if (message.mediaUrl == null) {
      return const Text('[图片]');
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        message.mediaUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceContent(BuildContext context, Color textColor) {
    final duration = message.metadata?['duration'] as int? ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_arrow,
          color: textColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(duration),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context, Color textColor) {
    final duration = message.metadata?['duration'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.metadata?['thumbnail'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Image.network(
                  message.metadata!['thumbnail'],
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam,
              color: textColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, Color textColor) {
    final fileName = message.metadata?['fileName'] as String? ?? '未知文件';
    final fileSize = message.metadata?['fileSize'] as int? ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          color: textColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatFileSize(fileSize),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationContent(BuildContext context, Color textColor) {
    final address = message.metadata?['address'] as String? ?? '位置信息';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          color: textColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        _getSenderName().isNotEmpty ? _getSenderName()[0].toUpperCase() : '?',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageStatus(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        );
        
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        );
        
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        );
        
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: theme.colorScheme.primary,
        );
        
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: theme.colorScheme.error,
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  void _showMessageActions(BuildContext context) {
    MessageActionMenu.show(
      context,
      message: message,
      currentUserId: currentUserId,
      onReply: onReply,
      onForward: onForward,
      onDelete: onDelete,
      onRecall: onRecall,
      onEdit: onEdit,
      onCopy: onCopy,
    );
  }

  String _getSenderName() {
    // TODO: 从用户服务获取发送者姓名
    // 这里暂时返回发送者ID的前几位作为显示名称
    if (message.senderId.length > 8) {
      return message.senderId.substring(0, 8);
    }
    return message.senderId;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}