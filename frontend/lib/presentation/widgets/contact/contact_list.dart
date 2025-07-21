import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:azlistview/azlistview.dart';

import '../../../domain/models/user_model.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../../domain/viewmodels/conversation_viewmodel.dart';
import '../../../presentation/pages/chat/chat_page.dart';
import 'contact_list_item.dart';

/// 联系人列表组件
/// 
/// 用于显示所有联系人，支持按字母分组、搜索、下拉刷新等功能
class ContactList extends StatefulWidget {
  const ContactList({Key? key}) : super(key: key);

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  
  @override
  void initState() {
    super.initState();
    // 延迟加载联系人列表，避免与页面构建冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshContacts();
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _refreshContacts() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await userViewModel.loadContacts();
  }
  
  void _navigateToChatPage(UserModel user) async {
    final conversationViewModel = Provider.of<ConversationViewModel>(context, listen: false);
    
    // 获取或创建与该用户的会话
    final response = await conversationViewModel.createOrGetUserConversation(user.id);
    
    if (mounted && response.success && response.data != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userId: user.id,
            userName: user.name,
          ),
        ),
      );
    }
  }
  
  void _showContactOptions(UserModel user) {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              user.isFavorite ? Icons.star_border : Icons.star,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(user.isFavorite ? '取消收藏' : '收藏'),
            onTap: () {
              userViewModel.toggleFavoriteContact(user.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              user.isBlocked ? Icons.block_outlined : Icons.block,
              color: Colors.red,
            ),
            title: Text(user.isBlocked ? '取消拉黑' : '拉黑'),
            onTap: () {
              userViewModel.toggleBlockContact(user.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text('删除联系人'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(user);
            },
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除联系人'),
        content: Text('确定要删除联系人 ${user.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final userViewModel = Provider.of<UserViewModel>(context, listen: false);
              userViewModel.deleteContact(user.id);
              Navigator.pop(context);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索联系人',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: Consumer<UserViewModel>(
            builder: (context, userViewModel, child) {
              if (userViewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (userViewModel.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败: ${userViewModel.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshContacts,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }
              
              final contacts = userViewModel.contacts;
              
              if (contacts.isEmpty) {
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshContacts,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 3),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 80,
                              color: Colors.grey.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '没有联系人',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.withAlpha(204),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '添加新的联系人开始聊天吧',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.withAlpha(153),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // 将 User 列表转换为 UserModel 列表
              final userModels = userViewModel.convertToUserModelList(contacts);
              
              // 过滤联系人
              final filteredContacts = _searchText.isEmpty
                  ? userModels
                  : userModels.where((contact) {
                      return contact.name.toLowerCase().contains(_searchText.toLowerCase()) ||
                          (contact.email?.toLowerCase().contains(_searchText.toLowerCase()) ?? false) ||
                          (contact.phone?.toLowerCase().contains(_searchText.toLowerCase()) ?? false);
                    }).toList();
              
              if (filteredContacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '没有找到匹配的联系人',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // 分离收藏和非收藏联系人
              final favoriteContacts = filteredContacts.where((c) => c.isFavorite).toList();
              final normalContacts = filteredContacts.where((c) => !c.isFavorite).toList();
              
              // 按字母排序非收藏联系人
              normalContacts.sort((a, b) => a.name.compareTo(b.name));
              
              // 创建字母索引列表
              final List<_AZItem> azItems = [];
              
              // 添加收藏联系人
              if (favoriteContacts.isNotEmpty) {
                azItems.add(_AZItem(
                  tag: '★',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                        child: Text(
                          '收藏联系人',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      ...favoriteContacts.map((contact) => Column(
                        children: [
                          ContactListItem(
                            user: contact,
                            onTap: _navigateToChatPage,
                            onLongPress: _showContactOptions,
                          ),
                          const Divider(height: 1, indent: 72),
                        ],
                      )),
                    ],
                  ),
                ));
              }
              
              // 按字母分组非收藏联系人
              String currentTag = '';
              List<UserModel> currentTagContacts = [];
              
              for (final contact in normalContacts) {
                final firstLetter = contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '#';
                
                if (firstLetter != currentTag) {
                  if (currentTagContacts.isNotEmpty) {
                    azItems.add(_createAZItem(currentTag, currentTagContacts));
                    currentTagContacts = [];
                  }
                  currentTag = firstLetter;
                }
                
                currentTagContacts.add(contact);
              }
              
              if (currentTagContacts.isNotEmpty) {
                azItems.add(_createAZItem(currentTag, currentTagContacts));
              }
              
              return RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshContacts,
                child: AzListView(
                  data: azItems,
                  itemCount: azItems.length,
                  itemBuilder: (context, index) {
                    return azItems[index].child;
                  },
                  physics: const AlwaysScrollableScrollPhysics(),
                  indexBarOptions: IndexBarOptions(
                    needRebuild: true,
                    indexHintAlignment: Alignment.centerRight,
                    indexHintOffset: const Offset(-20, 0),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  _AZItem _createAZItem(String tag, List<UserModel> contacts) {
    return _AZItem(
      tag: tag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              tag,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...contacts.map((contact) => Column(
            children: [
              ContactListItem(
                user: contact,
                onTap: _navigateToChatPage,
                onLongPress: _showContactOptions,
              ),
              const Divider(height: 1, indent: 72),
            ],
          )),
        ],
      ),
    );
  }
}

class _AZItem implements ISuspensionBean {
  final String tag;
  final Widget child;
  bool _isShowSuspension = true;
  
  _AZItem({required this.tag, required this.child});
  
  @override
  String getSuspensionTag() => tag;

  @override
  bool get isShowSuspension => _isShowSuspension;

  @override
  set isShowSuspension(bool value) {
    _isShowSuspension = value;
  }
}