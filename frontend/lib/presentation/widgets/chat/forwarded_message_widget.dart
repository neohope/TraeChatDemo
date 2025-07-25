import 'package:flutter/material.dart';
import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../utils/date_formatter.dart';

/// 转发消息显示组件
class ForwardedMessageWidget extends StatelessWidget {
  final MessageModel forwardedMessage;
  final bool isCompact;
  final VoidCallback? onTap;

  const ForwardedMessageWidget({
    Key? key,
    required this.forwardedMessage,
    this.isCompact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 转发标识
            Row(
              children: [
                Icon(
                  Icons.forward,
                  size: isCompact ? 14 : 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '转发消息',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ],
            ),
            
            if (!isCompact) const SizedBox(height: 8),
            
            // 原始消息内容
            _buildOriginalMessageContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalMessageContent(BuildContext context) {
    final originalMessage = forwardedMessage.forwardFromMessage;
    if (originalMessage == null) {
      return Text(
        '[转发消息]',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final theme = Theme.of(context);
    
    switch (originalMessage.type) {
      case MessageType.text:
        return _buildTextContent(context, originalMessage);
      case MessageType.image:
        return _buildImageContent(context, originalMessage);
      case MessageType.voice:
        return _buildVoiceContent(context, originalMessage);
      case MessageType.video:
        return _buildVideoContent(context, originalMessage);
      case MessageType.file:
        return _buildFileContent(context, originalMessage);
      case MessageType.location:
        return _buildLocationContent(context, originalMessage);
      case MessageType.system:
        return _buildSystemContent(context, originalMessage);
      case MessageType.recalled:
        return Text(
          '[已撤回的消息]',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );
      default:
        return Text(
          '[未知消息类型]',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildTextContent(BuildContext context, MessageModel message) {
    return Text(
      message.text ?? '',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: isCompact ? 13 : 14,
      ),
      maxLines: isCompact ? 2 : null,
      overflow: isCompact ? TextOverflow.ellipsis : null,
    );
  }

  Widget _buildImageContent(BuildContext context, MessageModel message) {
    return Row(
      children: [
        Icon(
          Icons.image,
          size: isCompact ? 16 : 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[图片]',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isCompact ? 13 : 14,
                ),
              ),
              if (!isCompact && message.mediaUrl != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(message.mediaUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceContent(BuildContext context, MessageModel message) {
    final duration = message.metadata?['duration'] as int? ?? 0;
    
    return Row(
      children: [
        Icon(
          Icons.mic,
          size: isCompact ? 16 : 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '[语音] ${_formatDuration(duration)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isCompact ? 13 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context, MessageModel message) {
    final duration = message.metadata?['duration'] as int? ?? 0;
    
    return Row(
      children: [
        Icon(
          Icons.videocam,
          size: isCompact ? 16 : 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '[视频] ${_formatDuration(duration)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isCompact ? 13 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, MessageModel message) {
    final fileName = message.metadata?['fileName'] as String? ?? '未知文件';
    final fileSize = message.metadata?['fileSize'] as int? ?? 0;
    
    return Row(
      children: [
        Icon(
          Icons.attach_file,
          size: isCompact ? 16 : 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isCompact ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isCompact)
                Text(
                  _formatFileSize(fileSize),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationContent(BuildContext context, MessageModel message) {
    final address = message.metadata?['address'] as String? ?? '位置信息';
    
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: isCompact ? 16 : 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isCompact ? 13 : 14,
            ),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemContent(BuildContext context, MessageModel message) {
    return Text(
      message.text ?? '[系统消息]',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: isCompact ? 13 : 14,
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
      maxLines: isCompact ? 2 : null,
      overflow: isCompact ? TextOverflow.ellipsis : null,
    );
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