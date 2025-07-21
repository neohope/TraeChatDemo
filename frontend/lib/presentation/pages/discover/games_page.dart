import 'package:flutter/material.dart';

import '../../themes/app_theme.dart';

/// 游戏页面
/// 
/// 显示和管理游戏
class GamesPage extends StatefulWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 我的游戏列表
  final List<Game> _myGames = [
    Game(
      id: 'game_1',
      name: '跳一跳',
      icon: 'https://picsum.photos/200/200?random=1',
      description: '考验反应能力的休闲游戏',
      category: '休闲',
      rating: 4.5,
      downloadCount: '1000万+',
      isInstalled: true,
    ),
    Game(
      id: 'game_2',
      name: '消灭星星',
      icon: 'https://picsum.photos/200/200?random=2',
      description: '经典三消游戏',
      category: '休闲',
      rating: 4.3,
      downloadCount: '5000万+',
      isInstalled: true,
    ),
  ];
  
  // 推荐游戏列表
  final List<Game> _recommendedGames = [
    Game(
      id: 'game_3',
      name: '王者荣耀',
      icon: 'https://picsum.photos/200/200?random=3',
      description: '5v5多人在线竞技游戏',
      category: 'MOBA',
      rating: 4.7,
      downloadCount: '1亿+',
      isInstalled: false,
    ),
    Game(
      id: 'game_4',
      name: '和平精英',
      icon: 'https://picsum.photos/200/200?random=4',
      description: '多人生存竞技游戏',
      category: '射击',
      rating: 4.6,
      downloadCount: '5000万+',
      isInstalled: false,
    ),
    Game(
      id: 'game_5',
      name: '开心消消乐',
      icon: 'https://picsum.photos/200/200?random=5',
      description: '休闲益智消除游戏',
      category: '休闲',
      rating: 4.4,
      downloadCount: '1亿+',
      isInstalled: false,
    ),
    Game(
      id: 'game_6',
      name: '原神',
      icon: 'https://picsum.photos/200/200?random=6',
      description: '开放世界冒险游戏',
      category: '角色扮演',
      rating: 4.8,
      downloadCount: '5000万+',
      isInstalled: false,
    ),
  ];
  
  // 热门游戏列表
  final List<Game> _hotGames = [
    Game(
      id: 'game_7',
      name: '阴阳师',
      icon: 'https://picsum.photos/200/200?random=7',
      description: '和风回合制RPG',
      category: '角色扮演',
      rating: 4.5,
      downloadCount: '3000万+',
      isInstalled: false,
    ),
    Game(
      id: 'game_8',
      name: '第五人格',
      icon: 'https://picsum.photos/200/200?random=8',
      description: '非对称性对抗竞技游戏',
      category: '竞技',
      rating: 4.6,
      downloadCount: '2000万+',
      isInstalled: false,
    ),
    Game(
      id: 'game_9',
      name: '我的世界',
      icon: 'https://picsum.photos/200/200?random=9',
      description: '沙盒建造游戏',
      category: '沙盒',
      rating: 4.7,
      downloadCount: '1亿+',
      isInstalled: false,
    ),
    Game(
      id: 'game_10',
      name: '荒野乱斗',
      icon: 'https://picsum.photos/200/200?random=10',
      description: '3v3多人在线竞技游戏',
      category: '竞技',
      rating: 4.5,
      downloadCount: '5000万+',
      isInstalled: false,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchGames,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '我的游戏'),
            Tab(text: '热门'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 推荐游戏
          _buildRecommendedGamesTab(),
          
          // 我的游戏
          _buildMyGamesTab(),
          
          // 热门游戏
          _buildHotGamesTab(),
        ],
      ),
    );
  }
  
  // 构建推荐游戏标签页
  Widget _buildRecommendedGamesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 精选游戏
          const Text(
            '精选游戏',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontSizeLarge,
            ),
          ),
          const SizedBox(height: AppTheme.spacingNormal),
          
          // 精选游戏横向列表
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedGames.length,
              itemBuilder: (context, index) {
                final game = _recommendedGames[index];
                return FeaturedGameCard(
                  game: game,
                  onTap: () => _openGameDetail(game),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // 新游推荐
          const Text(
            '新游推荐',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontSizeLarge,
            ),
          ),
          const SizedBox(height: AppTheme.spacingNormal),
          
          // 新游推荐列表
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendedGames.length,
            itemBuilder: (context, index) {
              final game = _recommendedGames[index];
              return GameListItem(
                game: game,
                onTap: () => _openGameDetail(game),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // 构建我的游戏标签页
  Widget _buildMyGamesTab() {
    if (_myGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingNormal),
            Text(
              '你还没有安装游戏',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('去发现游戏'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      itemCount: _myGames.length,
      itemBuilder: (context, index) {
        final game = _myGames[index];
        return GameListItem(
          game: game,
          onTap: () => _openGameDetail(game),
          showInstallButton: false,
          showPlayButton: true,
        );
      },
    );
  }
  
  // 构建热门游戏标签页
  Widget _buildHotGamesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingNormal),
      itemCount: _hotGames.length,
      itemBuilder: (context, index) {
        final game = _hotGames[index];
        return GameListItem(
          game: game,
          onTap: () => _openGameDetail(game),
          showRanking: true,
          ranking: index + 1,
        );
      },
    );
  }
  
  // 搜索游戏
  void _searchGames() {
    showSearch(
      context: context,
      delegate: GameSearchDelegate(
        allGames: [..._myGames, ..._recommendedGames, ..._hotGames],
        onGameSelected: _openGameDetail,
      ),
    );
  }
  
  // 打开游戏详情
  void _openGameDetail(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailPage(game: game),
      ),
    );
  }
}

