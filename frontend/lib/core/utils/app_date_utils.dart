import 'package:intl/intl.dart';

/// 应用日期工具类
class AppDateUtils {
  // 私有构造函数，防止实例化
  AppDateUtils._();

  // 常用日期格式
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultTimeFormat = 'HH:mm:ss';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String shortDateFormat = 'MM-dd';
  static const String shortTimeFormat = 'HH:mm';
  static const String shortDateTimeFormat = 'MM-dd HH:mm';
  static const String yearMonthFormat = 'yyyy-MM';
  static const String monthDayFormat = 'MM月dd日';
  static const String hourMinuteFormat = 'HH:mm';
  static const String iso8601Format = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

  // 格式化器缓存
  static final Map<String, DateFormat> _formatters = {};

  /// 获取格式化器
  static DateFormat _getFormatter(String pattern) {
    return _formatters.putIfAbsent(pattern, () => DateFormat(pattern));
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime, [String? pattern]) {
    final formatter = _getFormatter(pattern ?? defaultDateTimeFormat);
    return formatter.format(dateTime);
  }

  /// 格式化日期
  static String formatDate(DateTime dateTime, [String? pattern]) {
    final formatter = _getFormatter(pattern ?? defaultDateFormat);
    return formatter.format(dateTime);
  }

  /// 格式化时间
  static String formatTime(DateTime dateTime, [String? pattern]) {
    final formatter = _getFormatter(pattern ?? defaultTimeFormat);
    return formatter.format(dateTime);
  }

  /// 解析日期时间字符串
  static DateTime? parseDateTime(String dateTimeString, [String? pattern]) {
    try {
      final formatter = _getFormatter(pattern ?? defaultDateTimeFormat);
      return formatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// 解析ISO8601格式的日期时间
  static DateTime? parseIso8601(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// 获取相对时间描述（如：刚刚、5分钟前、昨天等）
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays == 2) {
      return '前天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}周前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}年前';
    }
  }

  /// 获取智能时间显示（聊天场景）
  static String getChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // 今天：显示时间
      return formatTime(dateTime, shortTimeFormat);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // 昨天：显示"昨天 HH:mm"
      return '昨天 ${formatTime(dateTime, shortTimeFormat)}';
    } else if (dateTime.year == now.year) {
      // 今年：显示"MM-dd HH:mm"
      return formatDateTime(dateTime, shortDateTimeFormat);
    } else {
      // 其他年份：显示完整日期时间
      return formatDateTime(dateTime, defaultDateTimeFormat);
    }
  }

  /// 获取消息列表时间显示
  static String getMessageListTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return formatTime(dateTime, shortTimeFormat);
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDate(dateTime, shortDateFormat);
    }
  }

  /// 格式化日期分隔符显示
  static String formatDateSeparator(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '今天';
    } else if (messageDate == yesterday) {
      return '昨天';
    } else if (dateTime.year == now.year) {
      return formatDate(dateTime, monthDayFormat);
    } else {
      return formatDate(dateTime, defaultDateFormat);
    }
  }

  /// 判断是否为今天
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  /// 判断是否为昨天
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
           dateTime.month == yesterday.month &&
           dateTime.day == yesterday.day;
  }

  /// 判断是否为本周
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return dateTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           dateTime.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// 判断是否为本月
  static bool isThisMonth(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && dateTime.month == now.month;
  }

  /// 判断是否为本年
  static bool isThisYear(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year;
  }

  /// 获取一天的开始时间（00:00:00）
  static DateTime getStartOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// 获取一天的结束时间（23:59:59.999）
  static DateTime getEndOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }

  /// 获取一周的开始时间（周一00:00:00）
  static DateTime getStartOfWeek(DateTime dateTime) {
    final startOfDay = getStartOfDay(dateTime);
    return startOfDay.subtract(Duration(days: dateTime.weekday - 1));
  }

  /// 获取一周的结束时间（周日23:59:59.999）
  static DateTime getEndOfWeek(DateTime dateTime) {
    final startOfWeek = getStartOfWeek(dateTime);
    return getEndOfDay(startOfWeek.add(const Duration(days: 6)));
  }

  /// 获取一个月的开始时间
  static DateTime getStartOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  /// 获取一个月的结束时间
  static DateTime getEndOfMonth(DateTime dateTime) {
    final nextMonth = dateTime.month == 12
        ? DateTime(dateTime.year + 1, 1, 1)
        : DateTime(dateTime.year, dateTime.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  /// 获取一年的开始时间
  static DateTime getStartOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 1, 1);
  }

  /// 获取一年的结束时间
  static DateTime getEndOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 12, 31, 23, 59, 59, 999);
  }

  /// 计算年龄
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// 获取时间段描述
  static String getTimeRangeDescription(DateTime start, DateTime end) {
    final startStr = formatDateTime(start, shortDateTimeFormat);
    final endStr = formatDateTime(end, shortDateTimeFormat);
    return '$startStr - $endStr';
  }

  /// 获取持续时间描述
  static String getDurationDescription(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天${duration.inHours % 24}小时';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  /// 获取简短的持续时间描述
  static String getShortDurationDescription(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  /// 格式化文件修改时间
  static String formatFileTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '今天 ${formatTime(dateTime, shortTimeFormat)}';
    } else if (difference.inDays == 1) {
      return '昨天 ${formatTime(dateTime, shortTimeFormat)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDate(dateTime, shortDateFormat);
    }
  }

  /// 格式化最后在线时间
  static String formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚在线';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前在线';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前在线';
    } else if (difference.inDays == 1) {
      return '昨天在线';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前在线';
    } else {
      return formatDate(dateTime, shortDateFormat);
    }
  }

  /// 获取时间戳（毫秒）
  static int getTimestamp([DateTime? dateTime]) {
    return (dateTime ?? DateTime.now()).millisecondsSinceEpoch;
  }

  /// 从时间戳创建DateTime
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 获取UTC时间
  static DateTime getUtcTime([DateTime? dateTime]) {
    return (dateTime ?? DateTime.now()).toUtc();
  }

  /// 从UTC时间转换为本地时间
  static DateTime fromUtcTime(DateTime utcTime) {
    return utcTime.toLocal();
  }

  /// 比较两个日期是否为同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 比较两个日期是否为同一周
  static bool isSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek1 = getStartOfWeek(date1);
    final startOfWeek2 = getStartOfWeek(date2);
    return isSameDay(startOfWeek1, startOfWeek2);
  }

  /// 比较两个日期是否为同一月
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// 比较两个日期是否为同一年
  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  /// 获取两个日期之间的天数
  static int getDaysBetween(DateTime start, DateTime end) {
    final startDate = getStartOfDay(start);
    final endDate = getStartOfDay(end);
    return endDate.difference(startDate).inDays;
  }

  /// 添加工作日（跳过周末）
  static DateTime addWorkDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;
    
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      // 1=Monday, 7=Sunday
      if (result.weekday <= 5) {
        addedDays++;
      }
    }
    
    return result;
  }

  /// 检查是否为工作日
  static bool isWorkDay(DateTime date) {
    return date.weekday <= 5; // Monday to Friday
  }

  /// 检查是否为周末
  static bool isWeekend(DateTime date) {
    return date.weekday > 5; // Saturday and Sunday
  }
}