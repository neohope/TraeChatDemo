import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import '../utils/app_logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static ApiService get instance => _instance;

  late Dio _dio;
  final AppLogger _logger = AppLogger.instance;
  
  // 基础配置
  static const String _baseUrl = 'http://localhost:3000/api';
  static const int _connectTimeout = 30000;
  static const int _receiveTimeout = 30000;
  static const int _sendTimeout = 30000;

  /// 初始化API服务
  void initialize({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _baseUrl,
      connectTimeout: Duration(milliseconds: _connectTimeout),
      receiveTimeout: Duration(milliseconds: _receiveTimeout),
      sendTimeout: Duration(milliseconds: _sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createLoggingInterceptor());
    _dio.interceptors.add(_createErrorInterceptor());
  }

  /// 创建认证拦截器
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加认证token
        final token = await LocalStorage.getAuthToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 处理401错误，尝试刷新token
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // 重试原请求
            final options = error.requestOptions;
            final token = await LocalStorage.getAuthToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            
            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              // 重试失败，继续原错误处理
            }
          }
        }
        handler.next(error);
      },
    );
  }

  /// 创建日志拦截器
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.logger.d('API请求: ${options.method} ${options.uri}');
        if (options.data != null) {
          _logger.logger.d('请求数据: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.logger.d('API响应: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.logger.e('API错误: ${error.message}');
        if (error.response != null) {
          _logger.logger.e('错误响应: ${error.response?.data}');
        }
        handler.next(error);
      },
    );
  }

  /// 创建错误处理拦截器
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final errorMessage = _handleError(error);
        final modifiedError = DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: errorMessage,
          message: errorMessage,
        );
        handler.next(modifiedError);
      },
    );
  }

  /// 处理错误信息
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络连接';
      case DioExceptionType.sendTimeout:
        return '发送超时，请重试';
      case DioExceptionType.receiveTimeout:
        return '接收超时，请重试';
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.unknown:
        return '网络错误，请检查网络连接';
      default:
        return '未知错误';
    }
  }

  /// 处理HTTP错误
  String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '禁止访问';
      case 404:
        return '请求的资源不存在';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      default:
        return '服务器错误 ($statusCode)';
    }
  }

  /// 刷新token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        await LocalStorage.saveAuthToken(newToken);
        if (newRefreshToken != null) {
          await LocalStorage.saveRefreshToken(newRefreshToken);
        }

        _logger.logger.i('Token刷新成功');
        return true;
      }
    } catch (e) {
      _logger.logger.e('Token刷新失败: $e');
      // 清除无效的认证信息
      await LocalStorage.clearAuthInfo();
    }
    return false;
  }

  /// GET请求
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _createApiException(e);
    }
  }

  /// POST请求
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _createApiException(e);
    }
  }

  /// PUT请求
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _createApiException(e);
    }
  }

  /// DELETE请求
  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _createApiException(e);
    }
  }

  /// 上传文件
  Future<Map<String, dynamic>> uploadFile(
    String path,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      return _processResponse(response);
    } on DioException catch (e) {
      throw _createApiException(e);
    }
  }

  /// 下载文件
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _createApiException(e);
    }
  }

  /// 处理响应数据
  Map<String, dynamic> _processResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data;
    } else if (response.data is String) {
      try {
        return json.decode(response.data);
      } catch (e) {
        return {'data': response.data, 'success': true};
      }
    } else {
      return {'data': response.data, 'success': true};
    }
  }

  /// 创建API异常
  ApiException _createApiException(DioException error) {
    return ApiException(
      message: error.message ?? '未知错误',
      statusCode: error.response?.statusCode,
      data: error.response?.data,
    );
  }

  /// 取消所有请求
  void cancelRequests() {
    _dio.interceptors.clear();
  }

  /// 获取Dio实例（用于特殊需求）
  Dio get dio => _dio;
}

/// API异常类
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}