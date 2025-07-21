import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_model.dart';
import '../../../domain/viewmodels/user_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

/// 朋友圈页面
/// 
/// 显示用户发布的动态内容，包括文字、图片等
class MomentsPage extends StatefulWidget {
  const MomentsPage({Key? key}) : super(key: key);

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  List<MomentItem> _moments = [];
  
  @override
  void initState() {
    super.initState();
    _loadMoments();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // 滚动监听器，用于实现下拉加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreMoments();
    }
  }
  
  // 加载朋友圈动态
  Future<void> _loadMoments() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // 模拟从服务器加载数据
    await Future.delayed(const Duration(seconds: 1));
    
    // 生成测试数据
    final testMoments = List.generate(
      10,
      (index) => MomentItem(
        id: 'moment_$index',
        userId: 'user_${index % 5}',
        content: '这是第 ${index + 1} 条朋友圈内容，分享生活点滴...',
        images: index % 3 == 0 ? [] : List.generate(
          index % 5 + 1,
          (imgIndex) => 'https://picsum.photos/500/500?random=${index * 10 + imgIndex}',
        ),
        likeCount: index * 5,
        commentCount: index * 3,
        timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
        isLiked: index % 2 == 0,
      ),
    );
    
    setState(() {
      _moments = testMoments;
      _isLoading = false;
      _hasMore = true;
    });
  }
  
  // 加载更多朋友圈动态
  Future<void> _loadMoreMoments() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // 模拟从服务器加载更多数据
    await Future.delayed(const Duration(seconds: 1));
    
    final lastIndex = _moments.length;
    final moreMoments = List.generate(
      5,
      (index) => MomentItem(
        id: 'moment_${lastIndex + index}',
        userId: 'user_${(lastIndex + index) % 5}',
        content: '这是第 ${lastIndex + index + 1} 条朋友圈内容，分享生活点滴...',
        images: (lastIndex + index) % 3 == 0 ? [] : List.generate(
          (lastIndex + index) % 4 + 1,
          (imgIndex) => 'https://picsum.photos/500/500?random=${(lastIndex + index) * 10 + imgIndex}',
        ),
        likeCount: (lastIndex + index) * 3,
        commentCount: (lastIndex + index) * 2,
        timestamp: DateTime.now().subtract(Duration(hours: (lastIndex + index) * 2)),
        isLiked: (lastIndex + index) % 2 == 0,
      ),
    );
    
    // 模拟没有更多数据的情况
    final noMoreData = _moments.length > 20;
    
    setState(() {
      _moments.addAll(moreMoments);
      _isLoading = false;
      _hasMore = !noMoreData;
    });
  }
  
  // 发布新动态
  void _publishNewMoment() {
    // 导航到发布页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PublishMomentPage(),
      ),
    ).then((_) {
      // 刷新朋友圈
      _loadMoments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          final currentUser = userViewModel.currentUser;
          
          if (currentUser == null) {
            return const Center(child: Text('请先登录'));
          }
          
          // 将 User 类型转换为 UserModel 类型
          final currentUserModel = UserModel(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            phone: currentUser.phoneNumber,
            avatarUrl: currentUser.avatarUrl,
            bio: currentUser.bio,
            lastSeen: currentUser.lastActive,
            isFavorite: currentUser.isFavorite,
            isBlocked: currentUser.isBlocked,
          );
          
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 朋友圈头部
              _buildMomentsHeader(currentUserModel),
              
              // 朋友圈列表
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _moments.length) {
                      final moment = _moments[index];
                      // 获取用户并转换为 UserModel
                      final user = userViewModel.getCachedUserById(moment.userId);
                      final userModel = user != null
                          ? UserModel(
                              id: user.id,
                              name: user.name,
                              email: user.email,
                              phone: user.phoneNumber,
                              avatarUrl: user.avatarUrl,
                              bio: user.bio,
                              lastSeen: user.lastActive,
                              isFavorite: user.isFavorite,
                              isBlocked: user.isBlocked,
                            )
                          : UserModel(id: moment.userId, name: '用户${moment.userId}');
                      
                      return MomentCard(
                        moment: moment,
                        user: userModel,
                        currentUserId: currentUser.id,
                        onLike: () => _toggleLike(moment.id),
                        onComment: () => _showCommentDialog(moment.id),
                      );
                    } else if (_hasMore) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingNormal),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingNormal),
                          child: Text('没有更多内容了'),
                        ),
                      );
                    }
                  },
                  childCount: _moments.length + (_hasMore ? 1 : 0),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _publishNewMoment,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // 构建朋友圈头部
  Widget _buildMomentsHeader(UserModel currentUser) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 背景图片
            Image.network(
              'https://picsum.photos/800/400?random=1',
              fit: BoxFit.cover,
            ),
            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            // 用户信息
            Positioned(
              right: AppTheme.spacingNormal,
              bottom: AppTheme.spacingNormal,
              child: Row(
                children: [
                  Text(
                    currentUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: currentUser.avatarUrl != null
                        ? NetworkImage(currentUser.avatarUrl!)
                        : null,
                    child: currentUser.avatarUrl == null
                        ? Text(currentUser.name[0])
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: const Text('朋友圈'),
      actions: [
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: _publishNewMoment,
        ),
      ],
    );
  }
  
  // 点赞/取消点赞
  void _toggleLike(String momentId) {
    setState(() {
      final index = _moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        final moment = _moments[index];
        final newMoment = MomentItem(
          id: moment.id,
          userId: moment.userId,
          content: moment.content,
          images: moment.images,
          likeCount: moment.isLiked ? moment.likeCount - 1 : moment.likeCount + 1,
          commentCount: moment.commentCount,
          timestamp: moment.timestamp,
          isLiked: !moment.isLiked,
        );
        _moments[index] = newMoment;
      }
    });
  }
  
  // 显示评论对话框
  void _showCommentDialog(String momentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingNormal),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '发表评论...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      // 提交评论
                      _submitComment(momentId, value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 提交评论
  void _submitComment(String momentId, String content) {
    setState(() {
      final index = _moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        final moment = _moments[index];
        final newMoment = MomentItem(
          id: moment.id,
          userId: moment.userId,
          content: moment.content,
          images: moment.images,
          likeCount: moment.likeCount,
          commentCount: moment.commentCount + 1,
          timestamp: moment.timestamp,
          isLiked: moment.isLiked,
        );
        _moments[index] = newMoment;
      }
    });
    
    // 显示提交成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('评论成功')),
    );
  }
}

