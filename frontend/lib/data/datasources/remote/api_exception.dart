/// API异常类
/// 
/// 用于处理API请求异常
class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException({
    required this.statusCode,
    required this.message,
  });
  
  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}