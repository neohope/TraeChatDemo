import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';

/// 通知设置组件
class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
        actions: [
          Consumer<NotificationViewModel>(builder: (context, viewModel, child) {
            return TextButton(
              onPressed: viewModel.isLoading ? null : () => _resetToDefault(viewModel),
              child: const Text('重置'),
            );
          }),
        ],
      ),
      body: Consumer<NotificationViewModel>(builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = viewModel.notificationSettings;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGeneralSettings(settings, viewModel),
            const SizedBox(height: 24),
            _buildTypeSettings(settings, viewModel),
            const SizedBox(height: 24),
            _buildQuietHoursSettings(settings, viewModel),
            const SizedBox(height: 24),
            _buildAdvancedSettings(settings, viewModel),
          ],
        );
      }),
    );
  }

  Widget _buildGeneralSettings(NotificationSettings settings, NotificationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通用设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用通知'),
              subtitle: const Text('接收应用通知'),
              value: settings.enabled,
              onChanged: (value) {
                viewModel.updateSettings(settings.copyWith(enabled: value));
              },
            ),
            SwitchListTile(
              title: const Text('声音提醒'),
              subtitle: const Text('播放通知声音'),
              value: settings.soundEnabled,
              onChanged: settings.enabled
                  ? (value) {
                      viewModel.updateSettings(settings.copyWith(soundEnabled: value));
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('振动提醒'),
              subtitle: const Text('设备振动提醒'),
              value: settings.vibrationEnabled,
              onChanged: settings.enabled
                  ? (value) {
                      viewModel.updateSettings(settings.copyWith(vibrationEnabled: value));
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('显示预览'),
              subtitle: const Text('在通知中显示消息内容'),
              value: settings.showPreview,
              onChanged: settings.enabled
                  ? (value) {
                      viewModel.updateSettings(settings.copyWith(showPreview: value));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSettings(NotificationSettings settings, NotificationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通知类型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTypeSettingItem(
              '消息通知',
              '新消息提醒',
              Icons.message,
              Colors.blue,
              settings.messageEnabled,
              settings.enabled,
              (value) {
                viewModel.updateSettings(settings.copyWith(messageEnabled: value));
              },
            ),
            _buildTypeSettingItem(
              '系统通知',
              '系统消息和更新',
              Icons.settings,
              Colors.orange,
              settings.systemEnabled,
              settings.enabled,
              (value) {
                viewModel.updateSettings(settings.copyWith(systemEnabled: value));
              },
            ),
            _buildTypeSettingItem(
              '群组通知',
              '群组消息和活动',
              Icons.group,
              Colors.green,
              settings.groupEnabled,
              settings.enabled,
              (value) {
                viewModel.updateSettings(settings.copyWith(groupEnabled: value));
              },
            ),
            _buildTypeSettingItem(
              '好友通知',
              '好友请求和状态',
              Icons.person_add,
              Colors.purple,
              settings.friendEnabled,
              settings.enabled,
              (value) {
                viewModel.updateSettings(settings.copyWith(friendEnabled: value));
              },
            ),
            _buildTypeSettingItem(
              '安全通知',
              '安全警告和提醒',
              Icons.security,
              Colors.red,
              settings.securityEnabled,
              settings.enabled,
              (value) {
                viewModel.updateSettings(settings.copyWith(securityEnabled: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSettingItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    bool enabled,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
      onTap: enabled ? () => onChanged(!value) : null,
    );
  }

  Widget _buildQuietHoursSettings(NotificationSettings settings, NotificationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '免打扰时间',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用免打扰'),
              subtitle: const Text('在指定时间段内静音通知'),
              value: settings.quietHoursEnabled,
              onChanged: settings.enabled
                  ? (value) {
                      viewModel.updateSettings(settings.copyWith(quietHoursEnabled: value));
                    }
                  : null,
            ),
            if (settings.quietHoursEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('开始时间'),
                subtitle: Text(_formatTime(settings.quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTime(
                  context,
                  settings.quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
                  (time) {
                    viewModel.updateSettings(settings.copyWith(quietHoursStart: time));
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('结束时间'),
                subtitle: Text(_formatTime(settings.quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTime(
                  context,
                  settings.quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0),
                  (time) {
                    viewModel.updateSettings(settings.copyWith(quietHoursEnd: time));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings(NotificationSettings settings, NotificationViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '高级设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('通知音量'),
              subtitle: Slider(
                value: settings.volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(settings.volume * 100).round()}%',
                onChanged: settings.enabled && settings.soundEnabled
                    ? (value) {
                        viewModel.updateSettings(settings.copyWith(volume: value));
                      }
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('通知持续时间'),
              subtitle: Text('${settings.duration}秒'),
              trailing: DropdownButton<int>(
                value: settings.duration,
                items: [3, 5, 10, 15, 30].map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text('${duration}秒'),
                  );
                }).toList(),
                onChanged: settings.enabled
                    ? (value) {
                        if (value != null) {
                          viewModel.updateSettings(settings.copyWith(duration: value));
                        }
                      }
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('优先级'),
              subtitle: Text(_getPriorityText(settings.priority)),
              trailing: DropdownButton<NotificationPriority>(
                value: settings.priority,
                items: NotificationPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(_getPriorityText(priority)),
                  );
                }).toList(),
                onChanged: settings.enabled
                    ? (value) {
                        if (value != null) {
                          viewModel.updateSettings(settings.copyWith(priority: value));
                        }
                      }
                    : null,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('清空所有通知'),
              subtitle: const Text('删除所有已接收的通知'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showClearAllDialog(viewModel),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('重置设置'),
              subtitle: const Text('恢复默认通知设置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResetDialog(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTime(BuildContext context, TimeOfDay initialTime, ValueChanged<TimeOfDay> onTimeSelected) {
    showTimePicker(
      context: context,
      initialTime: initialTime,
    ).then((time) {
      if (time != null) {
        onTimeSelected(time);
      }
    });
  }

  void _resetToDefault(NotificationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要将所有通知设置重置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.resetSettings();
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(NotificationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有通知'),
        content: const Text('确定要删除所有通知吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(NotificationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要将通知设置重置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.resetSettings();
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getPriorityText(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return '低';
      case NotificationPriority.normal:
        return '普通';
      case NotificationPriority.high:
        return '高';
      case NotificationPriority.urgent:
        return '紧急';
    }
  }
}