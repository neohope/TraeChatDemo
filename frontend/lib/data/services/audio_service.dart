import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/utils/app_logger.dart';

/// 音频录制状态
enum AudioRecordingState {
  idle,      // 空闲
  recording, // 录制中
  paused,    // 暂停
  stopped,   // 已停止
}

/// 音频播放状态
enum AudioPlayingState {
  idle,    // 空闲
  loading, // 加载中
  playing, // 播放中
  paused,  // 暂停
  stopped, // 已停止
  completed, // 播放完成
}

/// 音频信息模型
class AudioInfo {
  final String path;
  final Duration duration;
  final int fileSize;
  final DateTime createdAt;

  const AudioInfo({
    required this.path,
    required this.duration,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'duration': duration.inMilliseconds,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudioInfo.fromJson(Map<String, dynamic> json) {
    return AudioInfo(
      path: json['path'],
      duration: Duration(milliseconds: json['duration']),
      fileSize: json['fileSize'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// 音频服务
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Record _recorder = Record();
  final AudioPlayer _player = AudioPlayer();
  final _logger = AppLogger.instance.logger;

  // 录制相关状态
  AudioRecordingState _recordingState = AudioRecordingState.idle;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  StreamController<Duration>? _recordingDurationController;
  StreamController<double>? _recordingAmplitudeController;

  // 播放相关状态
  AudioPlayingState _playingState = AudioPlayingState.idle;
  String? _currentPlayingPath;
  Duration _playingDuration = Duration.zero;
  Duration _playingPosition = Duration.zero;
  StreamController<Duration>? _playingPositionController;
  StreamController<AudioPlayingState>? _playingStateController;

  // Getters
  AudioRecordingState get recordingState => _recordingState;
  AudioPlayingState get playingState => _playingState;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get currentPlayingPath => _currentPlayingPath;
  Duration get recordingDuration => _recordingDuration;
  Duration get playingDuration => _playingDuration;
  Duration get playingPosition => _playingPosition;

  // Streams
  Stream<Duration> get recordingDurationStream => _recordingDurationController?.stream ?? const Stream.empty();
  Stream<double> get recordingAmplitudeStream => _recordingAmplitudeController?.stream ?? const Stream.empty();
  Stream<Duration> get playingPositionStream => _playingPositionController?.stream ?? const Stream.empty();
  Stream<AudioPlayingState> get playingStateStream => _playingStateController?.stream ?? const Stream.empty();

  /// 初始化音频服务
  Future<void> initialize() async {
    try {
      // 初始化流控制器
      _recordingDurationController = StreamController<Duration>.broadcast();
      _recordingAmplitudeController = StreamController<double>.broadcast();
      _playingPositionController = StreamController<Duration>.broadcast();
      _playingStateController = StreamController<AudioPlayingState>.broadcast();

      // 监听播放器状态变化
      _player.playerStateStream.listen((state) {
        switch (state.processingState) {
          case ProcessingState.idle:
            _setPlayingState(AudioPlayingState.idle);
            break;
          case ProcessingState.loading:
            _setPlayingState(AudioPlayingState.loading);
            break;
          case ProcessingState.buffering:
            _setPlayingState(AudioPlayingState.loading);
            break;
          case ProcessingState.ready:
            if (state.playing) {
              _setPlayingState(AudioPlayingState.playing);
            } else {
              _setPlayingState(AudioPlayingState.paused);
            }
            break;
          case ProcessingState.completed:
            _setPlayingState(AudioPlayingState.completed);
            break;
        }
      });

      // 监听播放位置变化
      _player.positionStream.listen((position) {
        _playingPosition = position;
        _playingPositionController?.add(position);
      });

      // 监听播放时长变化
      _player.durationStream.listen((duration) {
        if (duration != null) {
          _playingDuration = duration;
        }
      });

      _logger.i('音频服务初始化成功');
    } catch (e) {
      _logger.e('音频服务初始化失败: $e');
      rethrow;
    }
  }

  /// 请求录音权限
  Future<bool> requestRecordPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      _logger.e('请求录音权限失败: $e');
      return false;
    }
  }

  /// 检查录音权限
  Future<bool> hasRecordPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      _logger.e('检查录音权限失败: $e');
      return false;
    }
  }

  /// 开始录音
  Future<bool> startRecording() async {
    try {
      // 检查权限
      if (!await hasRecordPermission()) {
        if (!await requestRecordPermission()) {
          _logger.w('录音权限被拒绝');
          return false;
        }
      }

      // 检查是否支持录音
      if (!await _recorder.hasPermission()) {
        _logger.w('设备不支持录音');
        return false;
      }

      // 生成录音文件路径
      final directory = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      // 开始录音
      await _recorder.start(path: _currentRecordingPath!);
      
      _setRecordingState(AudioRecordingState.recording);
      _startRecordingTimer();
      
      _logger.i('开始录音: $_currentRecordingPath');
      return true;
    } catch (e) {
      _logger.e('开始录音失败: $e');
      return false;
    }
  }

  /// 暂停录音
  Future<bool> pauseRecording() async {
    try {
      if (_recordingState != AudioRecordingState.recording) {
        return false;
      }

      await _recorder.pause();
      _setRecordingState(AudioRecordingState.paused);
      _stopRecordingTimer();
      
      _logger.i('暂停录音');
      return true;
    } catch (e) {
      _logger.e('暂停录音失败: $e');
      return false;
    }
  }

  /// 恢复录音
  Future<bool> resumeRecording() async {
    try {
      if (_recordingState != AudioRecordingState.paused) {
        return false;
      }

      await _recorder.resume();
      _setRecordingState(AudioRecordingState.recording);
      _startRecordingTimer();
      
      _logger.i('恢复录音');
      return true;
    } catch (e) {
      _logger.e('恢复录音失败: $e');
      return false;
    }
  }

  /// 停止录音
  Future<AudioInfo?> stopRecording() async {
    try {
      if (_recordingState == AudioRecordingState.idle) {
        return null;
      }

      final path = await _recorder.stop();
      _setRecordingState(AudioRecordingState.stopped);
      _stopRecordingTimer();

      if (path != null && await File(path).exists()) {
        final file = File(path);
        final fileSize = await file.length();
        
        final audioInfo = AudioInfo(
          path: path,
          duration: _recordingDuration,
          fileSize: fileSize,
          createdAt: DateTime.now(),
        );
        
        _logger.i('录音完成: $path, 时长: ${_recordingDuration.inSeconds}秒');
        _resetRecordingState();
        
        return audioInfo;
      } else {
        _logger.w('录音文件不存在');
        _resetRecordingState();
        return null;
      }
    } catch (e) {
      _logger.e('停止录音失败: $e');
      _resetRecordingState();
      return null;
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    try {
      if (_recordingState != AudioRecordingState.idle) {
        await _recorder.stop();
        
        // 删除录音文件
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        _resetRecordingState();
        _logger.i('取消录音');
      }
    } catch (e) {
      _logger.e('取消录音失败: $e');
    }
  }

  /// 播放音频
  Future<bool> playAudio(String path) async {
    try {
      // 停止当前播放
      await stopPlaying();
      
      _currentPlayingPath = path;
      
      // 设置音频源
      if (path.startsWith('http')) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      
      // 开始播放
      await _player.play();
      
      _logger.i('开始播放音频: $path');
      return true;
    } catch (e) {
      _logger.e('播放音频失败: $e');
      return false;
    }
  }

  /// 暂停播放
  Future<void> pausePlaying() async {
    try {
      await _player.pause();
      _logger.i('暂停播放');
    } catch (e) {
      _logger.e('暂停播放失败: $e');
    }
  }

  /// 恢复播放
  Future<void> resumePlaying() async {
    try {
      await _player.play();
      _logger.i('恢复播放');
    } catch (e) {
      _logger.e('恢复播放失败: $e');
    }
  }

  /// 停止播放
  Future<void> stopPlaying() async {
    try {
      await _player.stop();
      _currentPlayingPath = null;
      _logger.i('停止播放');
    } catch (e) {
      _logger.e('停止播放失败: $e');
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      _logger.e('跳转播放位置失败: $e');
    }
  }

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      _logger.e('设置播放速度失败: $e');
    }
  }

