import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/conversation_model.dart';
import '../../themes/app_theme.dart';

/// 会话列表项组件
/// 
/// 用于显示聊天列表中的会话项，包括头像、名称、最后消息、时间、未读消息数等
class ConversationListItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const ConversationListItem({
    Key? key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingNormal,
          vertical: AppTheme.spacingSmall,
        ),
        child: Row(
          children: [
            // 会话头像
            _buildAvatar(context),
            const SizedBox(width: AppTheme.spacingNormal),
            
            // 会话信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称和时间
                  Row(
                    children: [
                      // 会话名称
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // 最后消息时间
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 最后消息和未读数
                  Row(
                    children: [
                      // 静音图标
                      if (conversation.isMuted) ...[  
                        Icon(
                          Icons.volume_off,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                      ],
                      
                      // 最后消息内容
                      Expanded(
                        child: Text(
                          _getLastMessagePreview(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: conversation.unreadCount > 0
                                ? theme.textTheme.bodyMedium?.color
                                : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(width: AppTheme.spacingSmall),
                      
                      // 未读消息数
                      if (conversation.unreadCount > 0) ...[  
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          alignment: Alignment.center,
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建头像
  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        // 头像
        CircleAvatar(
          radius: AppTheme.avatarSizeMedium / 2,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: conversation.avatarUrl != null
              ? NetworkImage(conversation.avatarUrl!)
              : null,
          child: conversation.avatarUrl == null
              ? Icon(
                  conversation.isGroup ? Icons.group : Icons.person,
                  size: AppTheme.avatarSizeMedium / 2,
                  color: Theme.of(context).primaryColor,
                )
              : null,
        ),
        
        // 在线状态指示器
        if (!conversation.isGroup && conversation.isOnline) ...[  
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.getStatusColor(UserStatus.online),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
        
        // 置顶标记
        if (conversation.isPinned) ...[  
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  // 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      // 今天，显示时间
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      // 昨天，显示"昨天"
      return '昨天';
    } else if (now.difference(time).inDays < 7) {
      // 一周内，显示星期
      return DateFormat('EEEE', 'zh_CN').format(time);
    } else {
      // 超过一周，显示日期
      return DateFormat('MM-dd').format(time);
    }
  }
  
  // 获取最后消息预览
  String _getLastMessagePreview() {
    if (conversation.lastMessage == null || conversation.lastMessage!.isEmpty) {
      return '';
    }
    
    // 根据消息类型生成预览
    switch (conversation.lastMessageType) {
      case MessageType.text:
        return conversation.lastMessage!;
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
        return conversation.lastMessage!;
      default:
        return conversation.lastMessage!;
    }
  }
}

// 使用 domain/models/conversation_model.dart 中定义的枚举
// 已在文件顶部导入