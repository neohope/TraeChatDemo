import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../../utils/date_formatter.dart';

/// 会话列表项组件
/// 
/// 用于在会话列表中显示单个会话项，包括头像、名称、最后消息、时间、未读数等
class ConversationListItem extends StatelessWidget {
  final ConversationModel conversation;
  final Function(ConversationModel) onTap;
  final Function(ConversationModel) onLongPress;
  
  const ConversationListItem({
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    
    // 获取会话对应的用户或群组信息
    Widget avatar;
    String name;
    String? subtitle;
    
    if (conversation.isGroup) {
      // 群聊
      avatar = _buildGroupAvatar(conversation.avatar);
      name = conversation.name;
      
      // 如果有最后消息，显示发送者和消息内容
      if (conversation.lastMessage != null && conversation.lastMessage!.isNotEmpty) {
        final senderId = conversation.lastMessageSenderId;
        if (senderId != null) {
          final sender = userViewModel.getCachedUserById(senderId);
          final senderName = sender?.displayName ?? '未知用户';
          subtitle = '$senderName: ${_getLastMessageText()}';
        } else {
          subtitle = _getLastMessageText();
        }
      }
    } else {
      // 单聊，获取对方用户信息
      final otherUserId = conversation.participantIds != null 
        ? conversation.participantIds!.firstWhere(
            (id) => id != userViewModel.currentUser?.id,
            orElse: () => '',
          )
        : conversation.participantId ?? '';
      
      final otherUser = userViewModel.getCachedUserById(otherUserId);
      
      if (otherUser != null) {
        // 将 User 转换为 UserModel
        final userModel = UserModel(
          id: otherUser.id,
          name: otherUser.name,
          email: otherUser.email,
          phone: otherUser.phoneNumber,
          avatarUrl: otherUser.avatarUrl,
          bio: otherUser.bio,
          status: otherUser.status,
          lastSeen: otherUser.lastActive,
          isFavorite: otherUser.isFavorite,
          isBlocked: otherUser.isBlocked,
        );
        avatar = _buildUserAvatar(userModel);
        name = otherUser.displayName;
      } else {
        avatar = _buildDefaultAvatar();
        name = '未知用户';
      }
      
      subtitle = _getLastMessageText();
    }
    
    return InkWell(
      onTap: () => onTap(conversation),
      onLongPress: () => onLongPress(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                avatar,
                if (_isUserOnline())
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle ?? '',
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.isMuted)
                        const Icon(
                          Icons.volume_off,
                          size: 16,
                          color: Colors.grey,
                        ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
  
  Widget _buildUserAvatar(UserModel user) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(user.avatarUrl!),
      );
    } else {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.blue,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
  
  Widget _buildGroupAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(avatarUrl),
      );
    } else {
      return const CircleAvatar(
        radius: 28,
        backgroundColor: Colors.green,
        child: Icon(
          Icons.group,
          color: Colors.white,
          size: 28,
        ),
      );
    }
  }
  
  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey,
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 28,
      ),
    );
  }
  
  String _getLastMessageText() {
    if (conversation.lastMessage == null || conversation.lastMessage!.isEmpty) {
      return '暂无消息';
    }
    
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
        return '[系统消息]';
      default:
        return '未知消息类型';
    }
  }
  
  String _formatTime() {
    return DateFormatter.formatConversationTime(conversation.lastMessageTime);
  }
  
  bool _isUserOnline() {
    if (conversation.isGroup) {
      return false; // 群聊不显示在线状态
    }
    
    return conversation.isOnline || 
           conversation.participantStatus == UserStatus.online;
  }
}