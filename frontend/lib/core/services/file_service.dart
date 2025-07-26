import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import '../utils/app_logger.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  static FileService get instance => _instance;

  final ApiService _apiService = ApiService.instance;
  final AppLogger _logger = AppLogger.instance;
  
  bool _isInitialized = false;
  
  /// 初始化文件服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 这里可以添加任何需要的初始化逻辑
      // 比如检查权限、创建临时目录等
      _logger.logger.i('FileService initialized successfully');
      _isInitialized = true;
    } catch (e) {
      _logger.logger.e('Failed to initialize FileService: $e');
      rethrow;
    }
  }
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;
  
  // 支持的文件类型
  static const List<String> _supportedImageTypes = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'
  ];
  static const List<String> _supportedVideoTypes = [
    'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'
  ];
  static const List<String> _supportedAudioTypes = [
    'mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'
  ];
  static const List<String> _supportedDocumentTypes = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'
  ];
  
  // 文件大小限制（字节）
  static const int _maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int _maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int _maxAudioSize = 50 * 1024 * 1024; // 50MB
  static const int _maxDocumentSize = 20 * 1024 * 1024; // 20MB
  
  /// 选择单个文件
  // Future<PlatformFile?> pickSingleFile({
  //   FileType type = FileType.any,
  //   List<String>? allowedExtensions,
  // }) async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: type,
  //       allowedExtensions: allowedExtensions,
  //       allowMultiple: false,
  //     );
  //     
  //     if (result != null && result.files.isNotEmpty) {
  //       final file = result.files.first;
  //       _logger.logger.i('选择文件: ${file.name}, 大小: ${file.size} bytes');
  //       return file;
  //     }
  //     
  //     return null;
  //   } catch (e) {
  //     _logger.logger.e('选择文件失败: $e');
  //     return null;
  //   }
  // }
  
  /// 选择多个文件
  // Future<List<PlatformFile>?> pickMultipleFiles({
  //   FileType type = FileType.any,
  //   List<String>? allowedExtensions,
  //   int? maxFiles,
  // }) async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: type,
  //       allowedExtensions: allowedExtensions,
  //       allowMultiple: true,
  //     );
  //     
  //     if (result != null && result.files.isNotEmpty) {
  //       var files = result.files;
  //       
  //       // 限制文件数量
  //       if (maxFiles != null && files.length > maxFiles) {
  //         files = files.take(maxFiles).toList();
  //       }
  //       
  //       _logger.logger.i('选择了 ${files.length} 个文件');
  //       return files;
  //     }
  //     
  //     return null;
  //   } catch (e) {
  //     _logger.logger.e('选择多个文件失败: $e');
  //     return null;
  //   }
  // }
  
  /// 选择图片文件
  // Future<PlatformFile?> pickImage() async {
  //   return await pickSingleFile(
  //     type: FileType.custom,
  //     allowedExtensions: _supportedImageTypes,
  //   );
  // }
  
  /// 选择视频文件
  // Future<PlatformFile?> pickVideo() async {
  //   return await pickSingleFile(
  //     type: FileType.custom,
  //     allowedExtensions: _supportedVideoTypes,
  //   );
  // }
  
  /// 选择音频文件
  // Future<PlatformFile?> pickAudio() async {
  //   return await pickSingleFile(
  //     type: FileType.custom,
  //     allowedExtensions: _supportedAudioTypes,
  //   );
  // }
  
  /// 选择文档文件
  // Future<PlatformFile?> pickDocument() async {
  //   return await pickSingleFile(
  //     type: FileType.custom,
  //     allowedExtensions: _supportedDocumentTypes,
  //   );
  // }
  
  /// 验证文件
  // FileValidationResult validateFile(PlatformFile file) {
  //   final extension = path.extension(file.name).toLowerCase().replaceFirst('.', '');
  //   final fileType = getFileType(extension);
  //   
  //   // 检查文件类型
  //   if (fileType == FileCategory.unknown) {
  //     return FileValidationResult(
  //       isValid: false,
  //       error: '不支持的文件类型: $extension',
  //     );
  //   }
  //   
  //   // 检查文件大小
  //   final maxSize = _getMaxSizeForType(fileType);
  //   if (file.size > maxSize) {
  //     return FileValidationResult(
  //       isValid: false,
  //       error: '文件大小超过限制: ${_formatFileSize(file.size)} > ${_formatFileSize(maxSize)}',
  //     );
  //   }
  //   
  //   return FileValidationResult(isValid: true);
  // }
  
  /// 上传文件
  // Future<FileUploadResult> uploadFile(
  //   PlatformFile file, {
  //   String? customPath,
  //   Map<String, dynamic>? metadata,
  //   Function(double)? onProgress,
  // }) async {
  //   try {
  //     // 验证文件
  //     final validation = validateFile(file);
  //     if (!validation.isValid) {
  //       return FileUploadResult(
  //         success: false,
  //         error: validation.error,
  //       );
  //     }
  //     
  //     // 准备上传数据
  //     final uploadData = {
  //       'fileName': file.name,
  //       'fileSize': file.size,
  //       'fileType': getFileType(path.extension(file.name)).toString(),
  //       'customPath': customPath,
  //       ...?metadata,
  //     };
  //     
  //     // 上传文件
  //     String? filePath;
  //     if (kIsWeb) {
  //       // Web平台使用bytes
  //       filePath = await _uploadFileWeb(file, uploadData, onProgress);
  //     } else {
  //       // 移动平台使用文件路径
  //       filePath = await _uploadFileMobile(file, uploadData, onProgress);
  //     }
  //     
  //     if (filePath != null) {
  //       _logger.logger.i('文件上传成功: $filePath');
  //       return FileUploadResult(
  //         success: true,
  //         filePath: filePath,
  //         fileName: file.name,
  //         fileSize: file.size,
  //       );
  //     } else {
  //       return FileUploadResult(
  //         success: false,
  //         error: '文件上传失败',
  //       );
  //     }
  //   } catch (e) {
  //     _logger.logger.e('上传文件异常: $e');
  //     return FileUploadResult(
  //       success: false,
  //       error: '上传文件异常: $e',
  //     );
  //   }
  // }
  
  /// Web平台文件上传
  // Future<String?> _uploadFileWeb(
  //   PlatformFile file,
  //   Map<String, dynamic> uploadData,
  //   Function(double)? onProgress,
  // ) async {
  //   try {
  //     // 模拟上传进度
  //     if (onProgress != null) {
  //       for (int i = 0; i <= 100; i += 10) {
  //         await Future.delayed(Duration(milliseconds: 100));
  //         onProgress(i / 100.0);
  //       }
  //     }
  //     
  //     // 返回模拟的文件URL
  //     return 'https://example.com/files/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
  //   } catch (e) {
  //     _logger.logger.e('Web文件上传失败: $e');
  //     return null;
  //   }
  // }
  
  /// 移动平台文件上传
  // Future<String?> _uploadFileMobile(
  //   PlatformFile file,
  //   Map<String, dynamic> uploadData,
  //   Function(double)? onProgress,
  // ) async {
  //   try {
  //     if (file.path == null) {
  //       _logger.logger.e('文件路径为空');
  //       return null;
  //     }
  //     
  //     // 使用API服务上传文件
  //     final response = await _apiService.uploadFile(
  //       '/files/upload',
  //       file.path!,
  //       fileName: file.name,
  //       data: uploadData,
  //       onSendProgress: (sent, total) {
  //         if (onProgress != null) {
  //           onProgress(sent / total);
  //         }
  //       },
  //     );
  //     
  //     return response['filePath'];
  //   } catch (e) {
  //     _logger.logger.e('移动端文件上传失败: $e');
  //     return null;
  //   }
  // }
  
  /// 下载文件
  Future<FileDownloadResult> downloadFile(
    String url,
    String fileName, {
    String? savePath,
    Function(double)? onProgress,
  }) async {
    try {
      // 检查存储权限
      if (!kIsWeb) {
        final hasPermission = await _checkStoragePermission();
        if (!hasPermission) {
          return FileDownloadResult(
            success: false,
            error: '存储权限未授予',
          );
        }
      }
      
      // 确定保存路径
      final finalSavePath = savePath ?? await _getDownloadPath(fileName);
      
      // 下载文件
      await _apiService.downloadFile(
        url,
        finalSavePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );
      
      _logger.logger.i('文件下载成功: $finalSavePath');
      return FileDownloadResult(
        success: true,
        filePath: finalSavePath,
        fileName: fileName,
      );
    } catch (e) {
      _logger.logger.e('下载文件失败: $e');
      return FileDownloadResult(
        success: false,
        error: '下载文件失败: $e',
      );
    }
  }
  
  /// 删除本地文件
  Future<bool> deleteLocalFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台无法直接删除文件
        _logger.logger.w('Web平台不支持删除本地文件');
        return false;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.logger.i('本地文件已删除: $filePath');
        return true;
      } else {
        _logger.logger.w('文件不存在: $filePath');
        return false;
      }
    } catch (e) {
      _logger.logger.e('删除本地文件失败: $e');
      return false;
    }
  }
  
  /// 获取文件类型
  FileCategory getFileType(String extension) {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    
    if (_supportedImageTypes.contains(ext)) {
      return FileCategory.image;
    } else if (_supportedVideoTypes.contains(ext)) {
      return FileCategory.video;
    } else if (_supportedAudioTypes.contains(ext)) {
      return FileCategory.audio;
    } else if (_supportedDocumentTypes.contains(ext)) {
      return FileCategory.document;
    } else {
      return FileCategory.unknown;
    }
  }
  
  /// 格式化文件大小
  String formatFileSize(int bytes) {
    return _formatFileSize(bytes);
  }
  
  /// 获取文件信息
  Future<FileInfo?> getFileInfo(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台无法获取本地文件信息
        return null;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final stat = await file.stat();
      final fileName = path.basename(filePath);
      final extension = path.extension(fileName);
      
      return FileInfo(
        name: fileName,
        path: filePath,
        size: stat.size,
        extension: extension,
        category: getFileType(extension),
        createdAt: stat.changed,
        modifiedAt: stat.modified,
      );
    } catch (e) {
      _logger.logger.e('获取文件信息失败: $e');
      return null;
    }
  }
  
  /// 检查存储权限
  Future<bool> _checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return status.isGranted;
      }
      return true; // iOS不需要存储权限
    } catch (e) {
      _logger.logger.e('检查存储权限失败: $e');
      return false;
    }
  }
  
  /// 获取下载路径
  Future<String> _getDownloadPath(String fileName) async {
    if (kIsWeb) {
      return fileName; // Web平台返回文件名
    }
    
    // 移动平台返回完整路径
    final directory = Platform.isAndroid 
        ? '/storage/emulated/0/Download'
        : '/var/mobile/Containers/Data/Application/Documents';
    
    return path.join(directory, fileName);
  }
  
  /// 获取文件类型的最大大小限制
  // ignore: unused_element
  int _getMaxSizeForType(FileCategory category) {
    switch (category) {
      case FileCategory.image:
        return _maxImageSize;
      case FileCategory.video:
        return _maxVideoSize;
      case FileCategory.audio:
        return _maxAudioSize;
      case FileCategory.document:
        return _maxDocumentSize;
      default:
        return _maxDocumentSize;
    }
  }
  
  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// 文件类别枚举
enum FileCategory {
  image,
  video,
  audio,
  document,
  unknown,
}

/// 文件验证结果
class FileValidationResult {
  final bool isValid;
  final String? error;
  
  FileValidationResult({
    required this.isValid,
    this.error,
  });
}

/// 文件上传结果
class FileUploadResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? error;
  
  FileUploadResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.error,
  });
}

/// 文件下载结果
class FileDownloadResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? error;
  
  FileDownloadResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.error,
  });
}

/// 文件信息
class FileInfo {
  final String name;
  final String path;
  final int size;
  final String extension;
  final FileCategory category;
  final DateTime createdAt;
  final DateTime modifiedAt;
  
  FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
    required this.category,
    required this.createdAt,
    required this.modifiedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'extension': extension,
      'category': category.toString(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }
}