import 'package:flutter/material.dart';

import '../../../domain/models/user_model.dart';
import '../../../domain/models/conversation_model.dart'; // 导入 UserStatus 枚举
import '../../themes/app_theme.dart';

/// 用户列表项组件
/// 
/// 用于显示联系人列表中的用户项，包括头像、名称、状态、尾随部件等
class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showStatus;
  
  const UserListItem({
    Key? key,
    required this.user,
    required this.onTap,
    this.onLongPress,
    this.trailing,
    this.showStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingNormal,
          vertical: AppTheme.spacingSmall,
        ),
        child: Row(
          children: [
            // 用户头像
            _buildAvatar(context),
            const SizedBox(width: AppTheme.spacingNormal),
            
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名称
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (showStatus) ...[  
                    const SizedBox(height: 4),
                    
                    // 用户状态
                    Text(
                      _getStatusText(user.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // 尾随部件
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
  
  // 构建头像
  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        // 头像
        CircleAvatar(
          radius: AppTheme.avatarSizeMedium / 2,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 26), // 0.1 * 255 = 25.5 ≈ 26
          backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
              ? Icon(
                  Icons.person,
                  size: AppTheme.avatarSizeMedium / 2,
                  color: Theme.of(context).primaryColor,
                )
              : null,
        ),
        
        // 在线状态指示器
        if (showStatus) ...[  
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.getStatusColor(user.status),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
        
        // 收藏标记
        if (user.isFavorite)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(
                Icons.star,
                size: 6,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
  
  // 获取状态文本
  String _getStatusText(UserStatus? status) {
    if (status == null) return '离线';
    
    switch (status) {
      case UserStatus.online:
        return '在线';
      case UserStatus.offline:
        return '离线';
      case UserStatus.away:
        return '离开';
      case UserStatus.busy:
        return '忙碌';
      // ignore: unreachable_switch_default
      default:
        return '离线';
    }
  }
}