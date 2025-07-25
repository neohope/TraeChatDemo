import 'package:flutter/material.dart';
import '../../../domain/models/message_model.dart';
import '../../../utils/date_formatter.dart';

/// 撤回消息显示组件
class RecalledMessageWidget extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final bool showAvatar;
  final bool showTimestamp;

  const RecalledMessageWidget({
    Key? key,
    required this.message,
    required this.currentUserId,
    this.showAvatar = true,
    this.showTimestamp = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;
    final theme = Theme.of(context);
    
    return Padding(
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
                // 撤回消息容器
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.undo,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isMe ? '你撤回了一条消息' : '${_getSenderName()}撤回了一条消息',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 时间戳
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormatter.formatMessageTime(message.recalledAt ?? message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 11,
                      ),
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

  String _getSenderName() {
    // TODO: 从用户服务获取发送者姓名
    // 这里暂时返回发送者ID的前几位作为显示名称
    if (message.senderId.length > 8) {
      return message.senderId.substring(0, 8);
    }
    return message.senderId;
  }
}