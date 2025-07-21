import 'package:flutter/material.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 通知设置
          _buildSectionHeader('通知设置'),
          SwitchListTile(
            title: const Text('推送通知'),
            subtitle: const Text('接收新消息通知'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('声音提醒'),
            subtitle: const Text('新消息声音提醒'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          const Divider(),

          // 外观设置
          _buildSectionHeader('外观设置'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('启用深色主题'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          const Divider(),

          // 账户设置
          _buildSectionHeader('账户设置'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('个人资料'),
            subtitle: const Text('编辑个人信息'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 导航到个人资料编辑页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('隐私设置'),
            subtitle: const Text('管理隐私选项'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 导航到隐私设置页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('安全设置'),
            subtitle: const Text('密码和安全选项'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 导航到安全设置页面
            },
          ),
          const Divider(),

          // 其他设置
          _buildSectionHeader('其他'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('帮助与支持'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 导航到帮助页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 显示关于信息
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 执行退出登录逻辑
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}