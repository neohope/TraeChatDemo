import 'package:intl/intl.dart';

/// 日期格式化工具类
/// 
/// 提供各种日期格式化方法
class DateFormatter {
  /// 格式化消息时间
  /// 
  /// 如果是今天，显示时间（如 14:30）
  /// 如果是昨天，显示"昨天"
  /// 如果是本周，显示星期几
  /// 如果是本年，显示月日
  /// 否则显示年月日
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      // 今天，显示时间
      return DateFormat('HH:mm').format(dateTime);
    } else if (date == yesterday) {
      // 昨天
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (now.difference(date).inDays < 7) {
      // 本周，显示星期几
      final weekday = _getWeekdayString(dateTime.weekday);
      return '$weekday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (date.year == now.year) {
      // 本年，显示月日
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } else {
      // 其他，显示年月日
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
  }
  
  /// 格式化会话时间
  /// 
  /// 如果是今天，显示时间（如 14:30）
  /// 如果是昨天，显示"昨天"
  /// 如果是本周，显示星期几
  /// 否则显示日期（年月日或月日）
  static String formatConversationTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      // 今天，显示时间
      return DateFormat('HH:mm').format(dateTime);
    } else if (date == yesterday) {
      // 昨天
      return '昨天';
    } else if (now.difference(date).inDays < 7) {
      // 本周，显示星期几
      return _getWeekdayString(dateTime.weekday);
    } else if (date.year == now.year) {
      // 本年，显示月日
      return DateFormat('MM-dd').format(dateTime);
    } else {
      // 其他，显示年月日
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }
  
  /// 格式化详细时间
  /// 
  /// 显示完整的日期和时间
  static String formatDetailTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
  
  /// 格式化相对时间
  /// 
  /// 如果是几秒前，显示"刚刚"
  /// 如果是几分钟前，显示"x分钟前"
  /// 如果是几小时前，显示"x小时前"
  /// 如果是昨天，显示"昨天"
  /// 否则显示具体日期
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      // 几秒前
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      // 几分钟前
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      // 几小时前
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 2) {
      // 昨天
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // 本周
      final weekday = _getWeekdayString(dateTime.weekday);
      return '$weekday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      // 本年
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } else {
      // 其他
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
  }
  
  /// 获取星期几的字符串
  static String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return '星期一';
      case 2:
        return '星期二';
      case 3:
        return '星期三';
      case 4:
        return '星期四';
      case 5:
        return '星期五';
      case 6:
        return '星期六';
      case 7:
        return '星期日';
      default:
        return '';
    }
  }
}