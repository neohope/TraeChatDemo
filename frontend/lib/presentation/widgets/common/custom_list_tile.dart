import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 自定义列表项组件
/// 
/// 用于显示带有前导图标、标题、副标题和尾随部件的列表项
/// 支持自定义样式和点击事件
class CustomListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final bool enabled;
  final double? leadingSize;
  final double? trailingSize;
  
  const CustomListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.contentPadding,
    this.backgroundColor,
    this.enabled = true,
    this.leadingSize,
    this.trailingSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: backgroundColor ?? Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: Padding(
          padding: contentPadding ?? 
              const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingNormal,
                vertical: AppTheme.spacingSmall,
              ),
          child: Row(
            children: [
              // 前导图标
              if (leading != null) ...[  
                SizedBox(
                  width: leadingSize ?? AppTheme.iconSizeMedium,
                  height: leadingSize ?? AppTheme.iconSizeMedium,
                  child: leading,
                ),
                const SizedBox(width: AppTheme.spacingNormal),
              ],
              
              // 标题和副标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle(
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: enabled ? null : theme.disabledColor,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[  
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: enabled ? theme.textTheme.bodySmall!.color : theme.disabledColor,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              
              // 尾随部件
              if (trailing != null) ...[  
                const SizedBox(width: AppTheme.spacingNormal),
                SizedBox(
                  width: trailingSize ?? AppTheme.iconSizeSmall,
                  child: trailing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}