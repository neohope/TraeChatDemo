import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../domain/services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/result.dart';
import '../datasources/remote/api_exception.dart';

/// 存储服务实现
/// 
/// 实现了文件上传和下载功能
class StorageServiceImpl implements StorageService {
  final http.Client _client;
  final String _baseUrl;
  final Map<String, String> _headers;
  
  StorageServiceImpl({
    required http.Client client,
    required String baseUrl,
    required String authToken,
  }) : _client = client,
       _baseUrl = baseUrl,
       _headers = {
         'Authorization': 'Bearer $authToken',
       };
  
  @override
  Future<Result<String>> uploadFile({
    required String filePath,
    required String fileType,
  }) async {
    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.error('File not found');
      }
      
      // 检查文件大小
      final fileSize = await file.length();
      if (fileType == 'image' && fileSize > Constants.maxImageSize) {
        return Result.error('Image size exceeds the maximum allowed size (${Constants.maxImageSize / (1024 * 1024)} MB)');
      } else if (fileSize > Constants.maxFileSize) {
        return Result.error('File size exceeds the maximum allowed size (${Constants.maxFileSize / (1024 * 1024)} MB)');
      }
      
      // 检查文件扩展名
      final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
      if (fileType == 'image' && !Constants.allowedImageExtensions.contains(extension)) {
        return Result.error('Image type not allowed. Allowed types: ${Constants.allowedImageExtensions.join(', ')}');
      } else if (fileType == 'file' && !Constants.allowedFileExtensions.contains(extension)) {
        return Result.error('File type not allowed. Allowed types: ${Constants.allowedFileExtensions.join(', ')}');
      }
      
      // 创建multipart请求
      final url = Uri.parse('$_baseUrl/storage/upload');
      final request = http.MultipartRequest('POST', url);
      
      // 添加文件
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(filePath),
      );
      
      // 添加请求头和字段
      request.headers.addAll(_headers);
      request.fields['fileType'] = fileType;
      request.files.add(multipartFile);
      
      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final fileUrl = response.body;
        return Result.success(fileUrl);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to upload file',
        );
      }
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      return Result.error(Constants.networkErrorMessage);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<String>> downloadFile({
    required String fileUrl,
    required String localPath,
  }) async {
    try {
      // 发送GET请求下载文件
      final response = await _client.get(Uri.parse(fileUrl), headers: _headers);
      
      if (response.statusCode == 200) {
        // 创建本地文件
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        
        return Result.success(localPath);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to download file',
        );
      }
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      return Result.error(Constants.networkErrorMessage);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<void>> deleteFile(String fileUrl) async {
    try {
      // 从URL中提取文件ID
      final fileId = _extractFileIdFromUrl(fileUrl);
      if (fileId == null) {
        return Result.error('Invalid file URL');
      }
      
      // 发送DELETE请求删除文件
      final url = Uri.parse('$_baseUrl/storage/delete/$fileId');
      final response = await _client.delete(url, headers: _headers);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return Result.success(null);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to delete file',
        );
      }
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      return Result.error(Constants.networkErrorMessage);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<Map<String, dynamic>>> getFileInfo(String fileUrl) async {
    try {
      // 从URL中提取文件ID
      final fileId = _extractFileIdFromUrl(fileUrl);
      if (fileId == null) {
        return Result.error('Invalid file URL');
      }
      
      // 发送GET请求获取文件信息
      final url = Uri.parse('$_baseUrl/storage/info/$fileId');
      final response = await _client.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Result.success(data);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to get file info',
        );
      }
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      return Result.error(Constants.networkErrorMessage);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  @override
  Future<Result<String>> generateThumbnail({
    required String fileUrl,
    required int width,
    required int height,
  }) async {
    try {
      // 从URL中提取文件ID
      final fileId = _extractFileIdFromUrl(fileUrl);
      if (fileId == null) {
        return Result.error('Invalid file URL');
      }
      
      // 发送GET请求生成缩略图
      final url = Uri.parse('$_baseUrl/storage/thumbnail/$fileId?width=$width&height=$height');
      final response = await _client.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final thumbnailUrl = response.body;
        return Result.success(thumbnailUrl);
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to generate thumbnail',
        );
      }
    } on ApiException catch (e) {
      return Result.error(e.message);
    } on SocketException {
      return Result.error(Constants.networkErrorMessage);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
  
  /// 从URL中提取文件ID
  String? _extractFileIdFromUrl(String fileUrl) {
    // 示例URL: https://api.chatapp.com/v1/storage/files/1234567890
    final uri = Uri.parse(fileUrl);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length >= 2) {
      return pathSegments.last;
    }
    
    return null;
  }
}