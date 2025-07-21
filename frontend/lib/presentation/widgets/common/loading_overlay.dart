import 'package:flutter/material.dart';

/// 加载覆盖层组件，用于在操作过程中显示加载状态
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final Color? progressColor;
  final double opacity;
  
  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.progressColor,
    this.opacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 如果不在加载状态，直接返回子组件
    if (!isLoading) {
      return child;
    }
    
    // 在加载状态，显示加载覆盖层
    return Stack(
      children: [
        // 子组件
        child,
        
        // 半透明背景和加载指示器
        Positioned.fill(
          child: Container(
            color: (backgroundColor ?? Colors.black).withOpacity(opacity),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 加载指示器
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? theme.primaryColor,
                    ),
                  ),
                  
                  // 如果有消息，显示消息
                  if (message != null) ...[  
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}