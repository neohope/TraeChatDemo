import 'dart:async';
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
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  
  @override
  void dispose() {
    _textController.dispose();
    _recordingTimer?.cancel();
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
      _recordingDuration = 0;
    });
    
    // 显示录音提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('开始录音...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // 模拟录音过程
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }
  
  /// 停止录音
  void _stopRecording() {
    _recordingTimer?.cancel();
    
    setState(() {
      _isRecording = false;
      _recordStartTime = null;
    });
    
    // 显示录音结束提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('录音结束，时长：$_recordingDuration 秒'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // 模拟录音文件路径
    final audioPath = 'mock_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    // 调用回调函数发送语音消息
    widget.onSendVoice(audioPath, _recordingDuration);
    
    _recordingDuration = 0;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发送位置'),
        content: const Text('确定要发送当前位置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSendLocation();
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
  
  void _performSendLocation() {
    // 模拟位置数据
    const double latitude = 39.9042;
    const double longitude = 116.4074;
    const String address = '北京市朝阳区';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('位置已发送')),
    );
    
    // TODO: 调用发送位置的回调
    // widget.onSendLocation?.call(latitude, longitude, address);
  }
  
  /// 选择文件
  void _pickFile() async {
    try {
      // 模拟文件选择
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final fileSize = 1024 * 1024; // 1MB
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件已选择: $fileName')),
      );
      
      // TODO: 调用发送文件的回调
      // widget.onSendFile?.call(fileName, fileSize);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件选择失败: $e')),
      );
    }
  }
}