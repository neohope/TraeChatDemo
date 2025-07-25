import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/audio_service.dart';
import '../../../core/utils/app_logger.dart';

/// 语音消息组件
class VoiceMessageWidget extends StatefulWidget {
  final String? audioPath;
  final Duration? duration;
  final bool isFromCurrentUser;
  final VoidCallback? onSend;
  final VoidCallback? onCancel;
  final bool isRecording;

  const VoiceMessageWidget({
    Key? key,
    this.audioPath,
    this.duration,
    this.isFromCurrentUser = false,
    this.onSend,
    this.onCancel,
    this.isRecording = false,
  }) : super(key: key);

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final _logger = AppLogger.instance.logger;

  late AnimationController _waveAnimationController;
  late AnimationController _playAnimationController;
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudio();
  }

  void _initializeAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _playAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    if (widget.isRecording) {
      _waveAnimationController.repeat();
    }
  }

  void _initializeAudio() {
    if (widget.audioPath != null) {
      _loadAudioDuration();
    }
    
    _totalDuration = widget.duration ?? Duration.zero;
  }

  Future<void> _loadAudioDuration() async {
    if (widget.audioPath == null) return;
    
    try {
      final duration = await _audioService.getAudioDuration(widget.audioPath!);
      if (duration != null && mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    } catch (e) {
      _logger.e('加载音频时长失败: $e');
    }
  }

  @override
  void didUpdateWidget(VoiceMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _waveAnimationController.repeat();
      } else {
        _waveAnimationController.stop();
      }
    }
    
    if (widget.audioPath != oldWidget.audioPath) {
      _initializeAudio();
    }
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _playAnimationController.dispose();
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRecording) {
      return _buildRecordingWidget();
    } else if (widget.audioPath != null) {
      return _buildPlaybackWidget();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRecordingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 录音图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 波形动画
          _buildWaveAnimation(),
          
          const SizedBox(width: 12),
          
          // 录音时长
          StreamBuilder<Duration>(
            stream: _audioService.recordingDurationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 取消按钮
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 发送按钮
              GestureDetector(
                onTap: widget.onSend,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackWidget() {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isFromCurrentUser
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放/暂停按钮
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isFromCurrentUser
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isFromCurrentUser
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _playAnimationController,
                      builder: (context, child) {
                        return Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: widget.isFromCurrentUser
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          size: 20,
                        );
                      },
                    ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 波形和进度
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 波形可视化
                _buildWaveform(),
                
                const SizedBox(height: 4),
                
                // 时间显示
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isFromCurrentUser
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isFromCurrentUser
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveAnimation() {
    return AnimatedBuilder(
      animation: _waveAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final height = 20 + sin((_waveAnimationController.value * 2 * pi) + index) * 10;
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildWaveform() {
    return GestureDetector(
      onTapDown: (details) => _seekToPosition(details),
      child: Container(
        height: 30,
        child: CustomPaint(
          painter: WaveformPainter(
            progress: _totalDuration.inMilliseconds > 0
                ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                : 0.0,
            color: widget.isFromCurrentUser
                ? Colors.white
                : Theme.of(context).primaryColor,
            backgroundColor: widget.isFromCurrentUser
                ? Colors.white.withValues(alpha: 0.3)
                : Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _seekToPosition(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final progress = localPosition.dx / renderBox.size.width;
    final seekPosition = Duration(
      milliseconds: (_totalDuration.inMilliseconds * progress).round(),
    );
    
    _audioService.seekTo(seekPosition);
  }

  Future<void> _togglePlayback() async {
    if (widget.audioPath == null) return;
    
    HapticFeedback.lightImpact();
    
    try {
      if (_isPlaying) {
        await _audioService.pausePlaying();
        _playAnimationController.reverse();
      } else {
        setState(() {
          _isLoading = true;
        });
        
        // 如果是新的音频文件，需要重新加载
        if (_audioService.currentPlayingPath != widget.audioPath) {
          _setupAudioListeners();
          await _audioService.playAudio(widget.audioPath!);
        } else {
          await _audioService.resumePlaying();
        }
        
        _playAnimationController.forward();
      }
    } catch (e) {
      _logger.e('播放控制失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupAudioListeners() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    
    _positionSubscription = _audioService.playingPositionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
    
    _stateSubscription = _audioService.playingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == AudioPlayingState.playing;
          _isLoading = state == AudioPlayingState.loading;
        });
        
        if (state == AudioPlayingState.completed) {
          _playAnimationController.reverse();
          setState(() {
            _currentPosition = Duration.zero;
          });
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 波形绘制器
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  WaveformPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = 3.0;
    final barSpacing = 2.0;
    final barCount = (size.width / (barWidth + barSpacing)).floor();
    
    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final normalizedProgress = i / barCount;
      
      // 生成伪随机高度
      final height = size.height * (0.3 + 0.7 * sin(i * 0.5));
      final y = (size.height - height) / 2;
      
      // 根据播放进度选择颜色
      paint.color = normalizedProgress <= progress ? color : backgroundColor;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}