  /// 获取音频时长
  Future<Duration?> getAudioDuration(String path) async {
    try {
      final tempPlayer = AudioPlayer();
      
      if (path.startsWith('http')) {
        await tempPlayer.setUrl(path);
      } else {
        await tempPlayer.setFilePath(path);
      }
      
      final duration = tempPlayer.duration;
      await tempPlayer.dispose();
      
      return duration;
    } catch (e) {
      _logger.e('获取音频时长失败: $e');
      return null;
    }
  }

  /// 开始录音计时器
  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _recordingDuration = Duration(milliseconds: timer.tick * 100);
      _recordingDurationController?.add(_recordingDuration);
      
      // 获取录音振幅（模拟数据）
      _recordingAmplitudeController?.add(0.5 + (timer.tick % 10) * 0.05);
    });
  }

  /// 停止录音计时器
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// 设置录音状态
  void _setRecordingState(AudioRecordingState state) {
    _recordingState = state;
  }

  /// 设置播放状态
  void _setPlayingState(AudioPlayingState state) {
    _playingState = state;
    _playingStateController?.add(state);
  }

  /// 重置录音状态
  void _resetRecordingState() {
    _recordingState = AudioRecordingState.idle;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    _stopRecordingTimer();
  }

  /// 销毁服务
  Future<void> dispose() async {
    try {
      await _recorder.dispose();
      await _player.dispose();
      
      _recordingTimer?.cancel();
      
      await _recordingDurationController?.close();
      await _recordingAmplitudeController?.close();
      await _playingPositionController?.close();
      await _playingStateController?.close();
      
      _logger.i('音频服务已销毁');
    } catch (e) {
      _logger.e('销毁音频服务失败: $e');
    }
  }
}