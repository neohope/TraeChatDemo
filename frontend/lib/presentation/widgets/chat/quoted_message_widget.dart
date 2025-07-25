import 'package:flutter/material.dart';
import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../utils/date_formatter.dart';

/// 引用消息显示组件
class QuotedMessageWidget extends StatelessWidget {
  final MessageModel quotedMessage;
  final String? senderName;
  final VoidCallback? onTap;
  final bool isCompact;

  const QuotedMessageWidget({
    Key? key,
    required this.quotedMessage,
    this.senderName,
    this.onTap,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 发送者信息
            Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    senderName ?? _getSenderDisplayName(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isCompact)
                  Text(
                    DateFormatter.formatMessageTime(quotedMessage.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // 消息内容
            _buildMessageContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);
    
    if (quotedMessage.isRecalled) {
      return Row(
        children: [
          Icon(
            Icons.undo,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            '已撤回的消息',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
    
    switch (quotedMessage.type) {
      case MessageType.text:
        return Text(
          quotedMessage.text ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: isCompact ? 1 : 3,
          overflow: TextOverflow.ellipsis,
        );
        
      case MessageType.image:
        return _buildMediaContent(
          context,
          icon: Icons.image,
          label: '[图片]',
          url: quotedMessage.mediaUrl,
        );
        
      case MessageType.voice:
        return _buildMediaContent(
          context,
          icon: Icons.mic,
          label: '[语音]',
          duration: quotedMessage.metadata?['duration'],
        );
        
      case MessageType.video:
        return _buildMediaContent(
          context,
          icon: Icons.videocam,
          label: '[视频]',
          duration: quotedMessage.metadata?['duration'],
        );
        
      case MessageType.file:
        return _buildMediaContent(
          context,
          icon: Icons.attach_file,
          label: '[文件] ${quotedMessage.metadata?['fileName'] ?? ''}',
        );
        
      case MessageType.location:
        return _buildMediaContent(
          context,
          icon: Icons.location_on,
          label: '[位置] ${quotedMessage.metadata?['address'] ?? ''}',
        );
        
      case MessageType.system:
        return _buildMediaContent(
          context,
          icon: Icons.info,
          label: '[系统消息]',
        );
        
      default:
        return Text(
          '[消息]',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildMediaContent(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? url,
    int? duration,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            duration != null ? '$label ${_formatDuration(duration)}' : label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 如果是图片，显示缩略图
        if (quotedMessage.type == MessageType.image && url != null && !isCompact)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.broken_image,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  String _getSenderDisplayName() {
    // TODO: 从用户服务获取发送者姓名
    // 这里暂时返回发送者ID的前几位作为显示名称
    if (quotedMessage.senderId.length > 8) {
      return quotedMessage.senderId.substring(0, 8);
    }
    return quotedMessage.senderId;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// 引用消息输入预览组件
class QuotedMessageInputPreview extends StatelessWidget {
  final MessageModel quotedMessage;
  final String? senderName;
  final VoidCallback? onCancel;

  const QuotedMessageInputPreview({
    Key? key,
    required this.quotedMessage,
    this.senderName,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '回复 ${senderName ?? _getSenderDisplayName()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quotedMessage.getReplyPreviewText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  String _getSenderDisplayName() {
    // TODO: 从用户服务获取发送者姓名
    // 这里暂时返回发送者ID的前几位作为显示名称
    if (quotedMessage.senderId.length > 8) {
      return quotedMessage.senderId.substring(0, 8);
    }
    return quotedMessage.senderId;
  }
}