import 'package:flutter/material.dart';

import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/message_model.dart';
import '../../../utils/date_formatter.dart';

/// 消息气泡组件
/// 
/// 用于在聊天界面显示消息，支持文本、图片、语音等多种类型
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final Function(MessageModel)? onTap;
  final String? senderName;
  final bool showSenderName;
  final bool showStatus;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onTap,
    this.senderName,
    this.showSenderName = false,
    this.showStatus = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 发送者名称（如果需要显示）
          if (showSenderName && !isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
              child: Text(
                senderName!,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          
          // 消息内容
          GestureDetector(
            onLongPress: onLongPress,
            onTap: onTap != null ? () => onTap!(message) : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: _getBubbleColor(context),
                borderRadius: _getBubbleBorderRadius(),
              ),
              padding: _getBubblePadding(),
              child: _buildMessageContent(context),
            ),
          ),
          
          // 消息状态和时间
          if (showStatus)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 4.0, left: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMe) _buildMessageStatus(),
                  Text(
                    DateFormatter.formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  /// 构建消息内容
  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
        
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            message.mediaUrl ?? '',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.error),
              );
            },
          ),
        );
        
      case MessageType.voice:
        return _buildVoiceMessage(context);
        
      case MessageType.video:
        return _buildVideoMessage(context);
        
      case MessageType.file:
        return _buildFileMessage(context);
        
      case MessageType.location:
        return _buildLocationMessage(context);
        
      case MessageType.system:
        return Text(
          message.text ?? '',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        );
        
      default:
        return Text(
          '不支持的消息类型',
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
    }
  }
  
  /// 构建语音消息
  Widget _buildVoiceMessage(BuildContext context) {
    final duration = message.metadata?['duration'] as int? ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_arrow,
          color: isMe ? Colors.white : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 4.0),
        Container(
          width: duration < 10 ? 50.0 : (duration < 30 ? 100.0 : 150.0),
          height: 30.0,
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withAlpha(51) : Theme.of(context).primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          '$duration"',
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
  
  /// 构建视频消息
  Widget _buildVideoMessage(BuildContext context) {
    final thumbnailUrl = message.metadata?['thumbnail'] as String? ?? '';
    final duration = message.metadata?['duration'] as int? ?? 0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            thumbnailUrl,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.video_file),
              );
            },
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(128),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(128),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              _formatDuration(duration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建文件消息
  Widget _buildFileMessage(BuildContext context) {
    final fileName = message.metadata?['fileName'] as String? ?? 'File';
    final fileSize = message.metadata?['fileSize'] as int? ?? 0;
    final fileType = message.metadata?['fileType'] as String? ?? '';
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor.withAlpha(25) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(fileType),
            color: Theme.of(context).primaryColor,
            size: 36.0,
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    color: isMe ? Colors.white.withAlpha(179) : Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Icon(
            Icons.download,
            color: isMe ? Colors.white : Theme.of(context).primaryColor,
            size: 20.0,
          ),
        ],
      ),
    );
  }
  
  /// 构建位置消息
  Widget _buildLocationMessage(BuildContext context) {
    // 位置信息可用于在地图上显示，但当前仅显示地址
    // final latitude = message.metadata?['latitude'] as double? ?? 0.0;
    // final longitude = message.metadata?['longitude'] as double? ?? 0.0;
    final address = message.metadata?['address'] as String? ?? '位置信息';
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor.withAlpha(25) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.0),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 36.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            address,
            style: TextStyle(
              color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  /// 构建消息状态
  Widget _buildMessageStatus() {
    IconData? icon;
    Color? color;
    
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      // ignore: unreachable_switch_default
      default:
        return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Icon(
        icon,
        size: 12.0,
        color: color,
      ),
    );
  }
  
  /// 获取气泡颜色
  Color _getBubbleColor(BuildContext context) {
    if (message.type == MessageType.system) {
      return Colors.grey[300]!;
    }
    
    return isMe ? Theme.of(context).primaryColor : Colors.grey[100]!;
  }
  
  /// 获取气泡边框圆角
  BorderRadius _getBubbleBorderRadius() {
    if (message.type == MessageType.system) {
      return BorderRadius.circular(16.0);
    }
    
    const radius = Radius.circular(16.0);
    const smallRadius = Radius.circular(4.0);
    
    return isMe
        ? const BorderRadius.only(
            topLeft: radius,
            topRight: smallRadius,
            bottomLeft: radius,
            bottomRight: radius,
          )
        : const BorderRadius.only(
            topLeft: smallRadius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: radius,
          );
  }
  
  /// 获取气泡内边距
  EdgeInsets _getBubblePadding() {
    switch (message.type) {
      case MessageType.text:
      case MessageType.system:
        return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
      case MessageType.image:
      case MessageType.video:
        return EdgeInsets.zero;
      default:
        return const EdgeInsets.all(8.0);
    }
  }
  
  /// 获取文件图标
  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// 格式化视频时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}