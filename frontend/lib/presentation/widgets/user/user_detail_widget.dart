import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../domain/models/user_model.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
// TODO: Import these when needed
// import '../../../core/utils/date_utils.dart';
// import '../../../core/utils/image_utils.dart';

/// 用户详情组件
class UserDetailWidget extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;
  final bool showEditButton;
  final Function(UserModel)? onSendMessage;
  final Function(UserModel)? onAddFriend;
  final Function(UserModel)? onRemoveFriend;

  const UserDetailWidget({
    Key? key,
    required this.userId,
    this.isCurrentUser = false,
    this.showEditButton = true,
    this.onSendMessage,
    this.onAddFriend,
    this.onRemoveFriend,
  }) : super(key: key);

  @override
  State<UserDetailWidget> createState() => _UserDetailWidgetState();
}

class _UserDetailWidgetState extends State<UserDetailWidget> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(builder: (context, userViewModel, child) {
      final user = userViewModel.getUserById(widget.userId);
      
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_isEditing && _nicknameController.text.isEmpty) {
        _initializeEditForm(user);
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '编辑资料' : '用户资料'),
          actions: [
            if (widget.isCurrentUser && widget.showEditButton)
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: _toggleEdit,
              ),
          ],
        ),
        body: _isEditing ? _buildEditForm(user) : _buildDetailView(user),
        floatingActionButton: _isEditing ? _buildSaveButton(userViewModel) : null,
      );
    });
  }

  Widget _buildDetailView(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatarSection(user),
          const SizedBox(height: 24),
          _buildBasicInfo(user),
          const SizedBox(height: 24),
          _buildContactInfo(user),
          const SizedBox(height: 24),
          _buildStatusInfo(user),
          if (!widget.isCurrentUser) ...[
            const SizedBox(height: 32),
            _buildActionButtons(user),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEditableAvatarSection(user),
            const SizedBox(height: 24),
            _buildEditableBasicInfo(),
            const SizedBox(height: 24),
            _buildEditableContactInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      (user.nickname ?? user.name).substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.nickname ?? user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // TODO: Add isVerified property to UserModel
            // if (user.isVerified)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.verified,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.name}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            user.bio!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildEditableAvatarSection(UserModel user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : (user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!) as ImageProvider
                        : null),
                child: _selectedImage == null && user.avatarUrl == null
                    ? Text(
                        (user.nickname ?? user.name).substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '点击更换头像',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('用户名', '@${user.name}'),
            _buildInfoRow('昵称', user.nickname ?? user.name),
            if (user.bio != null && user.bio!.isNotEmpty)
              _buildInfoRow('个人简介', user.bio!),
            // TODO: Import AppDateUtils or use alternative date formatting
            // _buildInfoRow('注册时间', AppDateUtils.formatDate(user.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入昵称';
                }
                if (value.trim().length < 2) {
                  return '昵称至少需要2个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '个人简介',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '联系方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (user.email != null && user.email!.isNotEmpty)
              _buildInfoRow('邮箱', user.email!),
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildInfoRow('手机号', user.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableContactInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '联系方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '请输入有效的邮箱地址';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                    return '请输入有效的手机号';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '状态信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              '在线状态',
              user.isOnline ? '在线' : '离线',
              valueColor: user.isOnline ? Colors.green : Colors.grey,
            ),
            if (!user.isOnline && user.lastSeen != null)
              _buildInfoRow(
                '最后在线',
                user.lastSeen.toString(), // TODO: Format date properly
              ),
            // TODO: Add isVerified property to UserModel
            // _buildInfoRow(
            //   '账号状态',
            //   user.isVerified ? '已认证' : '未认证',
            //   valueColor: user.isVerified ? Colors.blue : Colors.grey,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Consumer2<FriendViewModel, ChatViewModel>(
      builder: (context, friendViewModel, chatViewModel, child) {
        final isFriend = friendViewModel.isFriend(user.id);
        final hasPendingRequest = friendViewModel.hasPendingFriendRequest(user.id);
        
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendMessage(user, chatViewModel),
                icon: const Icon(Icons.message),
                label: const Text('发送消息'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!isFriend && !hasPendingRequest)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addFriend(user, friendViewModel),
                  icon: const Icon(Icons.person_add),
                  label: const Text('添加好友'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else if (hasPendingRequest)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.hourglass_empty),
                  label: const Text('好友请求待确认'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _removeFriend(user, friendViewModel),
                  icon: const Icon(Icons.person_remove),
                  label: const Text('删除好友'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(UserViewModel userViewModel) {
    return FloatingActionButton.extended(
      onPressed: () => _saveChanges(userViewModel),
      icon: const Icon(Icons.save),
      label: const Text('保存'),
    );
  }

  void _initializeEditForm(UserModel user) {
    _nicknameController.text = user.nickname ?? user.name;
    _bioController.text = user.bio ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phone ?? '';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedImage = null;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges(UserViewModel userViewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // TODO: Implement image upload functionality
      // String? avatarUrl;
      // if (_selectedImage != null) {
      //   avatarUrl = await ImageUtils.uploadImage(_selectedImage!);
      // }

      // TODO: Implement updateProfile method in UserViewModel
      // await userViewModel.updateProfile(
      //   nickname: _nicknameController.text.trim(),
      //   bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      //   email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      //   phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      //   avatarUrl: avatarUrl,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('资料更新成功'),
            backgroundColor: Colors.green,
          ),
        );
        _toggleEdit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendMessage(UserModel user, ChatViewModel chatViewModel) async {
    try {
      // TODO: Implement createOrGetPrivateChat method in ChatViewModel
      // final chatId = await chatViewModel.createOrGetPrivateChat(user.id);
      if (mounted) {
        widget.onSendMessage?.call(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建聊天失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addFriend(UserModel user, FriendViewModel friendViewModel) async {
    try {
      await friendViewModel.sendFriendRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已向 ${user.nickname} 发送好友请求'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onAddFriend?.call(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送好友请求失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFriend(UserModel user, FriendViewModel friendViewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友 ${user.nickname ?? user.name} 吗？'),
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
        await friendViewModel.removeFriend(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除好友 ${user.nickname}'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onRemoveFriend?.call(user);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除好友失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}