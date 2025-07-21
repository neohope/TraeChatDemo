import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../presentation/viewmodels/message_view_model.dart';

/// 消息输入框组件
/// 
/// 用于聊天页面的消息输入，支持文本、图片、语音等多种输入方式
class MessageInput extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final bool isGroup;
  
  const MessageInput({
    Key? key,
    required this.conversationId,
    required this.receiverId,
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Record _audioRecorder = Record();
  
  bool _isRecording = false;
  DateTime? _recordStartTime;
  String _recordDuration = '00:00';
  bool _showEmojiPicker = false;
  bool _showAttachmentOptions = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _stopRecording();
    _audioRecorder.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showEmojiPicker = false;
        _showAttachmentOptions = false;
      });
    }
  }
  
  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    await messageViewModel.sendTextMessage(
      text,
      widget.receiverId,
    );
    
    _textController.clear();
  }
  
  Future<void> _sendImageMessage() async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相册权限才能发送图片')),
        );
      }
      return;
    }
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (image != null) {
      final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
      await messageViewModel.sendImageMessage(
        image.path,
        widget.receiverId,
      );
    }
  }
  
  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限才能拍照')),
        );
      }
      return;
    }
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    
    if (image != null) {
      final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
      await messageViewModel.sendImageMessage(
        image.path,
        widget.receiverId,
      );
    }
  }
  
  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限才能录音')),
        );
      }
      return;
    }
    
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start();
        _recordStartTime = DateTime.now();
        
        setState(() {
          _isRecording = true;
          _recordDuration = '00:00';
        });
        
        // 更新录音时长
        _updateRecordDuration();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音失败: $e')),
        );
      }
    }
  }
  
  void _updateRecordDuration() {
    if (!_isRecording || _recordStartTime == null) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording) {
        final duration = DateTime.now().difference(_recordStartTime!);
        final minutes = (duration.inSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        setState(() {
          _recordDuration = '$minutes:$seconds';
        });
        
        _updateRecordDuration(); // 递归调用以继续更新
      }
    });
  }
  
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        final duration = DateTime.now().difference(_recordStartTime!);
        if (duration.inSeconds < 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('录音时间太短')),
            );
          }
          return;
        }
        
        final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
        await messageViewModel.sendVoiceMessage(
          path,
          duration.inSeconds,
          widget.receiverId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存录音失败: $e')),
        );
      }
    }
  }
  
  void _cancelRecording() async {
    if (!_isRecording) return;
    
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      // 忽略取消录音时的错误
    }
  }
  
  Widget _buildAttachmentOptions() {
    return Container(
      height: 200,
      color: Theme.of(context).cardColor,
      child: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(16),
        children: [
          _buildAttachmentOption(
            icon: Icons.photo,
            label: '相册',
            onTap: _sendImageMessage,
          ),
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: '拍照',
            onTap: _takePhoto,
          ),
          _buildAttachmentOption(
            icon: Icons.location_on,
            label: '位置',
            onTap: () {
              // TODO: 实现位置发送功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('位置发送功能暂未实现')),
              );
            },
          ),
          _buildAttachmentOption(
            icon: Icons.file_present,
            label: '文件',
            onTap: () {
              // TODO: 实现文件发送功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件发送功能暂未实现')),
              );
            },
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordingView() {
    return Container(
      height: 150,
      color: Theme.of(context).cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.mic,
            color: Colors.red,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            _recordDuration,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _cancelRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('取消'),
              ),
              const SizedBox(width: 32),
              ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('发送'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _showAttachmentOptions ? Icons.close : Icons.add,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showAttachmentOptions = !_showAttachmentOptions;
                    _showEmojiPicker = false;
                    if (_showAttachmentOptions) {
                      _focusNode.unfocus();
                    }
                  });
                },
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: '输入消息...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                            _showAttachmentOptions = false;
                            if (_showEmojiPicker) {
                              _focusNode.unfocus();
                            } else {
                              _focusNode.requestFocus();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _textController.text.trim().isEmpty
                  ? GestureDetector(
                      onLongPress: _startRecording,
                      onLongPressEnd: (_) => _stopRecording(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _sendTextMessage,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        if (_isRecording) _buildRecordingView(),
        if (_showAttachmentOptions && !_isRecording) _buildAttachmentOptions(),
        // TODO: 实现表情选择器
        if (_showEmojiPicker && !_isRecording)
          Container(
            height: 200,
            color: Theme.of(context).cardColor,
            child: const Center(
              child: Text('表情选择器暂未实现'),
            ),
          ),
      ],
    );
  }
}