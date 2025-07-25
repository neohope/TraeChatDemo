import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageUtils {
  /// 默认头像颜色列表
  static const List<Color> _avatarColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
  ];

  /// 根据用户名生成头像颜色
  static Color getAvatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    
    final hash = name.hashCode;
    final index = hash.abs() % _avatarColors.length;
    return _avatarColors[index];
  }

  /// 获取用户名的首字母（支持中文）
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    
    // 如果是中文名，取最后一个字符
    if (_isChinese(trimmed)) {
      return trimmed.characters.last.toUpperCase();
    }
    
    // 英文名取首字母
    final words = trimmed.split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }

  /// 检查字符串是否包含中文字符
  static bool _isChinese(String text) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
  }

  /// 创建文字头像
  static Widget createTextAvatar({
    required String name,
    double size = 40,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  }) {
    final initials = getInitials(name);
    final bgColor = backgroundColor ?? getAvatarColor(name);
    final fgColor = textColor ?? Colors.white;
    final textSize = fontSize ?? size * 0.4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: fgColor,
            fontSize: textSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 创建网络图片头像，带有错误处理
  static Widget createNetworkAvatar({
    required String? imageUrl,
    required String fallbackName,
    double size = 40,
    Color? backgroundColor,
    Color? textColor,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return createTextAvatar(
        name: fallbackName,
        size: size,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return createTextAvatar(
            name: fallbackName,
            size: size,
            backgroundColor: backgroundColor,
            textColor: textColor,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 压缩图片
  static Future<Uint8List?> compressImage(
    Uint8List imageData, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// 获取图片尺寸
  static Future<Size?> getImageSize(Uint8List imageData) async {
    try {
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      return null;
    }
  }

  /// 创建圆角图片
  static Widget createRoundedImage({
    required ImageProvider imageProvider,
    double width = 100,
    double height = 100,
    double borderRadius = 8,
    BoxFit fit = BoxFit.cover,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  /// 创建带边框的圆形图片
  static Widget createCircularImageWithBorder({
    required ImageProvider imageProvider,
    double size = 100,
    Color borderColor = Colors.white,
    double borderWidth = 2,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: Image(
          image: imageProvider,
          width: size - borderWidth * 2,
          height: size - borderWidth * 2,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 创建渐变背景
  static Widget createGradientBackground({
    required Widget child,
    List<Color>? colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? [
            Colors.blue.shade400,
            Colors.purple.shade400,
          ],
        ),
      ),
      child: child,
    );
  }

  /// 创建模糊背景
  static Widget createBlurredBackground({
    required Widget child,
    required ImageProvider backgroundImage,
    double sigmaX = 10,
    double sigmaY = 10,
    Color? overlayColor,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            color: overlayColor ?? Colors.black.withOpacity(0.3),
          ),
        ),
        child,
      ],
    );
  }

  /// 验证图片URL格式
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final path = uri.path.toLowerCase();
    
    return validExtensions.any((ext) => path.endsWith(ext)) ||
           url.contains('image') ||
           url.contains('avatar') ||
           url.contains('photo');
  }

  /// 获取图片文件扩展名
  static String getImageExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filename.substring(lastDot).toLowerCase();
  }

  /// 检查是否是支持的图片格式
  static bool isSupportedImageFormat(String filename) {
    final extension = getImageExtension(filename);
    const supportedFormats = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    return supportedFormats.contains(extension);
  }
}