import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/message_model.dart';
import '../../../domain/models/conversation_model.dart';

/// 消息操作菜单组件
class MessageActionMenu extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onRecall;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;

  const MessageActionMenu({
    Key? key,
    required this.message,
    required this.currentUserId,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onRecall,
    this.onEdit,
    this.onCopy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;
    final canRecall = isMe && message.canRecall() && !message.isRecalled;
    final canCopy = message.type == MessageType.text && message.text?.isNotEmpty == true;
    final canEdit = isMe && message.type == MessageType.text && !message.isRecalled;
    final canDelete = isMe && !message.isRecalled;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 复制
          if (canCopy)
            _buildMenuItem(
              context,
              icon: Icons.content_copy,
              title: '复制',
              onTap: () {
                if (message.text != null) {
                  Clipboard.setData(ClipboardData(text: message.text!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制到剪贴板')),
                  );
                }
                Navigator.pop(context);
                onCopy?.call();
              },
            ),
          
          // 回复
          if (onReply != null && !message.isRecalled)
            _buildMenuItem(
              context,
              icon: Icons.reply,
              title: '回复',
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
          
          // 转发
          if (onForward != null && !message.isRecalled)
            _buildMenuItem(
              context,
              icon: Icons.forward,
              title: '转发',
              onTap: () {
                Navigator.pop(context);
                onForward?.call();
              },
            ),
          
          // 编辑
          if (canEdit && onEdit != null)
            _buildMenuItem(
              context,
              icon: Icons.edit,
              title: '编辑',
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
          
          // 撤回
          if (canRecall && onRecall != null)
            _buildMenuItem(
              context,
              icon: Icons.undo,
              title: '撤回',
              onTap: () {
                Navigator.pop(context);
                _showRecallConfirmDialog(context);
              },
            ),
          
          // 删除
          if (canDelete && onDelete != null)
            _buildMenuItem(
              context,
              icon: Icons.delete,
              title: '删除',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Theme.of(context).colorScheme.onSurface;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: itemColor,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecallConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤回消息'),
        content: const Text('确定要撤回这条消息吗？撤回后对方将无法看到消息内容。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRecall?.call();
            },
            child: const Text('撤回'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示消息操作菜单
  static void show(
    BuildContext context, {
    required MessageModel message,
    required String currentUserId,
    VoidCallback? onReply,
    VoidCallback? onForward,
    VoidCallback? onDelete,
    VoidCallback? onRecall,
    VoidCallback? onEdit,
    VoidCallback? onCopy,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: MessageActionMenu(
          message: message,
          currentUserId: currentUserId,
          onReply: onReply,
          onForward: onForward,
          onDelete: onDelete,
          onRecall: onRecall,
          onEdit: onEdit,
          onCopy: onCopy,
        ),
      ),
    );
  }
}