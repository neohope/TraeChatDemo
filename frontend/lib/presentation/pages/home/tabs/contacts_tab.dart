import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/user_model.dart';
import '../../../../domain/viewmodels/user_viewmodel.dart';
import '../../../routes/app_router.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/user/user_list_item.dart';

/// 联系人标签页，显示用户联系人列表
class ContactsTab extends StatefulWidget {
  const ContactsTab({Key? key}) : super(key: key);

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // 加载联系人列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserViewModel>(context, listen: false).loadContacts();
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  // 搜索内容变化
  void _onSearchChanged() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final query = _searchController.text.trim();
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isNotEmpty) {
      // 执行搜索
      userViewModel.searchContacts(query);
    } else {
      // 清空搜索，显示所有联系人
      userViewModel.clearContactSearch();
    }
  }
  
  // 刷新联系人列表
  Future<void> _refreshContacts() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await userViewModel.loadContacts(forceRefresh: true);
  }
  
  // 添加新联系人
  void _addNewContact() {
    // 导航到添加联系人页面或显示添加联系人对话框
    _showAddContactDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          // 添加联系人按钮
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addNewContact,
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingNormal),
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: '搜索联系人',
                    prefixIcon: Icons.search,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          // 获取联系人列表
          final contacts = _isSearching
              ? userViewModel.convertToUserModelList(userViewModel.searchResults)
              : userViewModel.convertToUserModelList(userViewModel.contacts);
          
          // 如果正在加载且没有数据，显示加载指示器
          if (userViewModel.isLoading && contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 如果没有联系人，显示空状态
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppTheme.spacingNormal),
                  Text(
                    _isSearching ? '没有找到相关联系人' : '暂无联系人',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (!_isSearching) ...[  
                    const SizedBox(height: AppTheme.spacingLarge),
                    ElevatedButton.icon(
                      onPressed: _addNewContact,
                      icon: const Icon(Icons.person_add),
                      label: const Text('添加联系人'),
                    ),
                  ],
                ],
              ),
            );
          }
          
          // 按字母分组显示联系人
          final Map<String, List<UserModel>> groupedContacts = {};
          
          // 对联系人进行分组
          for (var contact in contacts) {
            final firstLetter = contact.name.substring(0, 1).toUpperCase();
            if (!groupedContacts.containsKey(firstLetter)) {
              groupedContacts[firstLetter] = [];
            }
            groupedContacts[firstLetter]!.add(contact);
          }
          
          // 获取所有分组的首字母并排序
          final sortedKeys = groupedContacts.keys.toList()..sort();
          
          // 显示联系人列表
          return RefreshIndicator(
            onRefresh: _refreshContacts,
            child: ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final key = sortedKeys[index];
                final contactsInGroup = groupedContacts[key]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分组标题
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingNormal,
                        AppTheme.spacingSmall,
                        AppTheme.spacingNormal,
                        AppTheme.spacingSmall,
                      ),
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    // 分组中的联系人列表
                    ...contactsInGroup.map((contact) => UserListItem(
                      user: contact,
                      onTap: () {
                        // 导航到联系人详情页面
                        AppRouter.router.go(
                          '${AppRouter.profile}/${contact.id}',
                          extra: {'userName': contact.name},
                        );
                      },
                      onLongPress: () {
                        // 显示联系人操作菜单
                        _showContactOptions(contact);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () {
                          // 导航到聊天页面
                          AppRouter.router.go(
                            '${AppRouter.chat}/${contact.id}',
                            extra: {'userName': contact.name},
                          );
                        },
                      ),
                    )),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewContact,
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  // 显示添加联系人对话框
  void _showAddContactDialog() {
    final TextEditingController usernameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加联系人'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: usernameController,
                labelText: '用户名或邮箱',
                hintText: '输入用户名或邮箱',
                prefixIcon: Icons.person,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final username = usernameController.text.trim();
                if (username.isNotEmpty) {
                  Navigator.pop(context);
                  // 添加联系人
                  final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                  userViewModel.addContact(username).then((response) {
                    if (mounted) {
                      if (response.success && response.data == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('联系人添加成功')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response.message ?? '联系人添加失败，请检查用户名或邮箱是否正确')),
                        );
                      }
                    }
                  });
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
  
  // 显示联系人操作菜单
  void _showContactOptions(UserModel contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('发送消息'),
                onTap: () {
                  Navigator.pop(context);
                  // 导航到聊天页面
                  AppRouter.router.go(
                    '${AppRouter.chat}/${contact.id}',
                    extra: {'userName': contact.name},
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('查看资料'),
                onTap: () {
                  Navigator.pop(context);
                  // 导航到联系人详情页面
                  AppRouter.router.go(
                    '${AppRouter.profile}/${contact.id}',
                    extra: {'userName': contact.name},
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: Text(contact.isFavorite ? '取消收藏' : '添加收藏'),
                onTap: () {
                  Navigator.pop(context);
                  // 切换收藏状态
                  final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                  userViewModel.toggleFavoriteContact(contact.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.orange),
                title: const Text('拉黑联系人', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  // 确认拉黑联系人
                  _confirmBlockContact(contact);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除联系人', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // 确认删除联系人
                  _confirmDeleteContact(contact);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 确认拉黑联系人
  void _confirmBlockContact(UserModel contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('拉黑联系人'),
          content: Text('确定要将 ${contact.name} 拉黑吗？拉黑后将不再收到对方的消息。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 拉黑联系人
                final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                userViewModel.blockContact(contact.id).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已将 ${contact.name} 拉黑')),
                    );
                  }
                });
              },
              child: const Text('确定', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }
  
  // 确认删除联系人
  void _confirmDeleteContact(UserModel contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除联系人'),
          content: Text('确定要删除 ${contact.name} 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 删除联系人
                final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                userViewModel.deleteContact(contact.id).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已删除联系人 ${contact.name}')),
                    );
                  }
                });
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}