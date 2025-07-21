// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '聊天应用';

  @override
  String get login => '登录';

  @override
  String get logout => '退出登录';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get send => '发送';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get contacts => '联系人';

  @override
  String get chats => '聊天';

  @override
  String get profile => '个人资料';

  @override
  String get settings => '设置';

  @override
  String get error => '发生了一个错误';
}
