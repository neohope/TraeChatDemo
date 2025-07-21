import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../themes/app_theme.dart';

/// 聊天输入组件
/// 
/// 用于在聊天界面底部显示消息输入框，支持文本、图片、语音等多种输入方式
class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendImage;
  final Function(String, int) onSendVoice;
  
  const ChatInput({
    Key? key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false;
  DateTime? _recordStartTime;
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingNormal,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 附加功能按钮
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAttachmentOptions,
          ),
          
          // 输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingNormal,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  border: InputBorder.none,
                ),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          
          // 语音按钮
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _handleVoiceButton,
          ),
          
          // 发送按钮
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendTextMessage,
          ),
        ],
      ),
    );
  }
  
  /// 发送文本消息
  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      _textController.clear();
    }
  }
  
  /// 处理语音按钮点击
  void _handleVoiceButton() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }
  
  /// 开始录音
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordStartTime = DateTime.now();
    });
    
    // 显示录音提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('开始录音...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // TODO: 实现录音功能
  }
  
  /// 停止录音
  void _stopRecording() {
    final now = DateTime.now();
    final duration = now.difference(_recordStartTime ?? now).inSeconds;
    
    setState(() {
      _isRecording = false;
      _recordStartTime = null;
    });
    
    // 显示录音结束提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('录音结束，时长：$duration 秒'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // TODO: 实现获取录音文件路径的功能
    final audioPath = 'dummy_audio_path.mp3';
    
    // 调用回调函数发送语音消息
    widget.onSendVoice(audioPath, duration);
  }
  
  /// 显示附件选项
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('图片'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('位置'),
                onTap: () {
                  Navigator.pop(context);
                  _sendLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('文件'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        widget.onSendImage(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败：$e')),
      );
    }
  }
  
  /// 发送位置
  void _sendLocation() {
    // TODO: 实现位置选择和发送功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('位置发送功能尚未实现')),
    );
  }
  
  /// 选择文件
  void _pickFile() {
    // TODO: 实现文件选择和发送功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件发送功能尚未实现')),
    );
  }
}