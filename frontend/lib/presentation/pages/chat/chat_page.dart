import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/message.dart';
import '../../../domain/models/conversation_model.dart'; // 导入 MessageType 和 MessageStatus 枚举
import '../../../domain/models/message_model.dart';
import '../../../domain/viewmodels/message_viewmodel.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/chat/chat_app_bar.dart';
import '../../widgets/chat/chat_input.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/common/loading_overlay.dart';

/// 聊天页面
/// 
/// 用于显示与特定用户的聊天界面，包括消息列表、输入框等
class ChatPage extends StatefulWidget {
  final String userId;
  final String? userName;
  
  const ChatPage({
    Key? key,
    required this.userId,
    this.userName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    
    // 加载聊天记录
    _loadMessages();
    
    // 监听滚动事件，实现下拉加载更多
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // 加载聊天记录
  Future<void> _loadMessages() async {
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    await messageViewModel.loadMessages(widget.userId);
    
    // 标记消息为已读
    await messageViewModel.markMessagesAsRead(widget.userId);
    
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  // 滚动监听器
  void _scrollListener() {
    if (_scrollController.position.pixels == 0 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }
  
  // 加载更多消息
  Future<void> _loadMoreMessages() async {
    setState(() {
      _isLoadingMore = true;
    });
    
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    await messageViewModel.loadMoreMessages(widget.userId);
    
    setState(() {
      _isLoadingMore = false;
    });
  }
  
  // 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // 发送消息
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    await messageViewModel.sendTextMessage(text);
    
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  // 发送图片消息
  Future<void> _sendImageMessage(String imagePath) async {
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    // 创建File对象
    final imageFile = File(imagePath);
    await messageViewModel.sendImageMessage(imageFile);
    
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  // 发送语音消息
  Future<void> _sendVoiceMessage(String audioPath, int durationInSeconds) async {
    final messageViewModel = Provider.of<MessageViewModel>(context, listen: false);
    // 创建File对象
    final audioFile = File(audioPath);
    // 添加元数据 - 注意：sendVoiceMessage 方法只接受一个参数
    // 元数据需要在 MessageViewModel 内部处理
    await messageViewModel.sendVoiceMessage(audioFile);
    
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        userId: widget.userId,
        userName: widget.userName,
      ),
      body: Consumer2<MessageViewModel, UserViewModel>(
        builder: (context, messageViewModel, userViewModel, child) {
          // 获取当前用户ID
          final currentUserId = userViewModel.currentUser?.id;
          if (currentUserId == null) {
            return const Center(child: Text('未登录'));
          }
          
          // 获取消息列表
          final messagesList = messageViewModel.getMessagesForUser(widget.userId);
          
          // 将 Message 对象转换为 MessageModel 对象
          final messages = _convertToMessageModels(messagesList);
          
          // 获取对方用户信息 - 在需要时可以取消注释
          // final otherUser = userViewModel.getCachedUserById(widget.userId);
          
          return Stack(
            children: [
              Column(
                children: [
                  // 消息列表
                  Expanded(
                    child: messages.isEmpty
                        ? _buildEmptyChat()
                        : _buildMessageList(messages, currentUserId),
                  ),
                  
                  // 输入框
                  ChatInput(
                    onSendText: _sendMessage,
                    onSendImage: _sendImageMessage,
                    onSendVoice: _sendVoiceMessage,
                  ),
                ],
              ),
              
              // 加载指示器
              if (messageViewModel.isLoading)
                LoadingOverlay(
                  isLoading: true,
                  child: Container(), // 空容器作为子组件
                ),
            ],
          );
        },
      ),
    );
  }
  
  // 构建空聊天界面
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingNormal),
          Text(
            '没有消息',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            '开始发送消息吧',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建消息列表
  Widget _buildMessageList(List<MessageModel> messages, String currentUserId) {
    return ListView.builder(
      controller: _scrollController,
      reverse: false, // 从上到下显示消息
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingNormal,
        vertical: AppTheme.spacingSmall,
      ),
      itemCount: messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (_isLoadingMore && index == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingNormal),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final actualIndex = _isLoadingMore ? index - 1 : index;
        final message = messages[actualIndex];
        final isMe = message.senderId == currentUserId;
        
        // 显示时间分隔线
        final showTimeDivider = _shouldShowTimeDivider(messages, actualIndex);
        
        return Column(
          children: [
            // 时间分隔线
            if (showTimeDivider)
              _buildTimeDivider(message.timestamp),
            
            // 消息气泡
            MessageBubble(
              message: message,
              isMe: isMe,
              showStatus: true,
            ),
          ],
        );
      },
    );
  }
  
  // 判断是否显示时间分隔线
  bool _shouldShowTimeDivider(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    // 如果两条消息之间的时间间隔超过5分钟，显示时间分隔线
    return currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes > 5;
  }
  
  // 构建时间分隔线
  Widget _buildTimeDivider(DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingNormal),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingNormal,
            vertical: AppTheme.spacingSmall / 2,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Text(
            _formatTimeDivider(time),
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
  
  // 格式化时间分隔线
  String _formatTimeDivider(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      // 今天，显示"今天 HH:mm"
      return '今天 ${_formatTimeOnly(time)}';
    } else if (messageDate == yesterday) {
      // 昨天，显示"昨天 HH:mm"
      return '昨天 ${_formatTimeOnly(time)}';
    } else {
      // 其他日期，显示"yyyy-MM-dd HH:mm"
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${_formatTimeOnly(time)}';
    }
  }
  
  // 格式化时间（只显示时:分）
  String _formatTimeOnly(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  // 将 Message 对象列表转换为 MessageModel 对象列表
  List<MessageModel> _convertToMessageModels(List<Message> messages) {
    return messages.map((message) => MessageModel(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId ?? '',
      type: message.type,
      text: message.type == MessageType.text ? message.content : null,
      mediaUrl: message.mediaUrl,
      metadata: {
        if (message.duration != null) 'duration': message.duration,
        if (message.latitude != null && message.longitude != null) ...
        {
          'latitude': message.latitude,
          'longitude': message.longitude,
        },
        if (message.customData != null) ...message.customData!,
      },
      timestamp: message.createdAt,
      status: message.status,
      isRead: message.status == MessageStatus.read,
      isDeleted: message.isDeleted,
      isEdited: message.updatedAt != null,
      readAt: message.status == MessageStatus.read ? message.updatedAt : null,
      deliveredAt: message.status == MessageStatus.delivered ? message.updatedAt : null,
    )).toList();
  }
}