/// 游戏模型
class Game {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String category;
  final double rating;
  final String downloadCount;
  final bool isInstalled;
  
  Game({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.rating,
    required this.downloadCount,
    required this.isInstalled,
  });
}

/// 精选游戏卡片
class FeaturedGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  
  const FeaturedGameCard({
    Key? key,
    required this.game,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: AppTheme.spacingNormal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 游戏图标
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
              child: Image.network(
                game.icon,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            
            // 游戏名称
            Text(
              game.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fontSizeMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // 游戏分类
            Text(
              game.category,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 游戏列表项
class GameListItem extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final bool showInstallButton;
  final bool showPlayButton;
  final bool showRanking;
  final int? ranking;
  
  const GameListItem({
    Key? key,
    required this.game,
    required this.onTap,
    this.showInstallButton = true,
    this.showPlayButton = false,
    this.showRanking = false,
    this.ranking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingSmall,
        horizontal: AppTheme.spacingNormal,
      ),
      leading: Stack(
        children: [
          // 游戏图标
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Image.network(
              game.icon,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          
          // 排名标签
          if (showRanking && ranking != null)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getRankingColor(ranking!),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusSmall),
                    bottomRight: Radius.circular(AppTheme.borderRadiusSmall),
                  ),
                ),
                child: Text(
                  '$ranking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(game.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            game.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // 评分
              Icon(Icons.star, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                game.rating.toString(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
              const SizedBox(width: AppTheme.spacingNormal),
              
              // 下载量
              Icon(Icons.download, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                game.downloadCount,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: showPlayButton
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingNormal,
                  vertical: AppTheme.spacingSmall / 2,
                ),
              ),
              child: const Text('开始'),
            )
          : (showInstallButton
              ? OutlinedButton(
                  onPressed: () => _installGame(context, game),
                  child: const Text('安装'),
                )
              : null),
      onTap: onTap,
    );
  }
  
  // 获取排名颜色
  Color _getRankingColor(int ranking) {
    if (ranking == 1) return Colors.red;
    if (ranking == 2) return Colors.orange;
    if (ranking == 3) return Colors.amber;
    return Colors.grey;
  }
  
  // 安装游戏
  void _installGame(BuildContext context, Game game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在安装${game.name}...')),
    );
  }
}

/// 游戏搜索代理
class GameSearchDelegate extends SearchDelegate<Game?> {
  final List<Game> allGames;
  final Function(Game) onGameSelected;
  
  GameSearchDelegate({
    required this.allGames,
    required this.onGameSelected,
  });
  
  @override
  String get searchFieldLabel => '搜索游戏';
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }
  
  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键词搜索游戏'),
      );
    }
    
    final results = allGames.where((game) {
      return game.name.toLowerCase().contains(query.toLowerCase()) ||
             game.description.toLowerCase().contains(query.toLowerCase()) ||
             game.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
    
    if (results.isEmpty) {
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
              '没有找到相关游戏',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final game = results[index];
        return GameListItem(
          game: game,
          onTap: () {
            close(context, game);
            onGameSelected(game);
          },
        );
      },
    );
  }
}

