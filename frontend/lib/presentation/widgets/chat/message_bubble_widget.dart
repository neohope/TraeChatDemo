import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math';

import '../../../domain/models/message_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/conversation_model.dart';
import '../../viewmodels/voice_message_viewmodel.dart';
import '../../../core/utils/file_utils.dart';

/// 消息气泡组件
class MessageBubbleWidget extends StatefulWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isFromCurrentUser;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(MessageModel)? onReply;
  final Function(MessageModel)? onForward;
  final Function(MessageModel)? onDelete;
  final Function(MessageModel)? onEdit;
  final bool isSelected;

  const MessageBubbleWidget({
    Key? key,
    required this.message,
    this.sender,
    required this.isFromCurrentUser,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.onTap,
    this.onLongPress,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onEdit,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<MessageBubbleWidget> createState() => _MessageBubbleWidgetState();
}

class _MessageBubbleWidgetState extends State<MessageBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(
              left: widget.isFromCurrentUser ? 64 : 8,
              right: widget.isFromCurrentUser ? 8 : 64,
              bottom: 4,
            ),
            child: Row(
              mainAxisAlignment: widget.isFromCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isFromCurrentUser && widget.showAvatar)
                  _buildAvatar(),
                if (!widget.isFromCurrentUser && widget.showAvatar)
                  const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showMessageOptions();
                    },
                    onTapDown: (_) {
                      setState(() {
                      });
                      _animationController.forward();
                    },
                    onTapUp: (_) {
                      setState(() {
                      });
                      _animationController.reverse();
                    },
                    onTapCancel: () {
                      setState(() {
                      });
                      _animationController.reverse();
                    },
                    child: Column(
                      crossAxisAlignment: widget.isFromCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!widget.isFromCurrentUser && widget.sender != null)
                          _buildSenderName(),
                        _buildMessageBubble(),
                        if (widget.showTimestamp) _buildTimestamp(),
                      ],
                    ),
                  ),
                ),
                if (widget.isFromCurrentUser && widget.showAvatar)
                  const SizedBox(width: 8),
                if (widget.isFromCurrentUser && widget.showAvatar)
                  _buildAvatar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: widget.sender?.avatarUrl != null
          ? NetworkImage(widget.sender!.avatarUrl!)
          : null,
      child: widget.sender?.avatarUrl == null
          ? Text(
              widget.sender?.nickname?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        widget.sender?.nickname ?? 'Unknown',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
            : _getBubbleColor(),
        borderRadius: _getBubbleBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply functionality not implemented in current MessageModel
          _buildMessageContent(),
          _buildMessageStatus(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '回复消息',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
             'Reply message content not available',
              style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.voice:
        return _buildVoiceContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.file:
        return _buildFileContent();
      case MessageType.location:
        return _buildLocationContent();
      case MessageType.system:
        return _buildSystemContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SelectableText(
        widget.message.text ?? '',
        style: TextStyle(
          fontSize: 16,
          color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
        maxHeight: 300,
      ),
      child: ClipRRect(
        borderRadius: _getBubbleBorderRadius(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showImageViewer(),
              child: widget.message.mediaUrl != null && widget.message.mediaUrl!.startsWith('file://')
                  ? Image.file(
                      File(widget.message.mediaUrl!.replaceFirst('file://', '')),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : widget.message.mediaUrl != null
                      ? Image.network(
                          widget.message.mediaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildImagePlaceholder(
                              progress: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        )
                      : _buildImagePlaceholder(),
            ),
            if (widget.message.text != null && widget.message.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  widget.message.text!,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({double? progress}) {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: Colors.grey[600],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[400],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceContent() {
    final voicePath = widget.message.mediaUrl;
    if (voicePath == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: widget.isFromCurrentUser ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '语音消息',
              style: TextStyle(
                color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return VoicePlayerWidget(
      voicePath: voicePath,
      duration: (widget.message.metadata?['duration'] as int?) ?? 0,
      isFromCurrentUser: widget.isFromCurrentUser,
    );
  }

  Widget _buildVideoContent() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
        maxHeight: 200,
      ),
      child: ClipRRect(
        borderRadius: _getBubbleBorderRadius(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 250,
              height: 150,
              color: Colors.black,
              child: widget.message.metadata?['thumbnail'] != null
                  ? Image.network(
                      widget.message.metadata!['thumbnail'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildVideoPlaceholder();
                      },
                    )
                  : _buildVideoPlaceholder(),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
            if (widget.message.metadata?['duration'] != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(widget.message.metadata!['duration'] as int),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.videocam,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFileContent() {
    final fileName = (widget.message.metadata?['fileName'] as String?) ?? '未知文件';
    final fileSize = widget.message.metadata?['fileSize'] as int?;
    final fileType = FileUtils.getFileExtension(fileName).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileType),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(fileType),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize != null)
                  Text(
                    FileUtils.formatFileSize(fileSize),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isFromCurrentUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.download,
            color: widget.isFromCurrentUser
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
        maxHeight: 150,
      ),
      child: ClipRRect(
        borderRadius: _getBubbleBorderRadius(),
        child: Column(
          children: [
            Container(
              height: 100,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.message.text?.isNotEmpty == true
                    ? widget.message.text!
                    : '位置信息',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        widget.message.text ?? '',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!widget.isFromCurrentUser) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message.isEdited)
            Text(
              '已编辑',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          if (widget.message.isEdited) const SizedBox(width: 4),
          Icon(
            _getStatusIcon(),
            size: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        _formatTimestamp(widget.message.timestamp),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Color _getBubbleColor() {
    if (widget.message.type == MessageType.system) {
      return Colors.grey.withValues(alpha: 0.2);
    }
    return widget.isFromCurrentUser
        ? Theme.of(context).primaryColor
        : Colors.grey[200]!;
  }

  BorderRadius _getBubbleBorderRadius() {
    const radius = Radius.circular(16);
    if (widget.message.type == MessageType.system) {
      return BorderRadius.circular(12);
    }
    return widget.isFromCurrentUser
        ? const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: Radius.circular(4),
            bottomRight: radius,
          );
  }

  IconData _getStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
      default:
        return Icons.check;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String fileType) {
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
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('回复'),
              onTap: () {
                Navigator.pop(context);
                widget.onReply?.call(widget.message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('转发'),
              onTap: () {
                Navigator.pop(context);
                widget.onForward?.call(widget.message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage();
              },
            ),
            if (widget.isFromCurrentUser && widget.message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit?.call(widget.message);
                },
              ),
            if (widget.isFromCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _copyMessage() {
    String textToCopy = '';
    switch (widget.message.type) {
      case MessageType.text:
        textToCopy = widget.message.text ?? '';
        break;
      case MessageType.file:
        textToCopy = (widget.message.metadata?['fileName'] as String?) ?? '';
        break;
      default:
        textToCopy = widget.message.text ?? '';
        break;
    }
    
    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  void _showDeleteConfirmDialog() {
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
              widget.onDelete?.call(widget.message);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showImageViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: widget.message.mediaUrl,
          localPath: null,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// 语音播放器组件
class VoicePlayerWidget extends StatefulWidget {
  final String voicePath;
  final int duration;
  final bool isFromCurrentUser;
  final VoidCallback? onPlayComplete;

  const VoicePlayerWidget({
    Key? key,
    required this.voicePath,
    required this.duration,
    this.isFromCurrentUser = false,
    this.onPlayComplete,
  }) : super(key: key);

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  bool _isCurrentlyPlaying = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceMessageViewModel>(builder: (context, viewModel, child) {
      final isPlaying = viewModel.isPlaying;
      final isPaused = false; // Simplified for now
      final progress = 0.0; // Simplified for now
      final currentPosition = 0; // Simplified for now

      if (isPlaying && !_isCurrentlyPlaying) {
        _isCurrentlyPlaying = true;
        _waveController.repeat();
      } else if (!isPlaying && _isCurrentlyPlaying) {
        _isCurrentlyPlaying = false;
        _waveController.stop();
        _waveController.reset();
      }

      return Container(
        constraints: const BoxConstraints(
          minWidth: 200,
          maxWidth: 280,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildPlayButton(viewModel, isPlaying, isPaused),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWaveform(isPlaying, progress),
                  const SizedBox(height: 8),
                  _buildTimeInfo(currentPosition, widget.duration),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlayButton(VoiceMessageViewModel viewModel, bool isPlaying, bool isPaused) {
    IconData icon;
    Color color;
    VoidCallback? onPressed;

    if (isPlaying && !isPaused) {
      icon = Icons.pause;
      color = Colors.orange;
      onPressed = () {}; // Pause functionality not available
    } else if (isPaused) {
      icon = Icons.play_arrow;
      color = Colors.green;
      onPressed = () {}; // Resume functionality not available
    } else {
      icon = Icons.play_arrow;
      color = widget.isFromCurrentUser ? Colors.white : Theme.of(context).primaryColor;
      onPressed = () => _startPlayback(viewModel);
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildWaveform(bool isPlaying, double progress) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 20,
          child: Row(
            children: List.generate(15, (index) {
              final height = _getWaveHeight(index, isPlaying, progress);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: height,
                  decoration: BoxDecoration(
                    color: _getWaveColor(index, progress),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildTimeInfo(int currentPosition, int totalDuration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(currentPosition),
          style: TextStyle(
            fontSize: 10,
            color: widget.isFromCurrentUser
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.grey[600],
          ),
        ),
        Text(
          _formatDuration(totalDuration),
          style: TextStyle(
            fontSize: 10,
            color: widget.isFromCurrentUser
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _getWaveHeight(int index, bool isPlaying, double progress) {
    if (!isPlaying) {
      // 静态波形
      final heights = [6.0, 8.0, 12.0, 7.0, 10.0, 14.0, 8.0, 6.0, 12.0, 16.0,
                     10.0, 7.0, 14.0, 8.0, 6.0];
      return heights[index % heights.length];
    }

    // 动态波形
    final baseHeight = 4.0;
    final maxHeight = 16.0;
    final animationOffset = _waveAnimation.value * 2 * 3.14159;
    final waveHeight = baseHeight + (maxHeight - baseHeight) * 
        (0.5 + 0.5 * sin(animationOffset + index * 0.5));
    
    // 根据播放进度调整颜色
    final progressIndex = (progress * 15).floor();
    if (index <= progressIndex) {
      return waveHeight;
    } else {
      return baseHeight + (waveHeight - baseHeight) * 0.3;
    }
  }

  Color _getWaveColor(int index, double progress) {
    final progressIndex = (progress * 15).floor();
    if (index <= progressIndex) {
      return widget.isFromCurrentUser ? Colors.white : Theme.of(context).primaryColor;
    } else {
      return widget.isFromCurrentUser
          ? Colors.white.withValues(alpha: 0.5)
          : Colors.grey.withValues(alpha: 0.5);
    }
  }

  void _startPlayback(VoiceMessageViewModel viewModel) async {
    try {
      // Start playback functionality not available
      _showError('语音播放功能暂不可用');
      // 监听播放完成
      viewModel.addListener(_onPlaybackStateChanged);
    } catch (e) {
      _showError('播放失败: $e');
    }
  }

  void _onPlaybackStateChanged() {
    final viewModel = context.read<VoiceMessageViewModel>();
    if (!viewModel.isPlaying) {
      // 播放完成
      widget.onPlayComplete?.call();
      viewModel.removeListener(_onPlaybackStateChanged);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// 图片查看器
class ImageViewerScreen extends StatelessWidget {
  final String? imageUrl;
  final String? localPath;

  const ImageViewerScreen({
    Key? key,
    this.imageUrl,
    this.localPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: localPath != null && File(localPath!).existsSync()
              ? Image.file(File(localPath!))
              : imageUrl != null
                  ? Image.network(imageUrl!)
                  : const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 64,
                    ),
        ),
      ),
    );
  }
}