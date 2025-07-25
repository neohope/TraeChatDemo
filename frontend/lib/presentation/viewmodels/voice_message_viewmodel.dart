import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../data/services/audio_service.dart';
import '../../data/services/local_storage.dart';
import '../../core/utils/app_logger.dart';

/// 语音消息ViewModel
class VoiceMessageViewModel extends ChangeNotifier {
  final AudioService _audioService;
  final LocalStorage _localStorage;
  final AppLogger _logger;

  VoiceMessageViewModel({
    AudioService? audioService,
    LocalStorage? localStorage,
    AppLogger? logger,
  })  : _audioService = audioService ?? AudioService(),
        _localStorage = localStorage ?? LocalStorage(),
        _logger = logger ?? AppLogger.instance;

  // 录制状态
  bool _isRecording = false;
  bool _isRecordingPaused = false;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;
  Timer? _recordingTimer;

  // 播放状态
  String? _currentPlayingMessageId;
  bool _isPlaying = false;
  Duration _playingPosition = Duration.zero;
  Duration _playingDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  // 语音消息缓存
  final Map<String, String> _voiceMessagePaths = {};
  final Map<String, Duration> _voiceMessageDurations = {};

  // Getters
  bool get isRecording => _isRecording;
  bool get isRecordingPaused => _isRecordingPaused;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  
  String? get currentPlayingMessageId => _currentPlayingMessageId;
  bool get isPlaying => _isPlaying;
  Duration get playingPosition => _playingPosition;
  Duration get playingDuration => _playingDuration;
  double get playbackSpeed => _playbackSpeed;

  /// 初始化
  Future<void> initialize() async {
    try {
      await _audioService.initialize();
      await _loadVoiceMessageCache();
      _setupAudioListeners();
      _logger.info('语音消息ViewModel初始化完成');
    } catch (e) {
      _logger.error('语音消息ViewModel初始化失败: $e');
      rethrow;
    }
  }

  /// 销毁
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  /// 开始录制
  Future<String?> startRecording() async {
    try {
      if (_isRecording) {
        _logger.warning('已在录制中，忽略重复请求');
        return null;
      }

      final success = await _audioService.startRecording();
      if (success == true) {
        _isRecording = true;
        _isRecordingPaused = false;
        _recordingDuration = Duration.zero;
        _currentRecordingPath = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        _startRecordingTimer();
        notifyListeners();
        
        _logger.info('开始录制语音: $_currentRecordingPath');
        return _currentRecordingPath;
      }
      return null;
    } catch (e) {
      _logger.error('开始录制失败: $e');
      rethrow;
    }
  }

  /// 暂停录制
  Future<void> pauseRecording() async {
    try {
      if (!_isRecording || _isRecordingPaused) return;

      await _audioService.pauseRecording();
      _isRecordingPaused = true;
      _recordingTimer?.cancel();
      
      notifyListeners();
      _logger.info('暂停录制');
    } catch (e) {
      _logger.error('暂停录制失败: $e');
      rethrow;
    }
  }

  /// 恢复录制
  Future<void> resumeRecording() async {
    try {
      if (!_isRecording || !_isRecordingPaused) return;

      await _audioService.resumeRecording();
      _isRecordingPaused = false;
      _startRecordingTimer();
      
      notifyListeners();
      _logger.info('恢复录制');
    } catch (e) {
      _logger.error('恢复录制失败: $e');
      rethrow;
    }
  }

  /// 停止录制
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final success = await _audioService.stopRecording();
      _stopRecordingTimer();
      
      _isRecording = false;
      _isRecordingPaused = false;
      final duration = _recordingDuration;
      final recordingPath = _currentRecordingPath;
      _recordingDuration = Duration.zero;
      _currentRecordingPath = null;
      
      notifyListeners();
      
