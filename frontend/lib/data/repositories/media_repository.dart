import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

/// 媒体仓库类，用于管理媒体文件的上传、下载和处理
class MediaRepository {
  // 单例模式
  static final MediaRepository _instance = MediaRepository._internal();
  static MediaRepository get instance => _instance;
  
  // API服务
  final _apiService = ApiService.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  MediaRepository._internal();
  
  /// 上传图片文件
  Future<ApiResponse<String>> uploadImage(File imageFile, {ProgressCallback? onProgress}) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/upload/image',
        imageFile,
        onSendProgress: onProgress,
      );
      
      if (response.success && response.data != null) {
        final imageUrl = response.data!['url'] as String;
        return ApiResponse<String>.success(imageUrl);
      } else {
        return ApiResponse<String>.error(response.message ?? '上传图片失败');
      }
    } catch (e) {
      _logger.e('上传图片失败: $e');
      return ApiResponse<String>.error('上传图片失败: $e');
    }
  }
  
  /// 上传语音文件
  Future<ApiResponse<Map<String, dynamic>>> uploadVoice(File voiceFile, {ProgressCallback? onProgress}) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/upload/voice',
        voiceFile,
        onSendProgress: onProgress,
      );
      
      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(response.message ?? '上传语音失败');
      }
    } catch (e) {
      _logger.e('上传语音失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('上传语音失败: $e');
    }
  }
  
  /// 上传视频文件
  Future<ApiResponse<Map<String, dynamic>>> uploadVideo(File videoFile, {ProgressCallback? onProgress}) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/upload/video',
        videoFile,
        onSendProgress: onProgress,
      );
      
      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(response.message ?? '上传视频失败');
      }
    } catch (e) {
      _logger.e('上传视频失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('上传视频失败: $e');
    }
  }
  
  /// 上传文件（如文档、压缩包等）
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(File file, {ProgressCallback? onProgress}) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/upload/file',
        file,
        onSendProgress: onProgress,
      );
      
      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(response.message ?? '上传文件失败');
      }
    } catch (e) {
      _logger.e('上传文件失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('上传文件失败: $e');
    }
  }
  
  /// 下载文件
  Future<ApiResponse<String>> downloadFile(String url, String savePath, {ProgressCallback? onProgress}) async {
    try {
      final response = await _apiService.downloadFile(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );
      
      if (response.success) {
        return ApiResponse<String>.success(savePath);
      } else {
        return ApiResponse<String>.error(response.message ?? '下载文件失败');
      }
    } catch (e) {
      _logger.e('下载文件失败: $e');
      return ApiResponse<String>.error('下载文件失败: $e');
    }
  }
  
  /// 获取媒体文件的缩略图
  Future<ApiResponse<String>> getThumbnail(String mediaUrl) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/media/thumbnail',
        queryParameters: {'url': mediaUrl},
      );
      
      if (response.success && response.data != null) {
        final thumbnailUrl = response.data!['thumbnail_url'] as String;
        return ApiResponse<String>.success(thumbnailUrl);
      } else {
        return ApiResponse<String>.error(response.message ?? '获取缩略图失败');
      }
    } catch (e) {
      _logger.e('获取缩略图失败: $e');
      return ApiResponse<String>.error('获取缩略图失败: $e');
    }
  }
  
  /// 获取媒体文件的元数据（如文件大小、时长、分辨率等）
  Future<ApiResponse<Map<String, dynamic>>> getMediaMetadata(String mediaUrl) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/media/metadata',
        queryParameters: {'url': mediaUrl},
      );
      
      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(response.message ?? '获取媒体元数据失败');
      }
    } catch (e) {
      _logger.e('获取媒体元数据失败: $e');
      return ApiResponse<Map<String, dynamic>>.error('获取媒体元数据失败: $e');
    }
  }
  
  /// 压缩图片
  Future<ApiResponse<File>> compressImage(File imageFile, {int quality = 80}) async {
    try {
      // 这里可以使用第三方库如flutter_image_compress进行图片压缩
      // 由于这是一个本地操作，我们这里只是模拟一个API调用
      _logger.i('压缩图片: ${imageFile.path}, 质量: $quality');
      
      // 实际应用中，这里应该调用图片压缩库
      // 这里简单返回原图片作为示例
      return ApiResponse<File>.success(imageFile);
    } catch (e) {
      _logger.e('压缩图片失败: $e');
      return ApiResponse<File>.error('压缩图片失败: $e');
    }
  }
  
  /// 生成语音消息的波形数据
  Future<ApiResponse<List<double>>> generateWaveform(File audioFile) async {
    try {
      // 这里可以使用第三方库如flutter_audio_waveforms进行波形生成
      // 由于这是一个本地操作，我们这里只是模拟一个API调用
      _logger.i('生成波形数据: ${audioFile.path}');
      
      // 实际应用中，这里应该调用波形生成库
      // 这里简单返回一些随机数据作为示例
      final waveform = List.generate(50, (index) => (index % 10) / 10);
      return ApiResponse<List<double>>.success(waveform);
    } catch (e) {
      _logger.e('生成波形数据失败: $e');
      return ApiResponse<List<double>>.error('生成波形数据失败: $e');
    }
  }
  
  /// 清除本地缓存的媒体文件
  Future<ApiResponse<bool>> clearMediaCache() async {
    try {
      // 清除本地存储中的媒体缓存
      await LocalStorage.clearMediaCache();
      return ApiResponse<bool>.success(true);
    } catch (e) {
      _logger.e('清除媒体缓存失败: $e');
      return ApiResponse<bool>.error('清除媒体缓存失败: $e');
    }
  }
}