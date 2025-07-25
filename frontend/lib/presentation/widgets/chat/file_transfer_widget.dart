import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/file_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/file_utils.dart';

/// 文件传输组件
class FileTransferWidget extends StatefulWidget {
  final FileInfo fileInfo;
  final FileTransferInfo? transferInfo;
  final bool isFromCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onDownload;
  final bool showProgress;

  const FileTransferWidget({
    Key? key,
    required this.fileInfo,
    this.transferInfo,
    this.isFromCurrentUser = false,
    this.onTap,
    this.onCancel,
    this.onRetry,
    this.onDownload,
    this.showProgress = true,
  }) : super(key: key);

  @override
  State<FileTransferWidget> createState() => _FileTransferWidgetState();
}

class _FileTransferWidgetState extends State<FileTransferWidget>
    with SingleTickerProviderStateMixin {
  final _logger = AppLogger.instance.logger;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (_isTransferring) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(FileTransferWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final wasTransferring = _isTransferringForInfo(oldWidget.transferInfo);
    final isTransferring = _isTransferring;
    
    if (wasTransferring != isTransferring) {
      if (isTransferring) {
        _animationController.repeat();
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

  bool get _isTransferring => _isTransferringForInfo(widget.transferInfo);
  
  bool _isTransferringForInfo(FileTransferInfo? info) {
    return info?.status == FileTransferStatus.uploading ||
           info?.status == FileTransferStatus.downloading;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 200,
          maxWidth: 300,
          minHeight: 80,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isFromCurrentUser
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(context),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileHeader(),
            const SizedBox(height: 8),
            _buildFileInfo(),
            if (widget.showProgress && widget.transferInfo != null) ...[
              const SizedBox(height: 8),
              _buildProgressSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileHeader() {
    return Row(
      children: [
        // 文件图标
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFileTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(),
            color: _getFileTypeColor(),
            size: 24,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 文件名和状态
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fileInfo.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: widget.isFromCurrentUser
                      ? Colors.white
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.isFromCurrentUser
                      ? Colors.white.withValues(alpha: 0.8)
                      : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        
        // 操作按钮
        _buildActionButton(),
      ],
    );
  }

  Widget _buildFileInfo() {
    return Row(
      children: [
        Text(
          FileUtils.formatFileSize(widget.fileInfo.size),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.isFromCurrentUser
                ? Colors.white.withValues(alpha: 0.8)
                : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        if (widget.fileInfo.mimeType != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isFromCurrentUser
                  ? Colors.white.withValues(alpha: 0.5)
                  : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getFileTypeText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.isFromCurrentUser
                  ? Colors.white.withValues(alpha: 0.8)
                  : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection() {
    final transferInfo = widget.transferInfo!;
    
    return Column(
      children: [
        // 进度条
        if (transferInfo.status == FileTransferStatus.uploading ||
            transferInfo.status == FileTransferStatus.downloading)
          _buildProgressBar(),
        
        const SizedBox(height: 4),
        
        // 传输信息
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getTransferSpeedText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.isFromCurrentUser
                    ? Colors.white.withValues(alpha: 0.8)
                    : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            Text(
              '${(transferInfo.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.isFromCurrentUser
                    ? Colors.white.withValues(alpha: 0.8)
                    : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.transferInfo?.progress ?? 0.0;
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: widget.isFromCurrentUser
            ? Colors.white.withValues(alpha: 0.3)
            : Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _isTransferring ? null : progress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isFromCurrentUser
                  ? Colors.white
                  : Theme.of(context).primaryColor,
            ),
            minHeight: 4,
          );
        },
      ),
    );
  }

  Widget _buildActionButton() {
    final transferInfo = widget.transferInfo;
    
    if (transferInfo == null) {
      return const SizedBox.shrink();
    }
    
    IconData icon;
    VoidCallback? onPressed;
    Color? color;
    
    switch (transferInfo.status) {
      case FileTransferStatus.uploading:
      case FileTransferStatus.downloading:
        icon = Icons.close;
        onPressed = widget.onCancel;
        color = Colors.red;
        break;
      case FileTransferStatus.failed:
        icon = Icons.refresh;
        onPressed = widget.onRetry;
        color = Colors.orange;
        break;
      case FileTransferStatus.completed:
        icon = Icons.check_circle;
        onPressed = null;
        color = Colors.green;
        break;
      case FileTransferStatus.cancelled:
        icon = Icons.refresh;
        onPressed = widget.onRetry;
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          HapticFeedback.lightImpact();
          onPressed();
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    
    final transferInfo = widget.transferInfo;
    if (transferInfo?.status == FileTransferStatus.completed) {
      // 打开文件
      _openFile();
    } else if (transferInfo == null && !widget.isFromCurrentUser) {
      // 下载文件
      widget.onDownload?.call();
    } else {
      widget.onTap?.call();
    }
  }

  Future<void> _openFile() async {
    try {
      final file = File(widget.fileInfo.path);
      if (await file.exists()) {
        // 这里可以集成 open_file 包来打开文件
        _logger.i('打开文件: ${widget.fileInfo.path}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件已保存到本地')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件不存在')),
          );
        }
      }
    } catch (e) {
      _logger.e('打开文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件失败: $e')),
        );
      }
    }
  }

  Color _getBorderColor(BuildContext context) {
    final transferInfo = widget.transferInfo;
    if (transferInfo == null) {
      return Colors.transparent;
    }
    
    switch (transferInfo.status) {
      case FileTransferStatus.failed:
        return Colors.red.withValues(alpha: 0.3);
      case FileTransferStatus.completed:
        return Colors.green.withValues(alpha: 0.3);
      case FileTransferStatus.uploading:
      case FileTransferStatus.downloading:
        return Theme.of(context).primaryColor.withValues(alpha: 0.3);
      default:
        return Colors.transparent;
    }
  }

  Color _getFileTypeColor() {
    switch (widget.fileInfo.type) {
      case AppFileType.image:
        return Colors.blue;
      case AppFileType.video:
        return Colors.purple;
      case AppFileType.audio:
        return Colors.orange;
      case AppFileType.document:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon() {
    switch (widget.fileInfo.type) {
      case AppFileType.image:
        return Icons.image;
      case AppFileType.video:
        return Icons.videocam;
      case AppFileType.audio:
        return Icons.audiotrack;
      case AppFileType.document:
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileTypeText() {
    switch (widget.fileInfo.type) {
      case AppFileType.image:
        return '图片';
      case AppFileType.video:
        return '视频';
      case AppFileType.audio:
        return '音频';
      case AppFileType.document:
        return '文档';
      default:
        return '文件';
    }
  }

  String _getStatusText() {
    final transferInfo = widget.transferInfo;
    if (transferInfo == null) {
      return widget.isFromCurrentUser ? '已发送' : '点击下载';
    }
    
    switch (transferInfo.status) {
      case FileTransferStatus.pending:
        return '等待中';
      case FileTransferStatus.uploading:
        return '上传中';
      case FileTransferStatus.downloading:
        return '下载中';
      case FileTransferStatus.completed:
        return '已完成';
      case FileTransferStatus.failed:
        return '失败，点击重试';
      case FileTransferStatus.cancelled:
        return '已取消';
    }
  }

  String _getTransferSpeedText() {
    final transferInfo = widget.transferInfo;
    if (transferInfo == null) return '';
    
    final elapsed = DateTime.now().difference(transferInfo.startTime);
    if (elapsed.inSeconds == 0) return '计算中...';
    
    final bytesTransferred = (transferInfo.fileSize * transferInfo.progress).round();
    final speed = bytesTransferred / elapsed.inSeconds;
    
    return '${FileUtils.formatFileSize(speed.round())}/s';
  }
}

/// 文件选择器组件
class FilePickerWidget extends StatelessWidget {
  final Function(List<FileInfo>)? onFilesSelected;
  final bool multiple;
  final List<AppFileType>? allowedTypes;
  final Widget? child;

  const FilePickerWidget({
    Key? key,
    this.onFilesSelected,
    this.multiple = false,
    this.allowedTypes,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilePickerOptions(context),
      child: child ??
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attach_file,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '选择文件',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFilePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('选择图片'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('选择视频'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('选择文件'),
              onTap: () {
                Navigator.pop(context);
                _pickFiles(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final fileService = FileService();
      final files = await fileService.pickImages(multiple: multiple);
      if (files.isNotEmpty) {
        onFilesSelected?.call(files);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final fileService = FileService();
      final file = await fileService.takePhoto();
      if (file != null) {
        onFilesSelected?.call([file]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final fileService = FileService();
      final file = await fileService.pickVideo();
      if (file != null) {
        onFilesSelected?.call([file]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择视频失败: $e')),
        );
      }
    }
  }

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final fileService = FileService();
      final files = await fileService.pickFiles(multiple: multiple);
      if (files.isNotEmpty) {
        onFilesSelected?.call(files);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }
}