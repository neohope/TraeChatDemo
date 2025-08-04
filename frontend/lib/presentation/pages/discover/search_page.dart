import 'package:flutter/material.dart';

import '../../../domain/models/user_model.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

/// 搜索页面
/// 
/// 用于搜索用户、群组、内容等
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearching = false;
  String _searchQuery = '';
  
  // 搜索结果
  List<UserModel> _userResults = [];
  List<GroupResult> _groupResults = [];
  List<ContentResult> _contentResults = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _userResults = [];
        _groupResults = [];
        _contentResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
    });
    
    // 模拟搜索延迟
    await Future.delayed(const Duration(seconds: 1));
    
    // 模拟搜索结果
    final userResults = List.generate(
      5,
      (index) => UserModel(
        id: 'user_$index',
        name: '用户_$query${index + 1}',
        avatarUrl: 'https://picsum.photos/200/200?random=$index',
      ),
    );
    
    final groupResults = List.generate(
      3,
      (index) => GroupResult(
        id: 'group_$index',
        name: '$query群组${index + 1}',
        avatar: 'https://picsum.photos/200/200?random=${index + 10}',
        memberCount: (index + 1) * 10,
      ),
    );
    
    final contentResults = List.generate(
      7,
      (index) => ContentResult(
        id: 'content_$index',
        title: '包含"$query"的内容${index + 1}',
        snippet: '这是一段包含"$query"的内容摘要，用于展示搜索结果...',
        source: index % 3 == 0 ? '朋友圈' : (index % 3 == 1 ? '聊天记录' : '文章'),
        timestamp: DateTime.now().subtract(Duration(days: index)),
      ),
    );
    
    setState(() {
      _userResults = userResults;
      _groupResults = groupResults;
      _contentResults = contentResults;
      _isSearching = false;
    });
  }
  
  // 清除搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _userResults = [];
      _groupResults = [];
      _contentResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索用户、群组、内容...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
        bottom: _searchQuery.isNotEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '用户'),
                  Tab(text: '群组'),
                  Tab(text: '内容'),
                ],
              )
            : null,
      ),
      body: Stack(
        children: [
          if (_searchQuery.isEmpty)
            _buildSearchSuggestions()
          else
            TabBarView(
              controller: _tabController,
              children: [
                // 用户搜索结果
                _buildUserResults(),
                
                // 群组搜索结果
                _buildGroupResults(),
                
                // 内容搜索结果
                _buildContentResults(),
              ],
            ),
          
          // 加载指示器
          if (_isSearching)
            LoadingOverlay(
              isLoading: true,
              child: Container(), // 空容器作为子组件
            ),
        ],
      ),
    );
  }
  
  // 构建搜索建议
  Widget _buildSearchSuggestions() {
    // 热门搜索
    final hotSearches = [
      '热门活动',
      '交友',
      '游戏',
      '附近的人',
      '美食',
      '旅游',
    ];
    
    // 搜索历史
    final searchHistory = [
      '朋友',
      '群组',
      '工作',
      '学习资料',
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 热门搜索
          const Text(
            '热门搜索',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontSizeMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: AppTheme.spacingSmall,
            children: hotSearches.map((term) => _buildSearchChip(term)).toList(),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // 搜索历史
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 清除搜索历史
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('搜索历史已清除')),
                  );
                },
                child: const Text('清除'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Column(
            children: searchHistory.map((term) => _buildHistoryItem(term)).toList(),
          ),
        ],
      ),
    );
  }
  
  // 构建搜索词芯片
  Widget _buildSearchChip(String term) {
    return ActionChip(
      label: Text(term),
      onPressed: () {
        _searchController.text = term;
        _performSearch(term);
      },
    );
  }
  
  // 构建历史记录项
  Widget _buildHistoryItem(String term) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(term),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        onPressed: () {
          // 从历史记录中删除
        },
      ),
      onTap: () {
        _searchController.text = term;
        _performSearch(term);
      },
    );
  }
  
  // 构建用户搜索结果
  Widget _buildUserResults() {
    if (_userResults.isEmpty && !_isSearching) {
      return _buildEmptyResults('没有找到相关用户');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return UserResultItem(
          user: user,
          onTap: () => _viewUserProfile(user),
        );
      },
    );
  }
  
  // 构建群组搜索结果
  Widget _buildGroupResults() {
    if (_groupResults.isEmpty && !_isSearching) {
      return _buildEmptyResults('没有找到相关群组');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      itemCount: _groupResults.length,
      itemBuilder: (context, index) {
        final group = _groupResults[index];
        return GroupResultItem(
          group: group,
          onTap: () => _viewGroupProfile(group),
        );
      },
    );
  }
  
  // 构建内容搜索结果
  Widget _buildContentResults() {
    if (_contentResults.isEmpty && !_isSearching) {
      return _buildEmptyResults('没有找到相关内容');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      itemCount: _contentResults.length,
      itemBuilder: (context, index) {
        final content = _contentResults[index];
        return ContentResultItem(
          content: content,
          onTap: () => _viewContent(content),
        );
      },
    );
  }
  
  // 构建空结果提示
  Widget _buildEmptyResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingNormal),
          Text(
            message,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            '尝试其他搜索词',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  // 查看用户资料
  void _viewUserProfile(UserModel user) {
    // 导航到用户资料页面
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': user.id},
    );
  }
  
  // 查看群组资料
  void _viewGroupProfile(GroupResult group) {
    // 导航到群组资料页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看群组: ${group.name}')),
    );
  }
  
  // 查看内容详情
  void _viewContent(ContentResult content) {
    // 导航到内容详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看内容: ${content.title}')),
    );
  }
}

/// 群组搜索结果
class GroupResult {
  final String id;
  final String name;
  final String avatar;
  final int memberCount;
  
  GroupResult({
    required this.id,
    required this.name,
    required this.avatar,
    required this.memberCount,
  });
}

/// 内容搜索结果
class ContentResult {
  final String id;
  final String title;
  final String snippet;
  final String source;
  final DateTime timestamp;
  
  ContentResult({
    required this.id,
    required this.title,
    required this.snippet,
    required this.source,
    required this.timestamp,
  });
}

/// 用户搜索结果项
class UserResultItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  
  const UserResultItem({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(user.name),
      subtitle: Text('ID: ${user.id}'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

/// 群组搜索结果项
class GroupResultItem extends StatelessWidget {
  final GroupResult group;
  final VoidCallback onTap;
  
  const GroupResultItem({
    Key? key,
    required this.group,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(group.avatar),
      ),
      title: Text(group.name),
      subtitle: Text('${group.memberCount}人'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

/// 内容搜索结果项
class ContentResultItem extends StatelessWidget {
  final ContentResult content;
  final VoidCallback onTap;
  
  const ContentResultItem({
    Key? key,
    required this.content,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(content.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                content.source,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
              const SizedBox(width: AppTheme.spacingNormal),
              Text(
                _formatTimestamp(content.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
  
  // 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays < 1) {
      return '今天';
    } else if (difference.inDays < 2) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }
}