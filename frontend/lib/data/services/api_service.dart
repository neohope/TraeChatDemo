import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/http_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/api_response.dart';

/// API服务类，用于封装与后端API的交互
class ApiService {
  // 单例模式
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;
  
  // HTTP客户端
  final _httpClient = HttpClient.instance;
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  ApiService._internal();

  /// 检查用户是否已认证
  Future<bool> isAuthenticated() async {
    // 这里的逻辑是检查本地是否存有有效的token
    final token = await LocalStorage.getAuthToken();
    return token != null && token.isNotEmpty;
  }
  
  // 通用请求处理方法
  Future<ApiResponse<T>> _handleResponse<T>(
    Future<Response> Function() requestFunction,
  ) async {
    try {
      final response = await requestFunction();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          final Map<String, dynamic> responseData = response.data;
          
          // 检查API响应格式
          if (responseData.containsKey('success') && responseData.containsKey('data')) {
            final bool success = responseData['success'];
            final dynamic data = responseData['data'];
            final String? message = responseData['message'];
            
            if (success) {
              return ApiResponse<T>.success(data as T, message: message);
            } else {
              return ApiResponse<T>.error(message ?? '未知错误');
            }
          } else if (responseData.containsKey('token') && responseData.containsKey('user')) {
            // 处理登录API的特殊响应格式 {token, user}
            return ApiResponse<T>.success(response.data);
          } else {
            // 直接返回数据
            return ApiResponse<T>.success(response.data);
          }
        } else {
          // 直接返回数据
          return ApiResponse<T>.success(response.data);
        }
      } else {
        final errorMessage = _getErrorMessage(response);
        _logger.e('API错误: $errorMessage');
        return ApiResponse<T>.error(errorMessage);
      }
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);
      _logger.e('Dio错误: $errorMessage');
      return ApiResponse<T>.error(errorMessage);
    } catch (e) {
      _logger.e('未知错误: $e');
      return ApiResponse<T>.error('发生未知错误: $e');
    }
  }
  
  // 处理Dio错误
  String _handleDioError(DioException error) {
    _logger.e('Dio error details: ${error.response?.data}');
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送请求超时，请稍后重试';
      case DioExceptionType.receiveTimeout:
        return '接收响应超时，请稍后重试';
      case DioExceptionType.badCertificate:
        return '证书验证失败';
      case DioExceptionType.badResponse:
        return _getErrorMessage(error.response);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接错误，请检查网络';
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return '网络连接失败，请检查网络';
        }
        return '未知错误: ${error.message}';
      // ignore: unreachable_switch_default
      default:
        return '请求失败: ${error.message}';
    }
  }
  
  // 从响应中获取错误信息
  String _getErrorMessage(Response? response) {
    if (response == null) {
      return '服务器无响应';
    }
    
    try {
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;
        if (data.containsKey('message')) {
          return data['message'];
        } else if (data.containsKey('error')) {
          return data['error'];
        }
      } else if (response.data is String) {
        return response.data;
      }
      
      return '服务器错误: ${response.statusCode}';
    } catch (e) {
      return '解析错误响应失败: $e';
    }
  }
  
  // GET请求
  Future<ApiResponse<T>> get<T>(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _handleResponse<T>(() => _httpClient.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }
  
  // POST请求
  Future<ApiResponse<T>> post<T>(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _handleResponse<T>(() => _httpClient.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }
  
  // PUT请求
  Future<ApiResponse<T>> put<T>(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _handleResponse<T>(() => _httpClient.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }
  
  // DELETE请求
  Future<ApiResponse<T>> delete<T>(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _handleResponse<T>(() => _httpClient.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }
  
  // 上传文件
  Future<ApiResponse<T>> uploadFile<T>(String path, File file, {
    String? fileName,
    Map<String, dynamic>? extraData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _handleResponse<T>(() => _httpClient.uploadFile(
      path,
      file,
      fileName: fileName,
      extraData: extraData,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    ));
  }
  
  // 下载文件
  Future<ApiResponse<String>> downloadFile(String url, String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _httpClient.downloadFile(
        url,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      
      return ApiResponse<String>.success(savePath, message: '文件下载成功');
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);
      _logger.e('下载文件错误: $errorMessage');
      return ApiResponse<String>.error(errorMessage);
    } catch (e) {
      _logger.e('下载文件未知错误: $e');
      return ApiResponse<String>.error('下载文件时发生错误: $e');
    }
  }
}