      if (success == true && recordingPath != null) {
        // 缓存录制的语音文件信息
        await _cacheVoiceMessage(recordingPath, duration);
        _logger.info('录制完成: $recordingPath, 时长: ${duration.inSeconds}秒');
        return recordingPath;
      }
    } catch (e) {
      _logger.error('停止录制失败: $e');
      rethrow;
    }
    return null;
  }

  /// 取消录制
  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;

      await _audioService.cancelRecording();
      _stopRecordingTimer();
      
      // 删除录制文件
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _isRecording = false;
      _isRecordingPaused = false;
      _recordingDuration = Duration.zero;
      _currentRecordingPath = null;
      
      notifyListeners();
      _logger.info('取消录制');
    } catch (e) {
      _logger.error('取消录制失败: $e');
      rethrow;
    }
  }

  /// 播放语音消息
  Future<void> playVoiceMessage(String messageId, String audioPath) async {
    try {
      // 如果正在播放同一条消息，则暂停
      if (_currentPlayingMessageId == messageId && _isPlaying) {
        await pausePlaying();
        return;
      }
      
      // 如果正在播放其他消息，先停止
      if (_currentPlayingMessageId != null && _currentPlayingMessageId != messageId) {
        await stopPlaying();
      }

      _currentPlayingMessageId = messageId;
      await _audioService.playAudio(audioPath);
      
      _logger.info('开始播放语音消息: $messageId');
    } catch (e) {
      _logger.error('播放语音消息失败: $e');
      rethrow;
    }
  }

  /// 暂停播放
  Future<void> pausePlaying() async {
    try {
      await _audioService.pausePlaying();
      _logger.info('暂停播放');
    } catch (e) {
      _logger.error('暂停播放失败: $e');
      rethrow;
    }
  }

  /// 恢复播放
  Future<void> resumePlaying() async {
    try {
      await _audioService.resumePlaying();
      _logger.info('恢复播放');
    } catch (e) {
      _logger.error('恢复播放失败: $e');
      rethrow;
    }
  }

  /// 停止播放
  Future<void> stopPlaying() async {
    try {
      await _audioService.stopPlaying();
      _currentPlayingMessageId = null;
      _isPlaying = false;
      _playingPosition = Duration.zero;
      _playingDuration = Duration.zero;
      
      notifyListeners();
      _logger.info('停止播放');
    } catch (e) {
      _logger.error('停止播放失败: $e');
      rethrow;
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    try {
      await _audioService.seekTo(position);
      _logger.info('跳转到: ${position.inSeconds}秒');
    } catch (e) {
      _logger.error('跳转失败: $e');
      rethrow;
    }
  }

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioService.setPlaybackSpeed(speed);
      _playbackSpeed = speed;
      notifyListeners();
      _logger.info('设置播放速度: ${speed}x');
    } catch (e) {
      _logger.error('设置播放速度失败: $e');
      rethrow;
    }
  }

  /// 获取语音消息时长
  Duration? getVoiceMessageDuration(String messageId) {
    return _voiceMessageDurations[messageId];
  }

  /// 获取语音消息路径
  String? getVoiceMessagePath(String messageId) {
    return _voiceMessagePaths[messageId];
  }

  /// 检查消息是否正在播放
  bool isMessagePlaying(String messageId) {
    return _currentPlayingMessageId == messageId && _isPlaying;
  }

  /// 保存语音消息到本地
  Future<String> saveVoiceMessage(String tempPath, String messageId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final voiceDir = Directory(path.join(directory.path, 'voice_messages'));
      
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }
      
      final fileName = '${messageId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final savedPath = path.join(voiceDir.path, fileName);
      
      final tempFile = File(tempPath);
      final savedFile = await tempFile.copy(savedPath);
      
      // 删除临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      _logger.info('语音消息已保存: $savedPath');
      return savedFile.path;
    } catch (e) {
      _logger.error('保存语音消息失败: $e');
      rethrow;
    }
  }

  /// 删除语音消息文件
  Future<void> deleteVoiceMessage(String messageId) async {
    try {
      final audioPath = _voiceMessagePaths[messageId];
      if (audioPath != null) {
        final file = File(audioPath);
        if (await file.exists()) {
          await file.delete();
        }
        
        _voiceMessagePaths.remove(messageId);
        _voiceMessageDurations.remove(messageId);
        
        await _saveVoiceMessageCache();
        _logger.info('删除语音消息: $messageId');
      }
    } catch (e) {
      _logger.error('删除语音消息失败: $e');
    }
  }

  /// 清理过期的语音消息
  Future<void> cleanupExpiredVoiceMessages({int maxDays = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final voiceDir = Directory(path.join(directory.path, 'voice_messages'));
      
      if (!await voiceDir.exists()) return;
      
      final now = DateTime.now();
      final expiredTime = now.subtract(Duration(days: maxDays));
      
      await for (final entity in voiceDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(expiredTime)) {
            await entity.delete();
            _logger.info('删除过期语音文件: ${entity.path}');
          }
        }
      }
      
      // 清理缓存中的过期记录
      final expiredKeys = <String>[];
      for (final entry in _voiceMessagePaths.entries) {
        final file = File(entry.value);
        if (!await file.exists()) {
          expiredKeys.add(entry.key);
        }
      }
      
      for (final key in expiredKeys) {
        _voiceMessagePaths.remove(key);
        _voiceMessageDurations.remove(key);
      }
      
      if (expiredKeys.isNotEmpty) {
        await _saveVoiceMessageCache();
      }
      
      _logger.info('清理完成，删除了${expiredKeys.length}个过期记录');
    } catch (e) {
      _logger.error('清理过期语音消息失败: $e');
    }
  }

  /// 开始录制计时器
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isRecordingPaused) {
        _recordingDuration = Duration(seconds: timer.tick);
        notifyListeners();
      }
    });
  }

  /// 停止录制计时器
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// 设置音频监听器
  void _setupAudioListeners() {
    // TODO: 实现音频监听器 - 需要根据实际AudioService接口调整
    // 播放状态监听
    // _audioService.playbackStateStream.listen((state) {
    //   _isPlaying = state == AudioPlaybackState.playing;
    //   notifyListeners();
    // });
    
    // 播放位置监听
    // _audioService.playbackPositionStream.listen((position) {
    //   _playingPosition = position;
    //   notifyListeners();
    // });
    
    // 播放时长通过totalDuration获取
    // _playingDuration = _audioService.totalDuration;
  }

  /// 缓存语音消息信息
  Future<void> _cacheVoiceMessage(String path, Duration duration) async {
    try {
      final messageId = path.split('/').last.split('.').first;
      _voiceMessagePaths[messageId] = path;
      _voiceMessageDurations[messageId] = duration;
      
      await _saveVoiceMessageCache();
    } catch (e) {
      _logger.error('缓存语音消息信息失败: $e');
    }
  }

  /// 加载语音消息缓存
  Future<void> _loadVoiceMessageCache() async {
    try {
      final pathsData = await _localStorage.getString('voice_message_paths');
      final durationsData = await _localStorage.getString('voice_message_durations');
      
      if (pathsData != null) {
        final pathsMap = Map<String, String>.from(
          Map<String, dynamic>.from(pathsData as Map),
        );
        _voiceMessagePaths.addAll(pathsMap);
      }
      
      if (durationsData != null) {
        final durationsMap = Map<String, dynamic>.from(durationsData as Map);
        for (final entry in durationsMap.entries) {
          _voiceMessageDurations[entry.key] = Duration(
            milliseconds: entry.value as int,
          );
        }
      }
      
      _logger.info('加载语音消息缓存: ${_voiceMessagePaths.length}条记录');
    } catch (e) {
      _logger.error('加载语音消息缓存失败: $e');
    }
  }

  /// 保存语音消息缓存
  Future<void> _saveVoiceMessageCache() async {
    try {
      // Convert maps to JSON strings for storage
      final pathsJson = _voiceMessagePaths.entries
          .map((e) => '"${e.key}":"${e.value}"')
          .join(',');
      await _localStorage.setString('voice_message_paths', '{$pathsJson}');
      
      final durationsMap = <String, int>{};
      for (final entry in _voiceMessageDurations.entries) {
        durationsMap[entry.key] = entry.value.inMilliseconds;
      }
      final durationsJson = durationsMap.entries
          .map((e) => '"${e.key}":${e.value}')
          .join(',');
      await _localStorage.setString('voice_message_durations', '{$durationsJson}');
      
      _logger.info('保存语音消息缓存: ${_voiceMessagePaths.length}条记录');
    } catch (e) {
      _logger.error('保存语音消息缓存失败: $e');
    }
  }
}