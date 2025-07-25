import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../data/services/file_service.dart';
import '../../data/services/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/file_utils.dart';

/// 文件传输ViewModel
class FileTransferViewModel extends ChangeNotifier {
  final FileService _fileService;
  final LocalStorage _localStorage;
  final AppLogger _logger;

  FileTransferViewModel({
    FileService? fileService,
    LocalStorage? localStorage,
    AppLogger? logger,
  })  : _fileService = fileService ?? FileService(),
        _localStorage = localStorage ?? LocalStorage(),
        _logger = logger ?? AppLogger.instance;

  // 传输状态管理
  final Map<String, FileTransferInfo> _transferInfos = {};
  final Map<String, FileInfo> _fileInfos = {};
  StreamSubscription? _transferStatusSubscription;

  // 设置
  int _maxFileSizeMB = 100; // 最大文件大小（MB）
  bool _autoDownload = false; // 自动下载
  bool _compressImages = true; // 压缩图片
  String _downloadPath = ''; // 下载路径

  // Getters
  List<FileTransferInfo> get allTransfers => _transferInfos.values.toList();
  List<FileTransferInfo> get activeTransfers => _transferInfos.values
      .where((info) =>
          info.status == FileTransferStatus.uploading ||
          info.status == FileTransferStatus.downloading)
      .toList();
  List<FileTransferInfo> get completedTransfers => _transferInfos.values
      .where((info) => info.status == FileTransferStatus.completed)
      .toList();
  List<FileTransferInfo> get failedTransfers => _transferInfos.values
      .where((info) => info.status == FileTransferStatus.failed)
      .toList();

  int get maxFileSizeMB => _maxFileSizeMB;
  bool get autoDownload => _autoDownload;
  bool get compressImages => _compressImages;
  String get downloadPath => _downloadPath;

  /// 初始化
  Future<void> initialize() async {
    try {
      await _loadSettings();
      await _setupDownloadPath();
      _setupTransferStatusListener();
      _logger.info('文件传输ViewModel初始化完成');
    } catch (e) {
      _logger.error('文件传输ViewModel初始化失败: $e');
      rethrow;
    }
  }

  /// 销毁
  @override
  void dispose() {
    _transferStatusSubscription?.cancel();
    _fileService.dispose();
    super.dispose();
  }

