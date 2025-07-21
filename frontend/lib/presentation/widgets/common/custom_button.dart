import 'package:flutter/material.dart';

import '../../themes/app_theme.dart';

/// 自定义按钮组件
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;
  final double borderRadius;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
    this.borderRadius = AppTheme.borderRadiusNormal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 确定按钮颜色
    final bgColor = backgroundColor ?? theme.primaryColor;
    final txtColor = textColor ?? Colors.white;
    
    // 创建按钮样式
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingNormal,
              horizontal: AppTheme.spacingLarge,
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingNormal,
              horizontal: AppTheme.spacingLarge,
            ),
          );
    
    // 创建按钮内容
    Widget buttonContent;
    
    if (isLoading) {
      // 加载状态
      buttonContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? bgColor : txtColor,
          ),
        ),
      );
    } else if (icon != null) {
      // 带图标的按钮
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppTheme.spacingSmall),
          Text(text),
        ],
      );
    } else {
      // 纯文本按钮
      buttonContent = Text(text);
    }
    
    // 创建按钮
    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonContent,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonContent,
          );
    
    // 如果指定了宽度或高度，则使用SizedBox包装
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }
    
    return button;
  }
}