import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

import '../../core/utils/app_logger.dart';

/// 文件类型枚举
enum AppFileType {
  image,
  video,
  audio,
  document,
  other,
}

/// 文件信息模型
class FileInfo {
  final String name;
  final String path;
  final int size;
  final AppFileType type;
  final String? mimeType;
  final DateTime createdAt;
  final String? thumbnail;
  final Map<String, dynamic>? metadata;

  FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    this.mimeType,
    required this.createdAt,
    this.thumbnail,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'size': size,
        'type': type.name,
        'mimeType': mimeType,
        'createdAt': createdAt.toIso8601String(),
        'thumbnail': thumbnail,
        'metadata': metadata,
      };

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
        name: json['name'],
        path: json['path'],
        size: json['size'],
        type: AppFileType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AppFileType.other,
        ),
        mimeType: json['mimeType'],
        createdAt: DateTime.parse(json['createdAt']),
        thumbnail: json['thumbnail'],
        metadata: json['metadata'],
      );
}

/// 文件上传进度回调
typedef FileUploadProgressCallback = void Function(int sent, int total);

/// 文件下载进度回调
typedef FileDownloadProgressCallback = void Function(int received, int total);

/// 文件传输状态
enum FileTransferStatus {
  pending,
  uploading,
  downloading,
  completed,
  failed,
  cancelled,
}

/// 文件传输信息
class FileTransferInfo {
  final String id;
  final String fileName;
  final int fileSize;
  final FileTransferStatus status;
  final double progress;
  final String? error;
  final DateTime startTime;
  final DateTime? endTime;

  FileTransferInfo({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.status,
    required this.progress,
    this.error,
    required this.startTime,
    this.endTime,
  });

  FileTransferInfo copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    FileTransferStatus? status,
    double? progress,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return FileTransferInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// 文件服务
class FileService {
  final AppLogger _logger;
  final Dio _dio;
  final ImagePicker _imagePicker;
  
  // 文件传输状态管理
  final Map<String, FileTransferInfo> _transferInfos = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final StreamController<FileTransferInfo> _transferStatusController =
      StreamController<FileTransferInfo>.broadcast();

  FileService({
    AppLogger? logger,
    Dio? dio,
    ImagePicker? imagePicker,
  })  : _logger = logger ?? AppLogger.instance,
        _dio = dio ?? Dio(),
        _imagePicker = imagePicker ?? ImagePicker() {
    _initializeDio();
  }

  /// 文件传输状态流
  Stream<FileTransferInfo> get transferStatusStream =>
      _transferStatusController.stream;

  /// 获取文件传输信息
  FileTransferInfo? getTransferInfo(String transferId) {
    return _transferInfos[transferId];
  }

  /// 获取所有传输信息
  List<FileTransferInfo> getAllTransferInfos() {
    return _transferInfos.values.toList();
  }

  /// 初始化Dio配置
  void _initializeDio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(minutes: 10);
  }

