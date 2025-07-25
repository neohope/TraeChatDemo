import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 应用日志工具类，用于统一管理日志
class AppLogger {
  // 单例模式
  static final AppLogger _instance = AppLogger._internal();
  static AppLogger get instance => _instance;
  
  late Logger _logger;
  Logger get logger => _logger;
  
  // 日志文件路径
  String? _logFilePath;
  String? get logFilePath => _logFilePath;
  
  // 私有构造函数
  AppLogger._internal() {
    _initLogger();
  }
  
  // 初始化日志记录器
  void _initLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // 显示的方法调用数量
        errorMethodCount: 8, // 错误时显示的方法调用数量
        lineLength: 120, // 每行最大长度
        colors: true, // 彩色日志
        printEmojis: true, // 打印表情符号
        printTime: true, // 打印时间
      ),
      level: kDebugMode ? Level.verbose : Level.info, // 根据环境设置日志级别
    );
  }
  
  // 初始化文件日志
  Future<void> initFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDirectory = Directory('${directory.path}/logs');
      
      if (!await logDirectory.exists()) {
        await logDirectory.create(recursive: true);
      }
      
      final now = DateTime.now();
      final fileName = 'chat_app_${now.year}-${now.month}-${now.day}.log';
      _logFilePath = '${logDirectory.path}/$fileName';
      
      // 创建文件输出
      final fileOutput = FileOutput(file: File(_logFilePath!));
      
      // 创建多输出日志记录器
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: false, // 文件日志不需要颜色
          printEmojis: false,
          printTime: true,
        ),
        level: kDebugMode ? Level.verbose : Level.info,
        output: MultiOutput([ConsoleOutput(), fileOutput]),
      );
      
      _logger.i('文件日志初始化成功: $_logFilePath');
    } catch (e) {
      _logger.e('初始化文件日志失败: $e');
    }
  }
  
  // 获取所有日志文件
  Future<List<File>> getLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDirectory = Directory('${directory.path}/logs');
      
      if (!await logDirectory.exists()) {
        return [];
      }
      
      final files = await logDirectory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .map((entity) => entity as File)
          .toList();
      
      return files;
    } catch (e) {
      _logger.e('获取日志文件失败: $e');
      return [];
    }
  }
  
  // 清除所有日志文件
  Future<bool> clearAllLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDirectory = Directory('${directory.path}/logs');
      
      if (await logDirectory.exists()) {
        await logDirectory.delete(recursive: true);
        await logDirectory.create();
        _logger.i('所有日志文件已清除');
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('清除日志文件失败: $e');
      return false;
    }
  }
  
  // 便捷日志方法
  void verbose(String message) => _logger.v(message);
  void debug(String message) => _logger.d(message);
  void info(String message) => _logger.i(message);
  void warning(String message) => _logger.w(message);
  void error(String message) => _logger.e(message);
}

// 文件输出类
class FileOutput extends LogOutput {
  final File file;
  IOSink? _sink;
  
  FileOutput({required this.file}) {
    _sink = file.openWrite(mode: FileMode.append);
  }
  
  @override
  void output(OutputEvent event) {
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }
  
  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}