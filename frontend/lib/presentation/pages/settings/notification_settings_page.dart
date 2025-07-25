import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

/// 通知设置页面
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  TimeOfDay? _doNotDisturbStart;
  TimeOfDay? _doNotDisturbEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSettings();
    });
  }

  Future<void> _initializeSettings() async {
    final notificationViewModel = context.read<NotificationViewModel>();
    if (!notificationViewModel.isInitialized) {
      await notificationViewModel.initialize();
    }
    
    setState(() {
      _doNotDisturbStart = notificationViewModel.settings.doNotDisturbStart;
      _doNotDisturbEnd = notificationViewModel.settings.doNotDisturbEnd;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
        elevation: 0,
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, notificationViewModel, child) {
          if (notificationViewModel.isLoading) {
            return const LoadingWidget();
          }

          if (notificationViewModel.error != null) {
            return CustomErrorWidget(
              error: notificationViewModel.error!,
              onRetry: () => notificationViewModel.initialize(),
            );
          }

          return _buildSettingsContent(notificationViewModel);
        },
      ),
    );
  }

  Widget _buildSettingsContent(NotificationViewModel viewModel) {
    final settings = viewModel.settings;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 推送通知总开关
        _buildSectionHeader('推送通知'),
        _buildSwitchTile(
          title: '启用推送通知',
          subtitle: '接收来自应用的推送通知',
          value: settings.enablePushNotifications,
          onChanged: viewModel.togglePushNotifications,
          icon: Icons.notifications,
        ),
        
        const SizedBox(height: 24),
        
        // 通知类型设置
        _buildSectionHeader('通知类型'),
        _buildSwitchTile(
          title: '聊天消息',
          subtitle: '接收新消息通知',
          value: settings.enableMessageNotifications,
          onChanged: viewModel.toggleMessageNotifications,
          icon: Icons.message,
          enabled: settings.enablePushNotifications,
        ),
        _buildSwitchTile(
          title: '好友请求',
          subtitle: '接收好友请求通知',
          value: settings.enableFriendRequestNotifications,
          onChanged: viewModel.toggleFriendRequestNotifications,
          icon: Icons.person_add,
          enabled: settings.enablePushNotifications,
        ),
        _buildSwitchTile(
          title: '群组邀请',
          subtitle: '接收群组邀请通知',
          value: settings.enableGroupInviteNotifications,
          onChanged: viewModel.toggleGroupInviteNotifications,
          icon: Icons.group_add,
          enabled: settings.enablePushNotifications,
        ),
        _buildSwitchTile(
          title: '系统通知',
          subtitle: '接收系统消息通知',
          value: settings.enableSystemNotifications,
          onChanged: viewModel.toggleSystemNotifications,
          icon: Icons.info,
          enabled: settings.enablePushNotifications,
        ),
        
        const SizedBox(height: 24),
        
        // 通知方式设置
        _buildSectionHeader('通知方式'),
        _buildSwitchTile(
          title: '声音提醒',
          subtitle: '播放通知声音',
          value: settings.enableSoundNotifications,
          onChanged: viewModel.toggleSoundNotifications,
          icon: Icons.volume_up,
          enabled: settings.enablePushNotifications,
        ),
        _buildSwitchTile(
          title: '震动提醒',
          subtitle: '震动提醒新消息',
          value: settings.enableVibrationNotifications,
          onChanged: viewModel.toggleVibrationNotifications,
          icon: Icons.vibration,
          enabled: settings.enablePushNotifications,
        ),
        
        // 通知铃声选择
        _buildListTile(
          title: '通知铃声',
          subtitle: settings.notificationSound == 'default' ? '默认' : settings.notificationSound,
          icon: Icons.music_note,
          onTap: () => _showSoundPicker(viewModel),
          enabled: settings.enablePushNotifications && settings.enableSoundNotifications,
        ),
        
        const SizedBox(height: 24),
        
        // 免打扰设置
        _buildSectionHeader('免打扰'),
        _buildSwitchTile(
          title: '免打扰模式',
          subtitle: settings.doNotDisturbEnabled 
              ? '已启用 ${_formatTimeRange(_doNotDisturbStart, _doNotDisturbEnd)}'
              : '在指定时间段内不接收通知',
          value: settings.doNotDisturbEnabled,
          onChanged: viewModel.toggleDoNotDisturb,
          icon: Icons.do_not_disturb,
          enabled: settings.enablePushNotifications,
        ),
        
        if (settings.doNotDisturbEnabled) ...[
          _buildListTile(
            title: '开始时间',
            subtitle: _doNotDisturbStart?.format(context) ?? '未设置',
            icon: Icons.access_time,
            onTap: () => _selectDoNotDisturbTime(viewModel, true),
            enabled: settings.enablePushNotifications,
          ),
          _buildListTile(
            title: '结束时间',
            subtitle: _doNotDisturbEnd?.format(context) ?? '未设置',
            icon: Icons.access_time_filled,
            onTap: () => _selectDoNotDisturbTime(viewModel, false),
            enabled: settings.enablePushNotifications,
          ),
        ],
        
        const SizedBox(height: 24),
        
        // 通知统计
        _buildSectionHeader('通知统计'),
        _buildNotificationStats(viewModel),
        
        const SizedBox(height: 24),
        
        // 操作按钮
        _buildActionButtons(viewModel),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: enabled ? onChanged : null,
        secondary: Icon(
          icon,
          color: enabled ? Theme.of(context).primaryColor : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          icon,
          color: enabled ? Theme.of(context).primaryColor : Colors.grey,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
        enabled: enabled,
      ),
    );
  }

  Widget _buildNotificationStats(NotificationViewModel viewModel) {
    final stats = viewModel.getNotificationStats();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('总通知', stats['total'] ?? 0, Icons.notifications),
                _buildStatItem('未读', stats['unread'] ?? 0, Icons.mark_email_unread),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('消息', stats['message'] ?? 0, Icons.message),
                _buildStatItem('好友', stats['friendRequest'] ?? 0, Icons.person_add),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButtons(NotificationViewModel viewModel) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: viewModel.hasUnreadNotifications
                ? () => viewModel.markAllAsRead()
                : null,
            icon: const Icon(Icons.mark_email_read),
            label: const Text('标记所有为已读'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showClearConfirmDialog(viewModel),
            icon: const Icon(Icons.clear_all),
            label: const Text('清除所有通知'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDoNotDisturbTime(NotificationViewModel viewModel, bool isStart) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: isStart 
          ? (_doNotDisturbStart ?? const TimeOfDay(hour: 22, minute: 0))
          : (_doNotDisturbEnd ?? const TimeOfDay(hour: 8, minute: 0)),
    );

    if (selectedTime != null) {
      setState(() {
        if (isStart) {
          _doNotDisturbStart = selectedTime;
        } else {
          _doNotDisturbEnd = selectedTime;
        }
      });

      await viewModel.setDoNotDisturbTime(_doNotDisturbStart, _doNotDisturbEnd);
    }
  }

  Future<void> _showSoundPicker(NotificationViewModel viewModel) async {
    final sounds = ['default', 'bell', 'chime', 'ding', 'notification'];
    
    final String? selectedSound = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择通知铃声'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds.map((sound) => RadioListTile<String>(
            title: Text(sound == 'default' ? '默认' : sound),
            value: sound,
            groupValue: viewModel.settings.notificationSound,
            onChanged: (value) => Navigator.of(context).pop(value),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedSound != null) {
      await viewModel.setNotificationSound(selectedSound);
    }
  }

  Future<void> _showClearConfirmDialog(NotificationViewModel viewModel) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有通知吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await viewModel.clearAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清除所有通知')),
        );
      }
    }
  }

  String _formatTimeRange(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return '';
    return '${start.format(context)} - ${end.format(context)}';
  }
}