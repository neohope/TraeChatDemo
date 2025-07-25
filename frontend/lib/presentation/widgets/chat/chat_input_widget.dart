import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/voice_message_viewmodel.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../data/services/file_service.dart';


/// 聊天输入组件
class ChatInputWidget extends StatefulWidget {
  final Function(String text, MessageType type)? onSendText;
  final Function(String voicePath, int duration)? onSendVoice;
  final Function(String filePath, String fileName, String fileType)? onSendFile;
  final String? replyToMessageId;
  final String? replyToMessageText;
  final VoidCallback? onCancelReply;
  final bool isEnabled;

  const ChatInputWidget({
    Key? key,
    this.onSendText,
    this.onSendVoice,
    this.onSendFile,
    this.replyToMessageId,
    this.replyToMessageText,
    this.onCancelReply,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _expandController;
  
  bool _isExpanded = false;
  bool _isRecordingVoice = false;
  bool _showEmojiPicker = false;
  String _inputText = '';

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _textController.addListener(() {
      setState(() {
        _inputText = _textController.text;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyToMessageId != null) _buildReplyPreview(),
          if (_isRecordingVoice) _buildVoiceRecorder(),
          _buildMainInput(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded ? _buildExpandedOptions() : const SizedBox.shrink(),
          ),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            color: Theme.of(context).primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '回复消息',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyToMessageText ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecorder() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: VoiceRecorderWidget(
        onRecordComplete: (voicePath, duration) {
          setState(() {
            _isRecordingVoice = false;
          });
          widget.onSendVoice?.call(voicePath, duration);
        },
        onCancel: () {
          setState(() {
            _isRecordingVoice = false;
          });
        },
        isEnabled: widget.isEnabled,
      ),
    );
  }

  Widget _buildMainInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 展开/收起按钮
          IconButton(
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.add),
            ),
            onPressed: _toggleExpanded,
            color: Theme.of(context).primaryColor,
          ),
          // 文本输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // 表情按钮
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                      color: Colors.grey[600],
                    ),
                    onPressed: _toggleEmojiPicker,
                  ),
                  // 文本输入
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: widget.isEnabled && !_isRecordingVoice,
                      maxLines: 4,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _inputText.trim().isNotEmpty ? (_) => _sendTextMessage() : null,
                    ),
                  ),
                  // 附件按钮
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: Colors.grey[600],
                    ),
                    onPressed: widget.isEnabled ? _showAttachmentOptions : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 发送/语音按钮
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _inputText.trim().isNotEmpty;
    
    return GestureDetector(
      onTap: hasText ? _sendTextMessage : null,
      onLongPress: !hasText && widget.isEnabled ? _startVoiceRecording : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasText || widget.isEnabled
              ? Theme.of(context).primaryColor
              : Colors.grey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          hasText ? Icons.send : Icons.mic,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildExpandedOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
        children: [
          _buildOptionItem(
            icon: Icons.photo_camera,
            label: '拍照',
            color: Colors.blue,
            onTap: _takePhoto,
          ),
          _buildOptionItem(
            icon: Icons.photo_library,
            label: '相册',
            color: Colors.green,
            onTap: _pickImage,
          ),
          _buildOptionItem(
            icon: Icons.videocam,
            label: '录像',
            color: Colors.red,
            onTap: _recordVideo,
          ),
          _buildOptionItem(
            icon: Icons.insert_drive_file,
            label: '文件',
            color: Colors.orange,
            onTap: _pickFile,
          ),
          _buildOptionItem(
            icon: Icons.location_on,
            label: '位置',
            color: Colors.purple,
            onTap: _shareLocation,
          ),
          _buildOptionItem(
            icon: Icons.contact_phone,
            label: '联系人',
            color: Colors.teal,
            onTap: _shareContact,
          ),
          _buildOptionItem(
            icon: Icons.mic,
            label: '语音',
            color: Colors.indigo,
            onTap: _startVoiceRecording,
          ),
          _buildOptionItem(
            icon: Icons.gif_box,
            label: 'GIF',
            color: Colors.pink,
            onTap: _pickGif,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: widget.isEnabled ? onTap : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    // 简单的表情选择器，实际项目中可以使用 emoji_picker_flutter 包
    final emojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
      '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
      '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜',
      '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏',
      '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
      '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠',
      '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨',
      '😰', '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥',
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _insertEmoji(emojis[index]),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  emojis[index],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expandController.forward();
      _focusNode.unfocus();
      setState(() {
        _showEmojiPicker = false;
      });
    } else {
      _expandController.reverse();
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
    
    if (_showEmojiPicker) {
      _focusNode.unfocus();
      setState(() {
        _isExpanded = false;
      });
      _expandController.reverse();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSendText?.call(text, MessageType.text);
      _textController.clear();
      setState(() {
        _inputText = '';
        _showEmojiPicker = false;
        _isExpanded = false;
      });
      _expandController.reverse();
    }
  }

  void _startVoiceRecording() {
    if (!widget.isEnabled) return;
    
    setState(() {
      _isRecordingVoice = true;
      _isExpanded = false;
      _showEmojiPicker = false;
    });
    _expandController.reverse();
    _focusNode.unfocus();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择附件类型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                _buildOptionItem(
                  icon: Icons.photo_camera,
                  label: '拍照',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _buildOptionItem(
                  icon: Icons.photo_library,
                  label: '相册',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildOptionItem(
                  icon: Icons.insert_drive_file,
                  label: '文件',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _takePhoto() async {
    try {
      final fileService = FileService();
      final result = await fileService.takePhoto();
      if (result != null) {
        final fileName = result.name;
        widget.onSendFile?.call(result.path, fileName, 'image');
      }
    } catch (e) {
      _showError('拍照失败: $e');
    }
  }

  void _pickImage() async {
    try {
      final fileService = FileService();
      final result = await fileService.pickImages();
      if (result.isNotEmpty) {
        final file = result.first;
        final fileName = file.name;
        widget.onSendFile?.call(file.path, fileName, 'image');
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }

  void _recordVideo() async {
    try {
      final fileService = FileService();
      final result = await fileService.recordVideo();
      if (result != null) {
        final fileName = result.name;
        widget.onSendFile?.call(result.path, fileName, 'video');
      }
    } catch (e) {
      _showError('录制视频失败: $e');
    }
  }

  void _pickFile() async {
    try {
      final fileService = FileService();
      final result = await fileService.pickFiles();
      if (result.isNotEmpty) {
        final file = result.first;
        final fileName = file.name;
        final fileType = file.type.name;
        widget.onSendFile?.call(file.path, fileName, fileType);
      }
    } catch (e) {
      _showError('选择文件失败: $e');
    }
  }

  void _shareLocation() {
    _showLocationDialog();
  }

  void _shareContact() {
    _showContactDialog();
  }

  void _pickGif() {
    _showGifPicker();
  }
  
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享位置'),
        content: const Text('确定要分享当前位置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendLocationMessage();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _sendLocationMessage() {
    // 模拟位置数据
    const double latitude = 39.9042;
    const double longitude = 116.4074;
    const String address = '北京市朝阳区';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('位置已发送: $address'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: 调用发送位置消息的回调
    // widget.onSendLocation?.call(latitude, longitude, address);
  }
  
  void _showContactDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择联系人',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _mockContacts.length,
                itemBuilder: (context, index) {
                  final contact = _mockContacts[index];
                   return ListTile(
                     leading: CircleAvatar(
                       child: Text(contact['name']?[0] ?? ''),
                     ),
                     title: Text(contact['name'] ?? ''),
                     subtitle: Text(contact['phone'] ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      _sendContactMessage(contact);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _sendContactMessage(Map<String, String> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('联系人已发送: ${contact['name'] ?? ''}'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: 调用发送联系人消息的回调
    // widget.onSendContact?.call(contact);
  }
  
  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择GIF',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _mockGifs.length,
                itemBuilder: (context, index) {
                  final gif = _mockGifs[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _sendGifMessage(gif);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: Text(
                          gif['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _sendGifMessage(Map<String, String> gif) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('GIF已发送: ${gif['name'] ?? ''}'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: 调用发送GIF消息的回调
     // widget.onSendGif?.call(gif['url']!);
   }
   
   static const List<Map<String, String>> _mockContacts = [
     {'name': '张三', 'phone': '13800138001'},
     {'name': '李四', 'phone': '13800138002'},
     {'name': '王五', 'phone': '13800138003'},
     {'name': '赵六', 'phone': '13800138004'},
   ];
   
   static const List<Map<String, String>> _mockGifs = [
     {'name': '开心', 'url': 'https://example.com/happy.gif'},
     {'name': '哭泣', 'url': 'https://example.com/cry.gif'},
     {'name': '惊讶', 'url': 'https://example.com/surprise.gif'},
     {'name': '愤怒', 'url': 'https://example.com/angry.gif'},
     {'name': '点赞', 'url': 'https://example.com/thumbsup.gif'},
     {'name': '鼓掌', 'url': 'https://example.com/clap.gif'},
   ];

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
}

/// 语音消息录制组件
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String voicePath, int duration)? onRecordComplete;
  final VoidCallback? onCancel;
  final bool isEnabled;

  const VoiceRecorderWidget({
    Key? key,
    this.onRecordComplete,
    this.onCancel,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  Timer? _durationTimer;
  bool _isRecording = false;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // 自动开始录制
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecording();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceMessageViewModel>(builder: (context, viewModel, child) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRecordingIndicator(),
            const SizedBox(height: 16),
            _buildDurationDisplay(),
            const SizedBox(height: 24),
            _buildRecordingControls(viewModel),
          ],
        ),
      );
    });
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurationDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(VoiceMessageViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 取消按钮
        GestureDetector(
          onTap: () => _cancelRecording(viewModel),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ),
        // 停止并发送按钮
        GestureDetector(
          onTap: () => _stopRecording(viewModel),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        // 暂停/恢复按钮
        GestureDetector(
          onTap: () => _togglePauseRecording(viewModel),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.2),
            ),
            child: Icon(
              viewModel.isRecordingPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.orange,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  void _startRecording() async {
    if (!widget.isEnabled || _isRecording) return;

    try {
      final viewModel = context.read<VoiceMessageViewModel>();
      await viewModel.startRecording();
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _pulseController.repeat(reverse: true);
      _scaleController.forward();

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration++;
          });
        }
      });
    } catch (e) {
      _showError('录音失败: $e');
    }
  }

  void _stopRecording(VoiceMessageViewModel viewModel) async {
    if (!_isRecording) return;

    try {
      final duration = viewModel.recordingDuration;
      final result = await viewModel.stopRecording();
      _resetRecordingState();

      if (result != null && widget.onRecordComplete != null) {
        widget.onRecordComplete!(result, duration.inSeconds);
      }
    } catch (e) {
      _showError('停止录音失败: $e');
      _resetRecordingState();
    }
  }

  void _cancelRecording(VoiceMessageViewModel viewModel) async {
    if (!_isRecording) return;

    try {
      await viewModel.cancelRecording();
      _resetRecordingState();
      widget.onCancel?.call();
    } catch (e) {
      _showError('取消录音失败: $e');
      _resetRecordingState();
    }
  }

  void _togglePauseRecording(VoiceMessageViewModel viewModel) async {
    if (!_isRecording) return;

    try {
      if (viewModel.isRecordingPaused) {
        await viewModel.resumeRecording();
        _pulseController.repeat(reverse: true);
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });
      } else {
        await viewModel.pauseRecording();
        _pulseController.stop();
        _durationTimer?.cancel();
      }
    } catch (e) {
      _showError('暂停/恢复录音失败: $e');
    }
  }

  void _resetRecordingState() {
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
    _pulseController.stop();
    _pulseController.reset();
    _scaleController.reverse();
    _durationTimer?.cancel();
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