import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/models/message_model.dart';
import 'quoted_message_widget.dart';

/// 增强的聊天输入组件
/// 
/// 支持文本、图片、语音输入，以及引用回复功能
class EnhancedChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String, MessageModel) onSendReply;
  final Function(String) onSendImage;
  final Function(String, int) onSendVoice;
  final MessageModel? replyToMessage;
  final VoidCallback? onCancelReply;
  final String? placeholder;
  final bool enabled;

  const EnhancedChatInput({
    Key? key,
    required this.onSendText,
    required this.onSendReply,
    required this.onSendImage,
    required this.onSendVoice,
    this.replyToMessage,
    this.onCancelReply,
    this.placeholder,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _showAttachmentMenu = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 引用消息预览
        if (widget.replyToMessage != null)
          _buildReplyPreview(),
        
        // 输入区域
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // 附件按钮
                IconButton(
                  icon: Icon(
                    _showAttachmentMenu ? Icons.close : Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: widget.enabled ? _toggleAttachmentMenu : null,
                ),
                
                // 文本输入框
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: widget.placeholder ?? '输入消息...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 语音/发送按钮
                if (_textController.text.trim().isEmpty)
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording 
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: widget.enabled ? _handleVoiceButton : null,
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: widget.enabled ? _sendMessage : null,
                  ),
              ],
            ),
          ),
        ),
        
        // 附件菜单
        if (_showAttachmentMenu)
          _buildAttachmentMenu(),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final replyMessage = widget.replyToMessage!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '回复消息',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  QuotedMessageWidget(
                    quotedMessage: replyMessage,
                    isCompact: true,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onCancelReply,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.photo_camera,
            label: '拍照',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          _buildAttachmentOption(
            icon: Icons.photo_library,
            label: '相册',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          _buildAttachmentOption(
            icon: Icons.attach_file,
            label: '文件',
            onTap: _pickFile,
          ),
          _buildAttachmentOption(
            icon: Icons.location_on,
            label: '位置',
            onTap: _shareLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() {
          _showAttachmentMenu = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (widget.replyToMessage != null) {
      widget.onSendReply(text, widget.replyToMessage!);
    } else {
      widget.onSendText(text);
    }

    _textController.clear();
    setState(() {});
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
  }

  void _handleVoiceButton() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    // TODO: 实现语音录制功能
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: 实现停止录制并发送语音消息
    // widget.onSendVoice(voicePath, duration);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        widget.onSendImage(image.path);
      }
    } catch (e) {
      // 处理错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  void _pickFile() {
    // TODO: 实现文件选择功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件选择功能尚未实现')),
    );
  }

  void _shareLocation() {
    // TODO: 实现位置分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('位置分享功能尚未实现')),
    );
  }
}