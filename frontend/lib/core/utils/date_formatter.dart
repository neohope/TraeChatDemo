import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fullFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// 格式化时间为 HH:mm
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// 格式化日期为 yyyy-MM-dd
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// 格式化日期时间为 yyyy-MM-dd HH:mm
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// 格式化完整日期时间为 yyyy-MM-dd HH:mm:ss
  static String formatFullDateTime(DateTime dateTime) {
    return _fullFormat.format(dateTime);
  }

  /// 格式化相对时间（如：刚刚、5分钟前、昨天等）
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天 ${formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDate(dateTime);
    }
  }

  /// 格式化聊天时间显示
  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return formatTime(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨天 ${formatTime(dateTime)}';
    } else if (now.year == dateTime.year) {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } else {
      return formatDateTime(dateTime);
    }
  }
}