  /// 选择并上传图片
  Future<List<String>> selectAndUploadImages({
    bool multiple = false,
    String? uploadUrl,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final files = await _fileService.pickImages(multiple: multiple);
      if (files.isEmpty) return [];

      final uploadedUrls = <String>[];
      for (final file in files) {
        if (_validateFileSize(file)) {
          final url = await _uploadFile(file, uploadUrl, extraData);
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      }

      return uploadedUrls;
    } catch (e) {
      _logger.error('选择并上传图片失败: $e');
      rethrow;
    }
  }

  /// 拍照并上传
  Future<String?> takePhotoAndUpload({
    String? uploadUrl,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final file = await _fileService.takePhoto();
      if (file == null) return null;

      if (_validateFileSize(file)) {
        return await _uploadFile(file, uploadUrl, extraData);
      }
      return null;
    } catch (e) {
      _logger.error('拍照并上传失败: $e');
      rethrow;
    }
  }

  /// 选择并上传视频
  Future<String?> selectAndUploadVideo({
    String? uploadUrl,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final file = await _fileService.pickVideo();
      if (file == null) return null;

      if (_validateFileSize(file)) {
        return await _uploadFile(file, uploadUrl, extraData);
      }
      return null;
    } catch (e) {
      _logger.error('选择并上传视频失败: $e');
      rethrow;
    }
  }

  /// 选择并上传文件
  Future<List<String>> selectAndUploadFiles({
    bool multiple = false,
    List<String>? allowedExtensions,
    AppFileType? type,
    String? uploadUrl,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final files = await _fileService.pickFiles(
        multiple: multiple,
        allowedExtensions: allowedExtensions,
        type: type,
      );
      if (files.isEmpty) return [];

      final uploadedUrls = <String>[];
      for (final file in files) {
        if (_validateFileSize(file)) {
          final url = await _uploadFile(file, uploadUrl, extraData);
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      }

      return uploadedUrls;
    } catch (e) {
      _logger.error('选择并上传文件失败: $e');
      rethrow;
    }
  }

  /// 下载文件
  Future<String?> downloadFile(
    String downloadUrl,
    String fileName, {
    String? customPath,
  }) async {
    try {
      final savePath = customPath ?? path.join(_downloadPath, fileName);
      
      final filePath = await _fileService.downloadFile(
        downloadUrl,
        fileName,
        savePath: savePath,
      );

      if (filePath != null) {
        _logger.info('文件下载完成: $filePath');
      }

      return filePath;
    } catch (e) {
      _logger.error('下载文件失败: $e');
      rethrow;
    }
  }

  /// 取消传输
  Future<void> cancelTransfer(String transferId) async {
    try {
      await _fileService.cancelTransfer(transferId);
      _logger.info('取消传输: $transferId');
    } catch (e) {
      _logger.error('取消传输失败: $e');
      rethrow;
    }
  }

  /// 重试传输
  Future<void> retryTransfer(String transferId) async {
    try {
      final transferInfo = _transferInfos[transferId];
      final fileInfo = _fileInfos[transferId];
      
      if (transferInfo != null && fileInfo != null) {
        // 重新开始传输
        if (transferInfo.status == FileTransferStatus.failed) {
          // 这里需要根据原始传输类型决定是上传还是下载
          // 暂时记录日志
          _logger.info('重试传输: $transferId');
        }
      }
    } catch (e) {
      _logger.error('重试传输失败: $e');
      rethrow;
    }
  }

  /// 清理已完成的传输记录
  void clearCompletedTransfers() {
    final completedIds = _transferInfos.entries
        .where((entry) => entry.value.status == FileTransferStatus.completed)
        .map((entry) => entry.key)
        .toList();

    for (final id in completedIds) {
      _transferInfos.remove(id);
      _fileInfos.remove(id);
    }

    notifyListeners();
    _logger.info('清理了${completedIds.length}个已完成的传输记录');
  }

  /// 清理失败的传输记录
  void clearFailedTransfers() {
    final failedIds = _transferInfos.entries
        .where((entry) => entry.value.status == FileTransferStatus.failed)
        .map((entry) => entry.key)
        .toList();

    for (final id in failedIds) {
      _transferInfos.remove(id);
      _fileInfos.remove(id);
    }

    notifyListeners();
    _logger.info('清理了${failedIds.length}个失败的传输记录');
  }

  /// 获取传输信息
  FileTransferInfo? getTransferInfo(String transferId) {
    return _transferInfos[transferId];
  }

  /// 获取文件信息
  FileInfo? getFileInfo(String transferId) {
    return _fileInfos[transferId];
  }

  /// 设置最大文件大小
  Future<void> setMaxFileSizeMB(int sizeMB) async {
    _maxFileSizeMB = sizeMB;
    await _saveSettings();
    notifyListeners();
    _logger.info('设置最大文件大小: ${sizeMB}MB');
  }

  /// 设置自动下载
  Future<void> setAutoDownload(bool enabled) async {
    _autoDownload = enabled;
    await _saveSettings();
    notifyListeners();
    _logger.info('设置自动下载: $enabled');
  }

  /// 设置图片压缩
  Future<void> setCompressImages(bool enabled) async {
    _compressImages = enabled;
    await _saveSettings();
    notifyListeners();
    _logger.info('设置图片压缩: $enabled');
  }

  /// 设置下载路径
  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
    await _saveSettings();
    notifyListeners();
    _logger.info('设置下载路径: $path');
  }

  /// 获取传输统计
  Map<String, int> getTransferStatistics() {
    final stats = {
      'total': _transferInfos.length,
      'uploading': 0,
      'downloading': 0,
      'completed': 0,
      'failed': 0,
      'cancelled': 0,
    };

    for (final info in _transferInfos.values) {
      switch (info.status) {
        case FileTransferStatus.uploading:
          stats['uploading'] = stats['uploading']! + 1;
          break;
        case FileTransferStatus.downloading:
          stats['downloading'] = stats['downloading']! + 1;
          break;
        case FileTransferStatus.completed:
          stats['completed'] = stats['completed']! + 1;
          break;
        case FileTransferStatus.failed:
          stats['failed'] = stats['failed']! + 1;
          break;
        case FileTransferStatus.cancelled:
          stats['cancelled'] = stats['cancelled']! + 1;
          break;
        default:
          break;
      }
    }

    return stats;
  }

  /// 上传文件
  Future<String?> _uploadFile(
    FileInfo fileInfo,
    String? uploadUrl,
    Map<String, dynamic>? extraData,
  ) async {
    if (uploadUrl == null) {
      throw Exception('上传URL不能为空');
    }

    try {
      String filePath = fileInfo.path;
      
      // 如果是图片且启用压缩
      if (_compressImages && fileInfo.type == AppFileType.image) {
        final compressedPath = await _fileService.compressImage(filePath);
        if (compressedPath != null) {
          filePath = compressedPath;
        }
      }

      final url = await _fileService.uploadFile(
        filePath,
        uploadUrl,
        extraData: extraData,
      );

      return url;
    } catch (e) {
      _logger.error('上传文件失败: $e');
      rethrow;
    }
  }

  /// 验证文件大小
  bool _validateFileSize(FileInfo fileInfo) {
    if (FileUtils.isFileSizeExceeded(fileInfo.size, _maxFileSizeMB)) {
      _logger.warning(
        '文件大小超过限制: ${FileUtils.formatFileSize(fileInfo.size)} > ${_maxFileSizeMB}MB',
      );
      return false;
    }
    return true;
  }

  /// 设置传输状态监听器
  void _setupTransferStatusListener() {
    _transferStatusSubscription = _fileService.transferStatusStream.listen(
      (transferInfo) {
        _transferInfos[transferInfo.id] = transferInfo;
        notifyListeners();
      },
    );
  }

  /// 设置下载路径
  Future<void> _setupDownloadPath() async {
    if (_downloadPath.isEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      _downloadPath = path.join(directory.path, 'downloads');
      
      // 确保下载目录存在
      await FileUtils.createDirectory(_downloadPath);
    }
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      _maxFileSizeMB = await _localStorage.getInt('max_file_size_mb') ?? 100;
      _autoDownload = await _localStorage.getBool('auto_download') ?? false;
      _compressImages = await _localStorage.getBool('compress_images') ?? true;
      _downloadPath = await _localStorage.getString('download_path') ?? '';
      
      _logger.info('加载文件传输设置完成');
    } catch (e) {
      _logger.error('加载文件传输设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      await _localStorage.setInt('max_file_size_mb', _maxFileSizeMB);
      await _localStorage.setBool('auto_download', _autoDownload);
      await _localStorage.setBool('compress_images', _compressImages);
      await _localStorage.setString('download_path', _downloadPath);
      
      _logger.info('保存文件传输设置完成');
    } catch (e) {
      _logger.error('保存文件传输设置失败: $e');
    }
  }
}