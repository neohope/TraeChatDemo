/// API响应模型类，用于统一处理API返回数据
class ApiResponse<T> {
  /// 请求是否成功
  final bool success;
  
  /// 响应数据
  final T? data;
  
  /// 响应消息
  final String? message;
  
  /// 错误代码
  final String? errorCode;
  
  /// 构造函数
  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });
  
  /// 成功响应构造函数
  factory ApiResponse.success(T? data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message ?? '操作成功',
    );
  }
  
  /// 错误响应构造函数
  factory ApiResponse.error(String message, {String? errorCode, T? data}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errorCode: errorCode,
      data: data,
    );
  }
  
  /// 从JSON映射创建实例
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'],
      errorCode: json['errorCode'],
    );
  }
  
  /// 转换为JSON映射
  Map<String, dynamic> toJson(dynamic Function(T?) toJsonT) {
    return {
      'success': success,
      'data': data != null ? toJsonT(data) : null,
      'message': message,
      'errorCode': errorCode,
    };
  }
  
  /// 创建新实例并更新数据
  ApiResponse<T> copyWith({
    bool? success,
    T? data,
    String? message,
    String? errorCode,
  }) {
    return ApiResponse<T>(
      success: success ?? this.success,
      data: data ?? this.data,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
    );
  }
  
  /// 将当前响应转换为新类型
  ApiResponse<R> cast<R>(R? Function(T?) converter) {
    return ApiResponse<R>(
      success: success,
      data: converter(data),
      message: message,
      errorCode: errorCode,
    );
  }
  
  @override
  String toString() {
    return 'ApiResponse{success: $success, data: $data, message: $message, errorCode: $errorCode}';
  }
}