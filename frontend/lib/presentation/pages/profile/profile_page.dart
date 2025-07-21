import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../domain/models/conversation_model.dart'; // 导入 UserStatus 枚举
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../../domain/viewmodels/auth_viewmodel.dart';

/// 个人资料页面
/// 
/// 用于显示和编辑用户个人信息
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _avatarFile;
  
  @override
  void initState() {
    super.initState();
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
      });
    }
  }
  
  Future<void> _saveProfile() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;
    
    if (user == null) return;
    
    final updatedUser = user.copyWith(
      displayName: _nameController.text,
      bio: _bioController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
    );
    
    final result = await userViewModel.updateProfile(
      displayName: updatedUser.displayName,
      bio: updatedUser.bio,
      phone: updatedUser.phoneNumber,
    );
    
    if (_avatarFile != null) {
      await userViewModel.updateAvatar(_avatarFile!);
    }
    
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('个人资料已更新')),
        );
        setState(() {
          _isEditing = false;
          _avatarFile = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: ${result.message}')),
        );
      }
    }
  }
  
  void _logout() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      await authViewModel.logout();
      // 退出登录后的导航逻辑由 AuthViewModel 处理
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userViewModel, child) {
        final user = userViewModel.currentUser;
        
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('个人资料'),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveProfile,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!) as ImageProvider
                                : const AssetImage('assets/images/default_avatar.png')),
                        child: user.avatarUrl == null && _avatarFile == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileField(
                  label: '姓名',
                  value: user.name,
                  controller: _nameController,
                  icon: Icons.person,
                  isEditing: _isEditing,
                ),
                const SizedBox(height: 16),
                _buildProfileField(
                  label: '个人简介',
                  value: user.bio ?? '',
                  controller: _bioController,
                  icon: Icons.info,
                  isEditing: _isEditing,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildProfileField(
                  label: '邮箱',
                  value: user.email,
                  controller: _emailController,
                  icon: Icons.email,
                  isEditing: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildProfileField(
                  label: '电话',
                  value: user.phoneNumber ?? '',
                  controller: _phoneController,
                  icon: Icons.phone,
                  isEditing: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  label: '用户ID',
                  value: user.id,
                  icon: Icons.badge,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  label: '状态',
                  value: _getUserStatusText(user.status),
                  icon: Icons.circle,
                  iconColor: _getUserStatusColor(user.status),
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  label: '最后上线',
                  value: user.lastActive != null
                      ? '${user.lastActive!.year}-${user.lastActive!.month}-${user.lastActive!.day} ${user.lastActive!.hour}:${user.lastActive!.minute}'
                      : '未知',
                  icon: Icons.access_time,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProfileField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isEditing) ...[                  
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                  ),
                ] else ...[                  
                  Text(
                    value.isNotEmpty ? value : '未设置',
                    style: TextStyle(
                      fontSize: 16,
                      color: value.isNotEmpty ? null : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getUserStatusText(UserStatus? status) {
    switch (status) {
      case UserStatus.online:
        return '在线';
      case UserStatus.offline:
        return '离线';
      case UserStatus.away:
        return '离开';
      case UserStatus.busy:
        return '忙碌';
      default:
        return '未知';
    }
  }
  
  Color _getUserStatusColor(UserStatus? status) {
    switch (status) {
      case UserStatus.online:
        return Colors.green;
      case UserStatus.offline:
        return Colors.grey;
      case UserStatus.away:
        return Colors.orange;
      case UserStatus.busy:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}