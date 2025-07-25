import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static AudioService get instance => _instance;

  final AppLogger _logger = AppLogger.instance;
  
  // 录音状态
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isInitialized = false;
  
  // 录音配置
  static const int _sampleRate = 44100;
  static const int _bitRate = 128000;
  
  // 事件流控制器
  final StreamController<AudioRecordingState> _recordingStateController = 
      StreamController<AudioRecordingState>.broadcast();
  final StreamController<AudioPlaybackState> _playbackStateController = 
      StreamController<AudioPlaybackState>.broadcast();
  final StreamController<Duration> _recordingDurationController = 
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _playbackPositionController = 
      StreamController<Duration>.broadcast();
  
  // 计时器
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  /// 录音状态流
  Stream<AudioRecordingState> get recordingStateStream => _recordingStateController.stream;
  
  /// 播放状态流
  Stream<AudioPlaybackState> get playbackStateStream => _playbackStateController.stream;
  
  /// 录音时长流
  Stream<Duration> get recordingDurationStream => _recordingDurationController.stream;
  
  /// 播放位置流
  Stream<Duration> get playbackPositionStream => _playbackPositionController.stream;
  
  /// 是否正在录音
  bool get isRecording => _isRecording;
  
  /// 是否正在播放
  bool get isPlaying => _isPlaying;
  
  /// 当前录音时长
  Duration get recordingDuration => _recordingDuration;
  
  /// 当前播放位置
  Duration get playbackPosition => _playbackPosition;
  
  /// 总时长
  Duration get totalDuration => _totalDuration;
  
  /// 初始化音频服务
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }
    
    try {
      // 检查权限
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _logger.logger.w('音频权限未授予');
        return false;
      }
      
      // 在Web平台上，音频功能有限
      if (kIsWeb) {
        _logger.logger.i('Web平台音频服务初始化（功能有限）');
        _isInitialized = true;
        return true;
      }
      
      // 移动平台初始化
      _logger.logger.i('音频服务初始化成功');
      _isInitialized = true;
      return true;
    } catch (e) {
      _logger.logger.e('音频服务初始化失败: $e');
      return false;
    }
  }
  
  /// 检查音频权限
  Future<bool> _checkPermissions() async {
    if (kIsWeb) {
      // Web平台权限处理
      return true;
    }
    
    try {
      final microphoneStatus = await Permission.microphone.status;
      
      if (microphoneStatus.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      
      return microphoneStatus.isGranted;
    } catch (e) {
      _logger.logger.e('检查音频权限失败: $e');
      return false;
    }
  }
  
  /// 开始录音
  Future<bool> startRecording({String? outputPath}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
    }
    
    if (_isRecording) {
      _logger.logger.w('已在录音中');
      return false;
    }
    
    try {
      // Web平台录音实现
      if (kIsWeb) {
        return await _startWebRecording();
      }
      
      // 移动平台录音实现
      return await _startMobileRecording(outputPath);
    } catch (e) {
      _logger.logger.e('开始录音失败: $e');
      return false;
    }
  }
  
  /// Web平台录音
  Future<bool> _startWebRecording() async {
    try {
      // 模拟录音状态（实际实现需要使用Web API）
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _recordingStateController.add(AudioRecordingState.recording);
      
      _startRecordingTimer();
      _logger.logger.i('Web录音开始');
      return true;
    } catch (e) {
      _logger.logger.e('Web录音开始失败: $e');
      return false;
    }
  }
  
  /// 移动平台录音
  Future<bool> _startMobileRecording(String? outputPath) async {
    try {
      // 这里应该使用实际的录音插件，如 flutter_sound 或 record
      // 由于没有具体插件，这里提供模拟实现
      
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _recordingStateController.add(AudioRecordingState.recording);
      
      _startRecordingTimer();
      _logger.logger.i('移动端录音开始');
      return true;
    } catch (e) {
      _logger.logger.e('移动端录音开始失败: $e');
      return false;
    }
  }
  
  /// 停止录音
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      _logger.logger.w('当前未在录音');
      return null;
    }
    
    try {
      _isRecording = false;
      _stopRecordingTimer();
      _recordingStateController.add(AudioRecordingState.stopped);
      
      // 返回录音文件路径（模拟）
      final filePath = '/temp/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      _logger.logger.i('录音停止，文件路径: $filePath');
      return filePath;
    } catch (e) {
      _logger.logger.e('停止录音失败: $e');
      return null;
    }
  }
  
  /// 暂停录音
  Future<bool> pauseRecording() async {
    if (!_isRecording) {
      return false;
    }
    
    try {
      _stopRecordingTimer();
      _recordingStateController.add(AudioRecordingState.paused);
      _logger.logger.i('录音已暂停');
      return true;
    } catch (e) {
      _logger.logger.e('暂停录音失败: $e');
      return false;
    }
  }
  
  /// 恢复录音
  Future<bool> resumeRecording() async {
    try {
      _startRecordingTimer();
      _recordingStateController.add(AudioRecordingState.recording);
      _logger.logger.i('录音已恢复');
      return true;
    } catch (e) {
      _logger.logger.e('恢复录音失败: $e');
      return false;
    }
  }
  
  /// 播放音频文件
  Future<bool> playAudio(String filePath) async {
    if (_isPlaying) {
      await stopPlayback();
    }
    
    try {
      _isPlaying = true;
      _playbackPosition = Duration.zero;
      _totalDuration = Duration(seconds: 30); // 模拟时长
      _playbackStateController.add(AudioPlaybackState.playing);
      
      _startPlaybackTimer();
      _logger.logger.i('开始播放音频: $filePath');
      return true;
    } catch (e) {
      _logger.logger.e('播放音频失败: $e');
      return false;
    }
  }
  
  /// 停止播放
  Future<bool> stopPlayback() async {
    if (!_isPlaying) {
      return false;
    }
    
    try {
      _isPlaying = false;
      _stopPlaybackTimer();
      _playbackPosition = Duration.zero;
      _playbackStateController.add(AudioPlaybackState.stopped);
      _logger.logger.i('音频播放已停止');
      return true;
    } catch (e) {
      _logger.logger.e('停止播放失败: $e');
      return false;
    }
  }
  
  /// 暂停播放
  Future<bool> pausePlayback() async {
    if (!_isPlaying) {
      return false;
    }
    
    try {
      _stopPlaybackTimer();
      _playbackStateController.add(AudioPlaybackState.paused);
      _logger.logger.i('音频播放已暂停');
      return true;
    } catch (e) {
      _logger.logger.e('暂停播放失败: $e');
      return false;
    }
  }
  
  /// 恢复播放
  Future<bool> resumePlayback() async {
    try {
      _startPlaybackTimer();
      _playbackStateController.add(AudioPlaybackState.playing);
      _logger.logger.i('音频播放已恢复');
      return true;
    } catch (e) {
      _logger.logger.e('恢复播放失败: $e');
      return false;
    }
  }
  
  /// 跳转到指定位置
  Future<bool> seekTo(Duration position) async {
    if (!_isPlaying) {
      return false;
    }
    
    try {
      _playbackPosition = position;
      _playbackPositionController.add(_playbackPosition);
      _logger.logger.i('跳转到位置: ${position.inSeconds}秒');
      return true;
    } catch (e) {
      _logger.logger.e('跳转失败: $e');
      return false;
    }
  }
  
  /// 设置播放音量
  Future<bool> setVolume(double volume) async {
    try {
      // 音量范围 0.0 - 1.0
      final clampedVolume = volume.clamp(0.0, 1.0);
      _logger.logger.i('设置音量: $clampedVolume');
      return true;
    } catch (e) {
      _logger.logger.e('设置音量失败: $e');
      return false;
    }
  }
  
  /// 获取音频文件信息
  Future<AudioFileInfo?> getAudioFileInfo(String filePath) async {
    try {
      // 模拟获取音频文件信息
      return AudioFileInfo(
        filePath: filePath,
        duration: Duration(seconds: 30),
        size: 1024 * 1024, // 1MB
        format: 'aac',
        sampleRate: _sampleRate,
        bitRate: _bitRate,
      );
    } catch (e) {
      _logger.logger.e('获取音频文件信息失败: $e');
      return null;
    }
  }
  
  /// 开始录音计时器
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _recordingDuration = Duration(milliseconds: _recordingDuration.inMilliseconds + 100);
      _recordingDurationController.add(_recordingDuration);
    });
  }
  
  /// 停止录音计时器
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }
  
  /// 开始播放计时器
  void _startPlaybackTimer() {
    _playbackTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _playbackPosition = Duration(milliseconds: _playbackPosition.inMilliseconds + 100);
      _playbackPositionController.add(_playbackPosition);
      
      // 播放完成
      if (_playbackPosition >= _totalDuration) {
        stopPlayback();
      }
    });
  }
  
  /// 停止播放计时器
  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }
  
  /// 销毁服务
  void dispose() {
    stopRecording();
    stopPlayback();
    _recordingStateController.close();
    _playbackStateController.close();
    _recordingDurationController.close();
    _playbackPositionController.close();
  }
}

/// 录音状态枚举
enum AudioRecordingState {
  idle,
  recording,
  paused,
  stopped,
}

/// 播放状态枚举
enum AudioPlaybackState {
  idle,
  playing,
  paused,
  stopped,
  completed,
}

/// 音频文件信息
class AudioFileInfo {
  final String filePath;
  final Duration duration;
  final int size;
  final String format;
  final int sampleRate;
  final int bitRate;
  
  AudioFileInfo({
    required this.filePath,
    required this.duration,
    required this.size,
    required this.format,
    required this.sampleRate,
    required this.bitRate,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'size': size,
      'format': format,
      'sampleRate': sampleRate,
      'bitRate': bitRate,
    };
  }
  
  factory AudioFileInfo.fromJson(Map<String, dynamic> json) {
    return AudioFileInfo(
      filePath: json['filePath'] ?? '',
      duration: Duration(milliseconds: json['duration'] ?? 0),
      size: json['size'] ?? 0,
      format: json['format'] ?? '',
      sampleRate: json['sampleRate'] ?? 44100,
      bitRate: json['bitRate'] ?? 128000,
    );
  }
}