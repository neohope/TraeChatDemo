import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/services/audio_service.dart';
import '../../../core/utils/app_logger.dart';
// import 'voice_message_widget.dart'; // Unused import

/// 语音录制按钮组件
class VoiceRecordButton extends StatefulWidget {
  final Function(String audioPath, Duration duration)? onVoiceRecorded;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingCancel;
  final bool enabled;
  final double size;

  const VoiceRecordButton({
    Key? key,
    this.onVoiceRecorded,
    this.onRecordingStart,
    this.onRecordingCancel,
    this.enabled = true,
    this.size = 48,
  }) : super(key: key);

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final _logger = AppLogger.instance.logger;

  late AnimationController _scaleAnimationController;
  late AnimationController _rippleAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  bool _isRecording = false;
  bool _isPermissionGranted = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }

  void _initializeAnimations() {
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _rippleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleAnimationController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.status;
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.microphone.request();
    final granted = status.isGranted;
    
    setState(() {
      _isPermissionGranted = granted;
    });
    
    if (!granted && mounted) {
      _showPermissionDialog();
    }
    
    return granted;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要麦克风权限'),
        content: const Text('为了录制语音消息，请允许应用访问您的麦克风。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _rippleAnimationController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimationController,
          _rippleAnimationController,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 涟漪效果
              if (_isRecording)
                Container(
                  width: widget.size * 2 * _rippleAnimation.value,
                  height: widget.size * 2 * _rippleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withValues(
                      alpha: 0.3 * (1 - _rippleAnimation.value),
                    ),
                  ),
                ),
              
              // 主按钮
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : (widget.enabled
                            ? Theme.of(context).primaryColor
                            : Colors.grey),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Theme.of(context).primaryColor)
                            .withValues(alpha: 0.3),
                        blurRadius: _isRecording ? 12 : 6,
                        spreadRadius: _isRecording ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
              
              // 录音时长显示
              if (_isRecording)
                Positioned(
                  bottom: -30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onTap() {
    if (!widget.enabled) return;
    
    HapticFeedback.lightImpact();
    
    if (_isRecording) {
      _stopRecording();
    } else {
      _showRecordingInstructions();
    }
  }

  void _showRecordingInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('录制语音'),
        content: const Text('长按按钮开始录制语音消息，松开结束录制。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    if (!widget.enabled) return;
    
    HapticFeedback.mediumImpact();
    
    if (!_isPermissionGranted) {
      final granted = await _requestPermissions();
      if (!granted) return;
    }
    
    await _startRecording();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isRecording) return;
    
    HapticFeedback.lightImpact();
    _stopRecording();
  }

  void _onLongPressCancel() {
    if (!_isRecording) return;
    
    HapticFeedback.lightImpact();
    _cancelRecording();
  }

  Future<void> _startRecording() async {
    try {
      _logger.i('开始录制语音');
      
      final success = await _audioService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
          _currentRecordingPath = _audioService.currentRecordingPath;
        });
        
        _scaleAnimationController.forward();
        _rippleAnimationController.repeat();
        
        _startDurationTimer();
        widget.onRecordingStart?.call();
        
        _logger.i('录制开始，路径: $_currentRecordingPath');
      } else {
        _logger.e('开始录制失败');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('录制失败')),
          );
        }
      }
    } catch (e) {
      _logger.e('开始录制失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录制失败: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      _logger.i('停止录制语音');
      
      final audioInfo = await _audioService.stopRecording();
      _stopDurationTimer();
      
      setState(() {
        _isRecording = false;
      });
      
      _scaleAnimationController.reverse();
      _rippleAnimationController.stop();
      _rippleAnimationController.reset();
      
      if (audioInfo != null && _recordingDuration.inSeconds >= 1) {
        // 检查文件是否存在
        final file = File(audioInfo.path);
        if (await file.exists()) {
          widget.onVoiceRecorded?.call(audioInfo.path, _recordingDuration);
          _logger.i('录制完成，时长: ${_recordingDuration.inSeconds}秒');
        } else {
          _logger.e('录制文件不存在: ${audioInfo.path}');
          _showErrorMessage('录制文件保存失败');
        }
      } else {
        _showErrorMessage('录制时间太短，请至少录制1秒');
        // 删除过短的录音文件
        if (audioInfo != null) {
          final file = File(audioInfo.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      _logger.e('停止录制失败: $e');
      _showErrorMessage('录制失败: $e');
    } finally {
      setState(() {
        _recordingDuration = Duration.zero;
        _currentRecordingPath = null;
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    
    try {
      _logger.i('取消录制语音');
      
      await _audioService.cancelRecording();
      _stopDurationTimer();
      
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      
      _scaleAnimationController.reverse();
      _rippleAnimationController.stop();
      _rippleAnimationController.reset();
      
      // 删除取消的录音文件
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      widget.onRecordingCancel?.call();
      _logger.i('录制已取消');
    } catch (e) {
      _logger.e('取消录制失败: $e');
    } finally {
      setState(() {
        _currentRecordingPath = null;
      });
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
        
        // 最大录制时长限制（例如60秒）
        if (_recordingDuration.inSeconds >= 60) {
          _stopRecording();
        }
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 录制状态指示器
class RecordingIndicator extends StatefulWidget {
  final bool isRecording;
  final Duration duration;

  const RecordingIndicator({
    Key? key,
    required this.isRecording,
    required this.duration,
  }) : super(key: key);

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.isRecording) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RecordingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: _animation.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            '录制中 ${_formatDuration(widget.duration)}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}