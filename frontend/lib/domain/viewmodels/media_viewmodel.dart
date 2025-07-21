import 'dart:io';

import 'package:flutter/foundation.dart';
// 导入 dio 包以使用 ProgressCallback 类型
import 'package:dio/dio.dart' show ProgressCallback;

import '../../data/models/api_response.dart';
import '../../data/repositories/media_repository.dart';

/// 媒体视图模型，用于管理媒体相关的UI状态和业务逻辑
class MediaViewModel extends ChangeNotifier {
  // 媒体仓库实例
  final _mediaRepository = MediaRepository.instance;
  
  // 上传进度
  double _uploadProgress = 0.0;
  // 下载进度
  double _downloadProgress = 0.0;
  
  // 是否正在上传
  bool _isUploading = false;
  // 是否正在下载
  bool _isDownloading = false;
  // 错误信息
  String? _errorMessage;
  
  // 上传进度回调
  late final ProgressCallback _updateUploadProgress;
  // 下载进度回调
  late final ProgressCallback _updateDownloadProgress;
  
  MediaViewModel() {
    // 初始化上传进度回调
    _updateUploadProgress = (int count, int total) {
      _uploadProgress = total > 0 ? count / total : 0;
      notifyListeners();
    };
    
    // 初始化下载进度回调
    _updateDownloadProgress = (int count, int total) {
      _downloadProgress = total > 0 ? count / total : 0;
      notifyListeners();
    };
  }
  
  /// 获取上传进度
  double get uploadProgress => _uploadProgress;
  
  /// 获取下载进度
  double get downloadProgress => _downloadProgress;
  
  /// 是否正在上传
  bool get isUploading => _isUploading;
  
  /// 是否正在下载
  bool get isDownloading => _isDownloading;
  
  /// 获取错误信息
  String? get errorMessage => _errorMessage;
  
  /// 上传图片
  Future<ApiResponse<String>> uploadImage(File imageFile) async {
    _setUploading(true);
    _resetUploadProgress();
    _clearError();
    
    try {
      final response = await _mediaRepository.uploadImage(
        imageFile,
        onProgress: _updateUploadProgress,
      );
      
      if (!response.success) {
        _setError(response.message ?? '上传图片失败');
      }
      
      return response;
    } catch (e) {
      _setError('上传图片失败: $e');
      return ApiResponse<String>.error('上传图片失败: $e');
    } finally {
      _setUploading(false);
    }
  }
  
  /// 上传语音
  Future<ApiResponse<Map<String, dynamic>>> uploadVoice(File voiceFile) async {
    _setUploading(true);
    _resetUploadProgress();
    _clearError();
    
    try {
      final response = await _mediaRepository.uploadVoice(
        voiceFile,
        onProgress: _updateUploadProgress,
      );
      
      if (!response.success) {
        _setError(response.message ?? '上传语音失败');
      }
      
      return response;
    } catch (e) {
      _setError('上传语音失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('上传语音失败: $e');
    } finally {
      _setUploading(false);
    }
  }
  
  /// 上传视频
  Future<ApiResponse<Map<String, dynamic>>> uploadVideo(File videoFile) async {
    _setUploading(true);
    _resetUploadProgress();
    _clearError();
    
    try {
      final response = await _mediaRepository.uploadVideo(
        videoFile,
        onProgress: _updateUploadProgress,
      );
      
      if (!response.success) {
        _setError(response.message ?? '上传视频失败');
      }
      
      return response;
    } catch (e) {
      _setError('上传视频失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('上传视频失败: $e');
    } finally {
      _setUploading(false);
    }
  }
  
  /// 上传文件
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(File file) async {
    _setUploading(true);
    _resetUploadProgress();
    _clearError();
    
    try {
      final response = await _mediaRepository.uploadFile(
        file,
        onProgress: _updateUploadProgress,
      );
      
      if (!response.success) {
        _setError(response.message ?? '上传文件失败');
      }
      
      return response;
    } catch (e) {
      _setError('上传文件失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('上传文件失败: $e');
    } finally {
      _setUploading(false);
    }
  }
  
  /// 下载媒体文件
  Future<ApiResponse<String>> downloadMedia(String url, String savePath) async {
    _setDownloading(true);
    _resetDownloadProgress();
    _clearError();
    
    try {
      final response = await _mediaRepository.downloadFile(
        url,
        savePath,
        onProgress: _updateDownloadProgress,
      );
      
      if (!response.success) {
        _setError(response.message ?? '下载媒体失败');
      }
      
      return response;
    } catch (e) {
      _setError('下载媒体失败: $e');
      return ApiResponse<String>.error('下载媒体失败: $e');
    } finally {
      _setDownloading(false);
    }
  }
  
  /// 获取媒体缩略图
  Future<ApiResponse<String>> getThumbnail(String mediaUrl) async {
    _clearError();
    
    try {
      return await _mediaRepository.getThumbnail(mediaUrl);
    } catch (e) {
      _setError('获取缩略图失败: $e');
      return ApiResponse<String>.error('获取缩略图失败: $e');
    }
  }
  
  /// 获取媒体元数据
  Future<ApiResponse<Map<String, dynamic>>> getMediaMetadata(String mediaUrl) async {
    _clearError();
    
    try {
      return await _mediaRepository.getMediaMetadata(mediaUrl);
    } catch (e) {
      _setError('获取媒体元数据失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('获取媒体元数据失败: $e');
    }
  }
  
  /// 压缩图片
  Future<ApiResponse<File>> compressImage(File imageFile, {int quality = 80}) async {
    _clearError();
    
    try {
      return await _mediaRepository.compressImage(imageFile, quality: quality);
    } catch (e) {
      _setError('压缩图片失败: $e');
      return ApiResponse<File>.error('压缩图片失败: $e');
    }
  }
  
  /// 生成语音波形数据
  Future<ApiResponse<List<double>>> generateWaveformData(File audioFile) async {
    _clearError();
    
    try {
      return await _mediaRepository.generateWaveform(audioFile);
    } catch (e) {
      _setError('生成波形数据失败: $e');
      return ApiResponse<List<double>>.error('生成波形数据失败: $e');
    }
  }
  
  /// 清除媒体缓存
  Future<ApiResponse<bool>> clearMediaCache() async {
    _clearError();
    
    try {
      return await _mediaRepository.clearMediaCache();
    } catch (e) {
      _setError('清除媒体缓存失败: $e');
      return ApiResponse<bool>.error('清除媒体缓存失败: $e');
    }
  }
  
  /// 重置上传进度
  void _resetUploadProgress() {
    _uploadProgress = 0.0;
    notifyListeners();
  }
  
  /// 重置下载进度
  void _resetDownloadProgress() {
    _downloadProgress = 0.0;
    notifyListeners();
  }
  
  /// 设置上传状态
  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }
  
  /// 设置下载状态
  void _setDownloading(bool downloading) {
    _isDownloading = downloading;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}