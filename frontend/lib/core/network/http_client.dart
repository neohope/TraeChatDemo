import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../storage/local_storage.dart';
import '../utils/app_logger.dart';

/// 网络请求工具类，用于管理HTTP请求
class HttpClient {
  // 单例模式
  static final HttpClient _instance = HttpClient._internal();
  static HttpClient get instance => _instance;
  
  late Dio _dio;
  Dio get dio => _dio;
  
  // 日志实例
  final _logger = AppLogger.instance.logger;
  
  // 私有构造函数
  HttpClient._internal() {
    _initDio();
  }
  
  // 初始化Dio
  void _initDio() {
    final options = BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.instance.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.instance.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    _dio = Dio(options);
    
    // 添加拦截器
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) {
        if (AppConfig.instance.isDebug) {
          _logger.d(object.toString());
        }
      },
    ));
    
    // 添加认证拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 不为登录和注册请求添加认证令牌
        if (!options.path.contains('/login') && !options.path.contains('/register')) {
          final token = await LocalStorage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // 处理401错误（未授权）
        if (error.response?.statusCode == 401) {
          // 尝试刷新令牌
          if (await _refreshToken()) {
            // 重试请求
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  // 刷新令牌
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      
      // 创建新的Dio实例，避免循环拦截
      final tokenDio = Dio(BaseOptions(
        baseUrl: AppConfig.instance.apiBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      final response = await tokenDio.post(
        '/api/v1/auth/refresh',
        data: jsonEncode({'refresh_token': refreshToken}),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // 保存新令牌
        final newToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await LocalStorage.saveAuthToken(newToken);
        await LocalStorage.saveRefreshToken(newRefreshToken);
        
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('刷新令牌失败: $e');
      return false;
    }
  }
  
  // 重试请求
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
  
  // GET请求
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('GET请求失败: $path, 错误: $e');
      rethrow;
    }
  }
  
  // POST请求
  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('POST请求失败: $path, 错误: $e');
      rethrow;
    }
  }
  
  // PUT请求
  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('PUT请求失败: $path, 错误: $e');
      rethrow;
    }
  }
  
  // DELETE请求
  Future<Response> delete(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      _logger.e('DELETE请求失败: $path, 错误: $e');
      rethrow;
    }
  }
  
  // 上传文件
  Future<Response> uploadFile(String path, File file, {
    String? fileName,
    Map<String, dynamic>? extraData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      
      // 添加文件
      final fileBaseName = fileName ?? file.path.split('/').last;
      final fileExtension = fileBaseName.split('.').last;
      String mimeType = 'application/octet-stream';
      
      // 根据扩展名设置MIME类型
      switch (fileExtension.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mp3':
          mimeType = 'audio/mpeg';
          break;
      }
      
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(
          file.path,
          filename: fileBaseName,
          contentType: MediaType.parse(mimeType),
        ),
      ));
      
      // 添加额外数据
      if (extraData != null) {
        extraData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      return await _dio.post(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      _logger.e('上传文件失败: $path, 错误: $e');
      rethrow;
    }
  }
  
  // 下载文件
  Future<Response> downloadFile(String url, String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('下载文件失败: $url, 错误: $e');
      rethrow;
    }
  }
  
  /// 设置认证令牌
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _logger.i('已设置认证令牌');
  }
  
  /// 清除认证令牌
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    _logger.i('已清除认证令牌');
  }
}