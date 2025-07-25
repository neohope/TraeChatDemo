import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

/// 文件工具类
class FileUtils {
  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
  
  /// 获取文件扩展名
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }
  
  /// 获取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  /// 检查文件是否存在
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
  
  /// 获取文件大小
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      // 忽略删除错误
    }
    return false;
  }
  
  /// 复制文件
  static Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return true;
      }
    } catch (e) {
      // 忽略复制错误
    }
    return false;
  }
  
  /// 移动文件
  static Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.rename(destinationPath);
        return true;
      }
    } catch (e) {
      // 忽略移动错误
    }
    return false;
  }
  
  /// 创建目录
  static Future<bool> createDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 检查是否为图片文件
  static bool isImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }
  
  /// 检查是否为视频文件
  static bool isVideoFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv'].contains(extension);
  }
  
  /// 检查是否为音频文件
  static bool isAudioFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', '.wma'].contains(extension);
  }
  
  /// 检查是否为文档文件
  static bool isDocumentFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.rtf'].contains(extension);
  }
  
  /// 生成唯一文件名
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalName);
    final nameWithoutExt = getFileNameWithoutExtension(originalName);
    return '${nameWithoutExt}_$timestamp$extension';
  }
  
  /// 清理文件名（移除非法字符）
  static String sanitizeFileName(String fileName) {
    // 移除或替换非法字符
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
  
  /// 获取MIME类型
  static String? getMimeType(String filePath) {
    final extension = getFileExtension(filePath);
    
    switch (extension) {
      // 图片
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      
      // 视频
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';
      case '.mkv':
        return 'video/x-matroska';
      
      // 音频
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.flac':
        return 'audio/flac';
      case '.ogg':
        return 'audio/ogg';
      case '.m4a':
        return 'audio/mp4';
      case '.wma':
        return 'audio/x-ms-wma';
      
      // 文档
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      
      // 其他
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.html':
      case '.htm':
        return 'text/html';
      case '.css':
        return 'text/css';
      case '.js':
        return 'application/javascript';
      
      default:
        return 'application/octet-stream';
    }
  }
  
  /// 格式化时间戳
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 检查文件大小是否超过限制
  static bool isFileSizeExceeded(int fileSize, int maxSizeInMB) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSize > maxSizeInBytes;
  }
  
  /// 获取文件类型描述
  static String getFileTypeDescription(String filePath) {
    if (isImageFile(filePath)) {
      return '图片';
    } else if (isVideoFile(filePath)) {
      return '视频';
    } else if (isAudioFile(filePath)) {
      return '音频';
    } else if (isDocumentFile(filePath)) {
      return '文档';
    } else {
      return '文件';
    }
  }
  
  /// 压缩文件路径显示
  static String compressPath(String filePath, {int maxLength = 30}) {
    if (filePath.length <= maxLength) {
      return filePath;
    }
    
    final fileName = path.basename(filePath);
    final dirPath = path.dirname(filePath);
    
    if (fileName.length >= maxLength - 3) {
      return '...${fileName.substring(fileName.length - (maxLength - 3))}';
    }
    
    final availableLength = maxLength - fileName.length - 4; // 4 for "..." and "/"
    if (availableLength <= 0) {
      return '...$fileName';
    }
    
    return '${dirPath.substring(0, availableLength)}.../$fileName';
  }
}