  /// 选择图片
  Future<List<FileInfo>> pickImages({
    bool multiple = false,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final List<XFile> files;
      
      if (multiple) {
        files = await _imagePicker.pickMultiImage(
          imageQuality: imageQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
      } else {
        final file = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: imageQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
        files = file != null ? [file] : [];
      }
      
      final fileInfos = <FileInfo>[];
      for (final file in files) {
        final fileInfo = await _createFileInfo(file.path, AppFileType.image);
        if (fileInfo != null) {
          fileInfos.add(fileInfo);
        }
      }
      
      _logger.info('选择了${fileInfos.length}张图片');
      return fileInfos;
    } catch (e) {
      _logger.error('选择图片失败: $e');
      rethrow;
    }
  }

  /// 拍照
  Future<FileInfo?> takePhoto({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      if (file != null) {
        final fileInfo = await _createFileInfo(file.path, AppFileType.image);
        _logger.info('拍照完成: ${file.path}');
        return fileInfo;
      }
    } catch (e) {
      _logger.error('拍照失败: $e');
      rethrow;
    }
    return null;
  }

  /// 选择视频
  Future<FileInfo?> pickVideo({
    Duration? maxDuration,
  }) async {
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );
      
      if (file != null) {
        final fileInfo = await _createFileInfo(file.path, AppFileType.video);
        _logger.info('选择视频: ${file.path}');
        return fileInfo;
      }
    } catch (e) {
      _logger.error('选择视频失败: $e');
      rethrow;
    }
    return null;
  }

  /// 录制视频
  Future<FileInfo?> recordVideo({
    Duration? maxDuration,
  }) async {
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
      );
      
      if (file != null) {
        final fileInfo = await _createFileInfo(file.path, AppFileType.video);
        _logger.info('录制视频: ${file.path}');
        return fileInfo;
      }
    } catch (e) {
      _logger.error('录制视频失败: $e');
      rethrow;
    }
    return null;
  }

  /// 选择文件
  Future<List<FileInfo>> pickFiles({
    List<String>? allowedExtensions,
    bool multiple = false,
    AppFileType? type,
  }) async {
    _logger.warning('pickFiles is not implemented');
    return [];
    // try {
    //   // 检查存储权限
    //   if (!await _checkStoragePermission()) {
    //     throw Exception('需要存储权限才能选择文件');
    //   }
      
    //   final result = await FilePicker.platform.pickFiles(
    //     type: _convertFileType(type),
    //     allowedExtensions: allowedExtensions,
    //     allowMultiple: multiple,
    //     withData: false,
    //     withReadStream: false,
    //   );
      
    //   if (result != null) {
    //     final fileInfos = <FileInfo>[];
    //     for (final file in result.files) {
    //       if (file.path != null) {
    //         final fileType = _getFileTypeFromExtension(file.extension);
    //         final fileInfo = await _createFileInfo(file.path!, fileType);
    //         if (fileInfo != null) {
    //           fileInfos.add(fileInfo);
    //         }
    //       }
    //     }
        
    //     _logger.info('选择了${fileInfos.length}个文件');
    //     return fileInfos;
    //   }
    // } catch (e) {
    //   _logger.error('选择文件失败: $e');
    //   rethrow;
    // }
    // return [];
  }

  /// 上传文件
  Future<String?> uploadFile(
    String filePath,
    String uploadUrl, {
    Map<String, dynamic>? extraData,
    FileUploadProgressCallback? onProgress,
  }) async {
    final transferId = _generateTransferId();
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }
    
    final fileName = path.basename(filePath);
    final fileSize = await file.length();
    
    // 创建传输信息
    final transferInfo = FileTransferInfo(
      id: transferId,
      fileName: fileName,
      fileSize: fileSize,
      status: FileTransferStatus.uploading,
      progress: 0.0,
      startTime: DateTime.now(),
    );
    
    _transferInfos[transferId] = transferInfo;
    _transferStatusController.add(transferInfo);
    
    try {
      final cancelToken = CancelToken();
      _cancelTokens[transferId] = cancelToken;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?extraData,
      });
      
      final response = await _dio.post(
        uploadUrl,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          final updatedInfo = transferInfo.copyWith(
            progress: progress,
          );
          _transferInfos[transferId] = updatedInfo;
          _transferStatusController.add(updatedInfo);
          onProgress?.call(sent, total);
        },
      );
      
      if (response.statusCode == 200) {
        final completedInfo = transferInfo.copyWith(
          status: FileTransferStatus.completed,
          progress: 1.0,
          endTime: DateTime.now(),
        );
        _transferInfos[transferId] = completedInfo;
        _transferStatusController.add(completedInfo);
        
        _logger.info('文件上传成功: $fileName');
        return response.data['fileUrl'] ?? response.data['url'];
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      final failedInfo = transferInfo.copyWith(
        status: FileTransferStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );
      _transferInfos[transferId] = failedInfo;
      _transferStatusController.add(failedInfo);
      
      _logger.error('文件上传失败: $e');
      rethrow;
    } finally {
      _cancelTokens.remove(transferId);
    }
  }

  /// 下载文件
  Future<String?> downloadFile(
    String downloadUrl,
    String fileName, {
    String? savePath,
    FileDownloadProgressCallback? onProgress,
  }) async {
    final transferId = _generateTransferId();
    
    try {
      // 确定保存路径
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(path.join(directory.path, 'downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final finalSavePath = savePath ?? path.join(downloadsDir.path, fileName);
      
      // 创建传输信息
      final transferInfo = FileTransferInfo(
        id: transferId,
        fileName: fileName,
        fileSize: 0, // 将在下载开始后更新
        status: FileTransferStatus.downloading,
        progress: 0.0,
        startTime: DateTime.now(),
      );
      
      _transferInfos[transferId] = transferInfo;
      _transferStatusController.add(transferInfo);
      
      final cancelToken = CancelToken();
      _cancelTokens[transferId] = cancelToken;
      
      final response = await _dio.download(
        downloadUrl,
        finalSavePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final updatedInfo = transferInfo.copyWith(
              fileSize: total,
              progress: progress,
            );
            _transferInfos[transferId] = updatedInfo;
            _transferStatusController.add(updatedInfo);
            onProgress?.call(received, total);
          }
        },
      );
      
      if (response.statusCode == 200) {
        final completedInfo = transferInfo.copyWith(
          status: FileTransferStatus.completed,
          progress: 1.0,
          endTime: DateTime.now(),
        );
        _transferInfos[transferId] = completedInfo;
        _transferStatusController.add(completedInfo);
        
        _logger.info('文件下载成功: $fileName');
        return finalSavePath;
      } else {
        throw Exception('下载失败: ${response.statusCode}');
      }
    } catch (e) {
      final failedInfo = _transferInfos[transferId]!.copyWith(
        status: FileTransferStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );
      _transferInfos[transferId] = failedInfo;
      _transferStatusController.add(failedInfo);
      
      _logger.error('文件下载失败: $e');
      rethrow;
    } finally {
      _cancelTokens.remove(transferId);
    }
  }

  /// 取消文件传输
  Future<void> cancelTransfer(String transferId) async {
    final cancelToken = _cancelTokens[transferId];
    if (cancelToken != null) {
      cancelToken.cancel('用户取消');
      
      final transferInfo = _transferInfos[transferId];
      if (transferInfo != null) {
        final cancelledInfo = transferInfo.copyWith(
          status: FileTransferStatus.cancelled,
          endTime: DateTime.now(),
        );
        _transferInfos[transferId] = cancelledInfo;
        _transferStatusController.add(cancelledInfo);
      }
      
      _logger.info('取消文件传输: $transferId');
    }
  }

  /// 获取文件大小
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// 计算文件哈希
  Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }
    
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 压缩图片
  Future<String?> compressImage(
    String imagePath, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // 这里可以集成图片压缩库，如 flutter_image_compress
      // 目前返回原路径
      _logger.info('压缩图片: $imagePath');
      return imagePath;
    } catch (e) {
      _logger.error('压缩图片失败: $e');
      rethrow;
    }
  }

  /// 生成缩略图
  Future<String?> generateThumbnail(
    String filePath,
    AppFileType fileType, {
    int width = 200,
    int height = 200,
  }) async {
    try {
      // 这里可以集成缩略图生成库
      // 目前返回null
      _logger.info('生成缩略图: $filePath');
      return null;
    } catch (e) {
      _logger.error('生成缩略图失败: $e');
      return null;
    }
  }

  /// 清理临时文件
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      _logger.info('清理临时文件完成');
    } catch (e) {
      _logger.error('清理临时文件失败: $e');
    }
  }

  /// 销毁服务
  void dispose() {
    _transferStatusController.close();
    for (final cancelToken in _cancelTokens.values) {
      cancelToken.cancel('服务销毁');
    }
    _cancelTokens.clear();
    _transferInfos.clear();
  }

  /// 创建文件信息
  Future<FileInfo?> _createFileInfo(String filePath, AppFileType fileType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final stat = await file.stat();
      final fileName = path.basename(filePath);
      
      return FileInfo(
        name: fileName,
        path: filePath,
        size: stat.size,
        type: fileType,
        mimeType: _getMimeType(fileName),
        createdAt: stat.modified,
      );
    } catch (e) {
      _logger.error('创建文件信息失败: $e');
      return null;
    }
  }

  /// 检查存储权限
  // ignore: unused_element
  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    }
    return true;
  }

  // /// 转换文件类型
  // FileType _convertFileType(AppFileType? type) {
  //   switch (type) {
  //     case AppFileType.image:
  //       return FileType.image;
  //     case AppFileType.video:
  //       return FileType.video;
  //     case AppFileType.audio:
  //       return FileType.audio;
  //     default:
  //       return FileType.any;
  //   }
  // }

  /// 根据扩展名获取文件类型
  // ignore: unused_element
  AppFileType _getFileTypeFromExtension(String? extension) {
    if (extension == null) return AppFileType.other;
    
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return AppFileType.image;
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(ext)) {
      return AppFileType.video;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'].contains(ext)) {
      return AppFileType.audio;
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) {
      return AppFileType.document;
    } else {
      return AppFileType.other;
    }
  }

  /// 获取MIME类型
  String? _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  /// 生成传输ID
  String _generateTransferId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}