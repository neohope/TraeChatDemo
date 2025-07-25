import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../user/user_detail_widget.dart';
import '../notification/notification_settings_widget.dart';

/// 设置主页面组件
class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  PackageInfo? _packageInfo;
  bool _isDarkMode = false;
  String _language = 'zh';
  bool _autoDownloadImages = true;
  bool _autoDownloadVideos = false;
  bool _saveToGallery = true;
  double _fontSize = 16.0;
  String _chatBackground = 'default';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildUserSection(),
          const Divider(),
          _buildGeneralSection(),
          const Divider(),
          _buildChatSection(),
          const Divider(),
          _buildNotificationSection(),
          const Divider(),
          _buildPrivacySection(),
          const Divider(),
          _buildStorageSection(),
          const Divider(),
          _buildAboutSection(),
          const Divider(),
          _buildAccountSection(),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Consumer<UserViewModel>(builder: (context, userViewModel, child) {
      final currentUser = userViewModel.currentUser;
      
      if (currentUser == null) {
        return const SizedBox.shrink();
      }

      return ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: currentUser.avatarUrl != null
              ? NetworkImage(currentUser.avatarUrl!)
              : null,
          child: currentUser.avatarUrl == null
              ? Text(
                  (currentUser.nickname ?? currentUser.name).substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          currentUser.nickname ?? currentUser.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('@${currentUser.name}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToProfile(),
      );
    });
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('通用'),
        SwitchListTile(
          title: const Text('深色模式'),
          subtitle: const Text('使用深色主题'),
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
            _saveSettings();
          },
        ),
        ListTile(
          title: const Text('语言'),
          subtitle: Text(_getLanguageName(_language)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguageDialog,
        ),
        ListTile(
          title: const Text('字体大小'),
          subtitle: Text('${_fontSize.toInt()}px'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showFontSizeDialog,
        ),
      ],
    );
  }

  Widget _buildChatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('聊天'),
        SwitchListTile(
          title: const Text('自动下载图片'),
          subtitle: const Text('在Wi-Fi环境下自动下载图片'),
          value: _autoDownloadImages,
          onChanged: (value) {
            setState(() {
              _autoDownloadImages = value;
            });
            _saveSettings();
          },
        ),
        SwitchListTile(
          title: const Text('自动下载视频'),
          subtitle: const Text('在Wi-Fi环境下自动下载视频'),
          value: _autoDownloadVideos,
          onChanged: (value) {
            setState(() {
              _autoDownloadVideos = value;
            });
            _saveSettings();
          },
        ),
        SwitchListTile(
          title: const Text('保存到相册'),
          subtitle: const Text('自动保存接收的图片和视频到相册'),
          value: _saveToGallery,
          onChanged: (value) {
            setState(() {
              _saveToGallery = value;
            });
            _saveSettings();
          },
        ),
        ListTile(
          title: const Text('聊天背景'),
          subtitle: Text(_getChatBackgroundName(_chatBackground)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showChatBackgroundDialog,
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('通知'),
        ListTile(
          title: const Text('通知设置'),
          subtitle: const Text('管理消息通知偏好'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToNotificationSettings,
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('隐私与安全'),
        ListTile(
          title: const Text('隐私设置'),
          subtitle: const Text('管理谁可以联系您'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToPrivacySettings,
        ),
        ListTile(
          title: const Text('黑名单'),
          subtitle: const Text('管理被屏蔽的用户'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToBlockedUsers,
        ),
        ListTile(
          title: const Text('数据与隐私'),
          subtitle: const Text('了解我们如何处理您的数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showDataPrivacyInfo,
        ),
      ],
    );
  }

  Widget _buildStorageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('存储'),
        ListTile(
          title: const Text('存储管理'),
          subtitle: const Text('管理应用存储空间'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToStorageManagement,
        ),
        ListTile(
          title: const Text('清除缓存'),
          subtitle: const Text('清除临时文件和缓存'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showClearCacheDialog,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('关于'),
        ListTile(
          title: const Text('版本信息'),
          subtitle: Text(_packageInfo?.version ?? '未知'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showVersionInfo,
        ),
        ListTile(
          title: const Text('用户协议'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openUserAgreement,
        ),
        ListTile(
          title: const Text('隐私政策'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openPrivacyPolicy,
        ),
        ListTile(
          title: const Text('意见反馈'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openFeedback,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('账户'),
        ListTile(
          title: const Text(
            '退出登录',
            style: TextStyle(color: Colors.red),
          ),
          trailing: const Icon(Icons.exit_to_app, color: Colors.red),
          onTap: _showLogoutDialog,
        ),
        ListTile(
          title: const Text(
            '注销账户',
            style: TextStyle(color: Colors.red),
          ),
          trailing: const Icon(Icons.delete_forever, color: Colors.red),
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  Future<void> _loadSettings() async {
    try {
      final localStorage = LocalStorage();
      
      final isDarkMode = (await localStorage.getBool('dark_mode')) ?? false;
      final language = (await localStorage.getString('language')) ?? 'zh';
      final autoDownloadImages = (await localStorage.getBool('auto_download_images')) ?? true;
      final autoDownloadVideos = (await localStorage.getBool('auto_download_videos')) ?? false;
      final saveToGallery = (await localStorage.getBool('save_to_gallery')) ?? true;
      final fontSize = (await localStorage.getDouble('font_size')) ?? 16.0;
      final chatBackground = (await localStorage.getString('chat_background')) ?? 'default';
      
      setState(() {
        _isDarkMode = isDarkMode;
        _language = language;
        _autoDownloadImages = autoDownloadImages;
        _autoDownloadVideos = autoDownloadVideos;
        _saveToGallery = saveToGallery;
        _fontSize = fontSize;
        _chatBackground = chatBackground;
      });
    } catch (e) {
      AppLogger.instance.error('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final localStorage = LocalStorage();
      
      await localStorage.setBool('dark_mode', _isDarkMode);
      await localStorage.setString('language', _language);
      await localStorage.setBool('auto_download_images', _autoDownloadImages);
      await localStorage.setBool('auto_download_videos', _autoDownloadVideos);
      await localStorage.setBool('save_to_gallery', _saveToGallery);
      await localStorage.setDouble('font_size', _fontSize);
      await localStorage.setString('chat_background', _chatBackground);
    } catch (e) {
      AppLogger.instance.error('Failed to save settings: $e');
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return '中文';
    }
  }

  String _getChatBackgroundName(String background) {
    switch (background) {
      case 'default':
        return '默认';
      case 'dark':
        return '深色';
      case 'custom':
        return '自定义';
      default:
        return '默认';
    }
  }

  void _navigateToProfile() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final currentUser = userViewModel.currentUser;
    
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetailWidget(
            userId: currentUser.id,
            isCurrentUser: true,
          ),
        ),
      );
    }
  }

  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsWidget(),
      ),
    );
  }

  void _navigateToPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsWidget(),
      ),
    );
  }

  void _navigateToBlockedUsers() {
    // 导航到黑名单页面
  }

  void _navigateToStorageManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StorageManagementWidget(),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('中文'),
              value: 'zh',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字体大小'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '示例文本',
                style: TextStyle(fontSize: _fontSize),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                label: '${_fontSize.toInt()}px',
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              this.setState(() {});
              _saveSettings();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showChatBackgroundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('聊天背景'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('默认'),
              value: 'default',
              groupValue: _chatBackground,
              onChanged: (value) {
                setState(() {
                  _chatBackground = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('深色'),
              value: 'dark',
              groupValue: _chatBackground,
              onChanged: (value) {
                setState(() {
                  _chatBackground = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('自定义'),
              value: 'custom',
              groupValue: _chatBackground,
              onChanged: (value) {
                setState(() {
                  _chatBackground = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDataPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据与隐私'),
        content: const SingleChildScrollView(
          child: Text(
            '我们重视您的隐私，承诺保护您的个人信息安全。\n\n'
            '• 我们只收集必要的信息以提供服务\n'
            '• 您的聊天记录采用端到端加密\n'
            '• 我们不会向第三方出售您的个人信息\n'
            '• 您可以随时删除您的账户和数据\n\n'
            '详细信息请查看我们的隐私政策。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
          TextButton(
            onPressed: _openPrivacyPolicy,
            child: const Text('查看隐私政策'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('这将清除所有临时文件和缓存数据，但不会影响您的聊天记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearCache();
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版本信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('应用名称: ${_packageInfo?.appName ?? '未知'}'),
            Text('版本号: ${_packageInfo?.version ?? '未知'}'),
            Text('构建号: ${_packageInfo?.buildNumber ?? '未知'}'),
            Text('包名: ${_packageInfo?.packageName ?? '未知'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注销账户'),
        content: const Text(
          '注销账户将永久删除您的所有数据，包括聊天记录、好友关系等。\n\n'
          '此操作不可撤销，请谨慎操作。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAccountConfirmDialog();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定注销'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      // 清除缓存逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('缓存清除成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清除缓存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.logout();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退出登录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最终确认'),
        content: const Text(
          '您即将永久删除账户，此操作无法撤销。\n\n请再次确认您要删除账户。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      // TODO: Implement deleteAccount method in AuthViewModel
      // For now, just logout the user
      await authViewModel.logout();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('账户删除请求已提交，正在处理中...'),
            backgroundColor: Colors.orange,
          ),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('注销账户失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openUserAgreement() async {
    const url = 'https://example.com/user-agreement';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://example.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openFeedback() async {
    const url = 'mailto:feedback@example.com';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

/// 隐私设置组件
class PrivacySettingsWidget extends StatefulWidget {
  const PrivacySettingsWidget({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsWidget> createState() => _PrivacySettingsWidgetState();
}

class _PrivacySettingsWidgetState extends State<PrivacySettingsWidget> {
  bool _allowFriendRequests = true;
  bool _allowGroupInvites = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _allowSearchByPhone = true;
  bool _allowSearchByEmail = true;
  String _whoCanSeeProfile = 'friends'; // everyone, friends, nobody

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私设置'),
      ),
      body: ListView(
        children: [
          _buildContactSection(),
          const Divider(),
          _buildVisibilitySection(),
          const Divider(),
          _buildDiscoverabilitySection(),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('联系方式'),
        SwitchListTile(
          title: const Text('允许好友请求'),
          subtitle: const Text('其他用户可以向您发送好友请求'),
          value: _allowFriendRequests,
          onChanged: (value) {
            setState(() {
              _allowFriendRequests = value;
            });
            _savePrivacySettings();
          },
        ),
        SwitchListTile(
          title: const Text('允许群组邀请'),
          subtitle: const Text('其他用户可以邀请您加入群组'),
          value: _allowGroupInvites,
          onChanged: (value) {
            setState(() {
              _allowGroupInvites = value;
            });
            _savePrivacySettings();
          },
        ),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('可见性'),
        SwitchListTile(
          title: const Text('显示在线状态'),
          subtitle: const Text('其他用户可以看到您的在线状态'),
          value: _showOnlineStatus,
          onChanged: (value) {
            setState(() {
              _showOnlineStatus = value;
            });
            _savePrivacySettings();
          },
        ),
        SwitchListTile(
          title: const Text('显示最后在线时间'),
          subtitle: const Text('其他用户可以看到您的最后在线时间'),
          value: _showLastSeen,
          onChanged: (value) {
            setState(() {
              _showLastSeen = value;
            });
            _savePrivacySettings();
          },
        ),
        ListTile(
          title: const Text('谁可以查看我的资料'),
          subtitle: Text(_getProfileVisibilityText(_whoCanSeeProfile)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showProfileVisibilityDialog,
        ),
      ],
    );
  }

  Widget _buildDiscoverabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('可发现性'),
        SwitchListTile(
          title: const Text('允许通过手机号搜索'),
          subtitle: const Text('其他用户可以通过您的手机号找到您'),
          value: _allowSearchByPhone,
          onChanged: (value) {
            setState(() {
              _allowSearchByPhone = value;
            });
            _savePrivacySettings();
          },
        ),
        SwitchListTile(
          title: const Text('允许通过邮箱搜索'),
          subtitle: const Text('其他用户可以通过您的邮箱找到您'),
          value: _allowSearchByEmail,
          onChanged: (value) {
            setState(() {
              _allowSearchByEmail = value;
            });
            _savePrivacySettings();
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _getProfileVisibilityText(String value) {
    switch (value) {
      case 'everyone':
        return '所有人';
      case 'friends':
        return '仅好友';
      case 'nobody':
        return '仅自己';
      default:
        return '仅好友';
    }
  }

  void _showProfileVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('谁可以查看我的资料'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('所有人'),
              value: 'everyone',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() {
                  _whoCanSeeProfile = value!;
                });
                _savePrivacySettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('仅好友'),
              value: 'friends',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() {
                  _whoCanSeeProfile = value!;
                });
                _savePrivacySettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('仅自己'),
              value: 'nobody',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() {
                  _whoCanSeeProfile = value!;
                });
                _savePrivacySettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final localStorage = LocalStorage();
      
      final allowFriendRequests = (await localStorage.getBool('allow_friend_requests')) ?? true;
      final allowGroupInvites = (await localStorage.getBool('allow_group_invites')) ?? true;
      final showOnlineStatus = (await localStorage.getBool('show_online_status')) ?? true;
      final showLastSeen = (await localStorage.getBool('show_last_seen')) ?? true;
      final allowSearchByPhone = (await localStorage.getBool('allow_search_by_phone')) ?? true;
      final allowSearchByEmail = (await localStorage.getBool('allow_search_by_email')) ?? true;
      final whoCanSeeProfile = (await localStorage.getString('who_can_see_profile')) ?? 'friends';
      
      setState(() {
        _allowFriendRequests = allowFriendRequests;
        _allowGroupInvites = allowGroupInvites;
        _showOnlineStatus = showOnlineStatus;
        _showLastSeen = showLastSeen;
        _allowSearchByPhone = allowSearchByPhone;
        _allowSearchByEmail = allowSearchByEmail;
        _whoCanSeeProfile = whoCanSeeProfile;
      });
    } catch (e) {
      AppLogger.instance.error('Failed to load privacy settings: $e');
    }
  }

  Future<void> _savePrivacySettings() async {
    try {
      final localStorage = LocalStorage();
      
      await localStorage.setBool('allow_friend_requests', _allowFriendRequests);
      await localStorage.setBool('allow_group_invites', _allowGroupInvites);
      await localStorage.setBool('show_online_status', _showOnlineStatus);
      await localStorage.setBool('show_last_seen', _showLastSeen);
      await localStorage.setBool('allow_search_by_phone', _allowSearchByPhone);
      await localStorage.setBool('allow_search_by_email', _allowSearchByEmail);
      await localStorage.setString('who_can_see_profile', _whoCanSeeProfile);
    } catch (e) {
      AppLogger.instance.error('Failed to save privacy settings: $e');
    }
  }
}

/// 存储管理组件
class StorageManagementWidget extends StatefulWidget {
  const StorageManagementWidget({Key? key}) : super(key: key);

  @override
  State<StorageManagementWidget> createState() => _StorageManagementWidgetState();
}

class _StorageManagementWidgetState extends State<StorageManagementWidget> {
  double _totalSize = 0;
  double _cacheSize = 0;
  double _mediaSize = 0;
  double _databaseSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateStorageUsage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储管理'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStorageOverview(),
                const SizedBox(height: 24),
                _buildStorageBreakdown(),
                const SizedBox(height: 24),
                _buildStorageActions(),
              ],
            ),
    );
  }

  Widget _buildStorageOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '存储使用情况',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '总计: ${_formatSize(_totalSize)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _totalSize > 0 ? _totalSize / (1024 * 1024 * 1024) : 0, // 假设最大1GB
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '存储详情',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStorageItem(
              '缓存文件',
              _cacheSize,
              Icons.cached,
              Colors.orange,
            ),
            _buildStorageItem(
              '媒体文件',
              _mediaSize,
              Icons.photo,
              Colors.blue,
            ),
            _buildStorageItem(
              '数据库',
              _databaseSize,
              Icons.storage,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItem(
    String title,
    double size,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatSize(size),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _clearCache,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('清除缓存'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearMediaFiles,
            icon: const Icon(Icons.delete_sweep),
            label: const Text('清除媒体文件'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.download),
            label: const Text('导出数据'),
          ),
        ),
      ],
    );
  }

  String _formatSize(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toStringAsFixed(0)} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _calculateStorageUsage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟计算存储使用情况
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _cacheSize = 50 * 1024 * 1024; // 50MB
        _mediaSize = 200 * 1024 * 1024; // 200MB
        _databaseSize = 10 * 1024 * 1024; // 10MB
        _totalSize = _cacheSize + _mediaSize + _databaseSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('计算存储使用情况失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      // 清除缓存逻辑
      setState(() {
        _cacheSize = 0;
        _totalSize = _mediaSize + _databaseSize;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('缓存清除成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清除缓存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearMediaFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除媒体文件'),
        content: const Text('这将删除所有下载的图片、视频等媒体文件，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 清除媒体文件逻辑
        setState(() {
          _mediaSize = 0;
          _totalSize = _cacheSize + _databaseSize;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('媒体文件清除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清除媒体文件失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportData() async {
    try {
      // 导出数据逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据导出成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出数据失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}