/// 游戏详情页面
class GameDetailPage extends StatelessWidget {
  final Game game;
  
  const GameDetailPage({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 应用栏
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                game.icon,
                fit: BoxFit.cover,
              ),
              title: Text(game.name),
            ),
          ),
          
          // 游戏信息
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingNormal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 游戏基本信息
                  Row(
                    children: [
                      // 游戏图标
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
                        child: Image.network(
                          game.icon,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingNormal),
                      
                      // 游戏信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.fontSizeLarge,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              game.category,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: AppTheme.fontSizeSmall,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // 评分
                                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  game.rating.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingNormal),
                                
                                // 下载量
                                Text(
                                  game.downloadCount,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: AppTheme.fontSizeSmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingNormal),
                  
                  // 安装/开始按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _playOrInstallGame(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingNormal),
                      ),
                      child: Text(game.isInstalled ? '开始' : '安装'),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // 游戏截图
                  const Text(
                    '游戏截图',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                            child: Image.network(
                              'https://picsum.photos/600/300?random=${index + 20}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // 游戏介绍
                  const Text(
                    '游戏介绍',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    '${game.description}\n\n这是一款非常好玩的游戏，拥有精美的画面和流畅的操作体验。游戏中，玩家可以体验到丰富的游戏内容和多样的玩法。\n\n游戏特色：\n- 精美的画面和音效\n- 丰富的游戏内容\n- 多样的玩法\n- 社交互动功能\n\n赶快下载体验吧！',
                    style: const TextStyle(
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // 用户评价
                  const Text(
                    '用户评价',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  _buildUserReviews(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建用户评价
  Widget _buildUserReviews() {
    final reviews = [
      UserReview(
        username: '用户1',
        avatar: 'https://picsum.photos/200/200?random=101',
        rating: 5.0,
        content: '非常好玩的游戏，画面精美，操作流畅。',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      UserReview(
        username: '用户2',
        avatar: 'https://picsum.photos/200/200?random=102',
        rating: 4.0,
        content: '游戏内容丰富，但有时会卡顿。',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      UserReview(
        username: '用户3',
        avatar: 'https://picsum.photos/200/200?random=103',
        rating: 5.0,
        content: '很好玩，推荐给大家！',
        date: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
    
    return Column(
      children: reviews.map((review) => _buildReviewItem(review)).toList(),
    );
  }
  
  // 构建评价项
  Widget _buildReviewItem(UserReview review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(review.avatar),
          ),
          const SizedBox(width: AppTheme.spacingNormal),
          
          // 评价内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名和评分
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating.floor() ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // 评价内容
                Text(review.content),
                const SizedBox(height: 4),
                
                // 评价日期
                Text(
                  _formatDate(review.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // 安装或开始游戏
  void _playOrInstallGame(BuildContext context) {
    if (game.isInstalled) {
      // 开始游戏
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正在启动${game.name}...')),
      );
    } else {
      // 安装游戏
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正在安装${game.name}...')),
      );
    }
  }
}

/// 用户评价模型
class UserReview {
  final String username;
  final String avatar;
  final double rating;
  final String content;
  final DateTime date;
  
  UserReview({
    required this.username,
    required this.avatar,
    required this.rating,
    required this.content,
    required this.date,
  });
}