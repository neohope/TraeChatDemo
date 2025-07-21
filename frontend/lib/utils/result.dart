/// 结果类
/// 
/// 用于封装操作结果，可以是成功或失败
class Result<T> {
  final T? _data;
  final String? _error;
  final bool _isSuccess;
  
  Result._({T? data, String? error, required bool isSuccess})
      : _data = data,
        _error = error,
        _isSuccess = isSuccess;
  
  /// 创建成功结果
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }
  
  /// 创建失败结果
  factory Result.error(String error) {
    return Result._(error: error, isSuccess: false);
  }
  
  /// 处理结果
  R when<R>({
    required R Function(T) success,
    required R Function(String) error,
  }) {
    if (_isSuccess) {
      return success(_data as T);
    } else {
      return error(_error!);
    }
  }
  
  /// 是否成功
  bool get isSuccess => _isSuccess;
  
  /// 是否失败
  bool get isError => !_isSuccess;
  
  /// 获取数据（如果成功）
  T? get data => _isSuccess ? _data : null;
  
  /// 获取错误信息（如果失败）
  String? get error => _isSuccess ? null : _error;
}