/// 朋友圈动态项
class MomentItem {
  final String id;
  final String userId;
  final String content;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final DateTime timestamp;
  final bool isLiked;
  
  MomentItem({
    required this.id,
    required this.userId,
    required this.content,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.timestamp,
    required this.isLiked,
  });
}

/// 朋友圈卡片组件
class MomentCard extends StatelessWidget {
  final MomentItem moment;
  final UserModel user;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  
  const MomentCard({
    Key? key,
    required this.moment,
    required this.user,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingNormal,
        vertical: AppTheme.spacingSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingNormal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.name[0])
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.fontSizeMedium,
                        ),
                      ),
                      Text(
                        _formatTimestamp(moment.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: AppTheme.fontSizeSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                // 更多操作按钮
                if (moment.userId == currentUserId)
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _showMoreOptions(context),
                  ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSmall),
            
            // 动态内容
            Text(moment.content),
            
            // 图片内容
            if (moment.images.isNotEmpty) ...[  
              const SizedBox(height: AppTheme.spacingSmall),
              _buildImageGrid(context, moment.images),
            ],
            
            const SizedBox(height: AppTheme.spacingSmall),
            
            // 点赞和评论
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 点赞按钮
                TextButton.icon(
                  icon: Icon(
                    moment.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: moment.isLiked ? Colors.red : null,
                  ),
                  label: Text('${moment.likeCount}'),
                  onPressed: onLike,
                ),
                
                // 评论按钮
                TextButton.icon(
                  icon: const Icon(Icons.comment),
                  label: Text('${moment.commentCount}'),
                  onPressed: onComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建图片网格
  Widget _buildImageGrid(BuildContext context, List<String> images) {
    final int count = images.length;
    final int crossAxisCount = count == 1 ? 1 : (count == 4 ? 2 : 3);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.spacingSmall,
        mainAxisSpacing: AppTheme.spacingSmall,
        childAspectRatio: count == 1 ? 16 / 9 : 1.0,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _viewImage(context, images, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  // 查看大图
  void _viewImage(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  // 显示更多选项
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  // 编辑动态
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 确认删除
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除动态'),
          content: const Text('确定要删除这条动态吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 删除动态
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('动态已删除')),
                );
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  // 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }
  }
}

/// 发布朋友圈页面
class PublishMomentPage extends StatefulWidget {
  const PublishMomentPage({Key? key}) : super(key: key);

  @override
  State<PublishMomentPage> createState() => _PublishMomentPageState();
}

class _PublishMomentPageState extends State<PublishMomentPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedImages = [];
  bool _isPublishing = false;
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
  
  // 选择图片
  void _selectImages() {
    // 模拟选择图片
    setState(() {
      if (_selectedImages.length < 9) {
        _selectedImages.add('https://picsum.photos/500/500?random=${DateTime.now().millisecondsSinceEpoch}');
      }
    });
  }
  
  // 移除图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  // 发布动态
  Future<void> _publishMoment() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容或选择图片')),
      );
      return;
    }
    
    setState(() {
      _isPublishing = true;
    });
    
    // 模拟发布过程
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isPublishing = false;
    });
    
    // 发布成功，返回上一页
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布成功')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布动态'),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publishMoment,
            child: const Text('发布'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingNormal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 内容输入框
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: '分享你的生活点滴...',
                    border: InputBorder.none,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                ),
                
                const SizedBox(height: AppTheme.spacingNormal),
                
                // 图片网格
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppTheme.spacingSmall,
                    mainAxisSpacing: AppTheme.spacingSmall,
                  ),
                  itemCount: _selectedImages.length + (_selectedImages.length < 9 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      // 添加图片按钮
                      return GestureDetector(
                        onTap: _selectImages,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    } else {
                      // 已选图片
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                            child: Image.network(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // 删除按钮
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // 加载指示器
          if (_isPublishing)
            const LoadingOverlay(
              isLoading: true,
              child: SizedBox(),
            ),
        ],
      ),
    );
  }
}