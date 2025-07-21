import 'package:flutter/material.dart';

import '../../themes/app_theme.dart';
import '../../widgets/common/custom_list_tile.dart';

/// 小程序页面
/// 
/// 显示和管理小程序
class MiniProgramsPage extends StatefulWidget {
  const MiniProgramsPage({Key? key}) : super(key: key);

  @override
  State<MiniProgramsPage> createState() => _MiniProgramsPageState();
}

class _MiniProgramsPageState extends State<MiniProgramsPage> {
  // 我的小程序列表
  final List<MiniProgram> _myMiniPrograms = [
    MiniProgram(
      id: 'mini_1',
      name: '扫一扫',
      icon: Icons.qr_code_scanner,
      color: Colors.green,
      description: '扫描二维码',
    ),
    MiniProgram(
      id: 'mini_2',
      name: '收付款',
      icon: Icons.payment,
      color: Colors.blue,
      description: '收款和付款',
    ),
    MiniProgram(
      id: 'mini_3',
      name: '出行服务',
      icon: Icons.directions_car,
      color: Colors.orange,
      description: '打车、公交、地铁等',
    ),
    MiniProgram(
      id: 'mini_4',
      name: '购物',
      icon: Icons.shopping_bag,
      color: Colors.red,
      description: '网上购物',
    ),
  ];
  
  // 推荐小程序列表
  final List<MiniProgram> _recommendedMiniPrograms = [
    MiniProgram(
      id: 'mini_5',
      name: '美食外卖',
      icon: Icons.fastfood,
      color: Colors.amber,
      description: '点外卖',
    ),
    MiniProgram(
      id: 'mini_6',
      name: '电影票',
      icon: Icons.movie,
      color: Colors.purple,
      description: '购买电影票',
    ),
    MiniProgram(
      id: 'mini_7',
      name: '酒店',
      icon: Icons.hotel,
      color: Colors.indigo,
      description: '预订酒店',
    ),
    MiniProgram(
      id: 'mini_8',
      name: '天气',
      icon: Icons.cloud,
      color: Colors.lightBlue,
      description: '查看天气预报',
    ),
    MiniProgram(
      id: 'mini_9',
      name: '快递查询',
      icon: Icons.local_shipping,
      color: Colors.brown,
      description: '查询快递信息',
    ),
    MiniProgram(
      id: 'mini_10',
      name: '记账本',
      icon: Icons.account_balance_wallet,
      color: Colors.teal,
      description: '记录收支',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小程序'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchMiniPrograms,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 我的小程序
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingNormal),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '我的小程序',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _manageMiniPrograms,
                    child: const Text('管理'),
                  ),
                ],
              ),
            ),
            _buildMiniProgramGrid(_myMiniPrograms),
            
            const SizedBox(height: AppTheme.spacingNormal),
            
            // 推荐小程序
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingNormal),
              child: Text(
                '推荐小程序',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
            ),
            _buildMiniProgramGrid(_recommendedMiniPrograms),
          ],
        ),
      ),
    );
  }
  
  // 构建小程序网格
  Widget _buildMiniProgramGrid(List<MiniProgram> miniPrograms) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingNormal),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppTheme.spacingSmall,
        mainAxisSpacing: AppTheme.spacingNormal,
        childAspectRatio: 0.8,
      ),
      itemCount: miniPrograms.length,
      itemBuilder: (context, index) {
        final miniProgram = miniPrograms[index];
        return MiniProgramItem(
          miniProgram: miniProgram,
          onTap: () => _openMiniProgram(miniProgram),
        );
      },
    );
  }
  
  // 搜索小程序
  void _searchMiniPrograms() {
    showSearch(
      context: context,
      delegate: MiniProgramSearchDelegate(
        allMiniPrograms: [..._myMiniPrograms, ..._recommendedMiniPrograms],
        onMiniProgramSelected: _openMiniProgram,
      ),
    );
  }
  
  // 管理小程序
  void _manageMiniPrograms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageMiniProgramsPage(
          miniPrograms: _myMiniPrograms,
        ),
      ),
    );
  }
  
  // 打开小程序
  void _openMiniProgram(MiniProgram miniProgram) {
    // 这里可以实现打开小程序的逻辑
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('打开${miniProgram.name}'),
        content: Text('即将打开${miniProgram.name}小程序'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 打开小程序
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${miniProgram.name}小程序即将上线')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 小程序模型
class MiniProgram {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  
  MiniProgram({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// 小程序项组件
class MiniProgramItem extends StatelessWidget {
  final MiniProgram miniProgram;
  final VoidCallback onTap;
  
  const MiniProgramItem({
    Key? key,
    required this.miniProgram,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: miniProgram.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusNormal),
            ),
            child: Icon(
              miniProgram.icon,
              color: miniProgram.color,
              size: 30,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          
          // 名称
          Text(
            miniProgram.name,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 小程序搜索代理
class MiniProgramSearchDelegate extends SearchDelegate<MiniProgram?> {
  final List<MiniProgram> allMiniPrograms;
  final Function(MiniProgram) onMiniProgramSelected;
  
  MiniProgramSearchDelegate({
    required this.allMiniPrograms,
    required this.onMiniProgramSelected,
  });
  
  @override
  String get searchFieldLabel => '搜索小程序';
  
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
        child: Text('输入关键词搜索小程序'),
      );
    }
    
    final results = allMiniPrograms.where((program) {
      return program.name.toLowerCase().contains(query.toLowerCase()) ||
             program.description.toLowerCase().contains(query.toLowerCase());
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
              '没有找到相关小程序',
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
        final miniProgram = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: miniProgram.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              miniProgram.icon,
              color: miniProgram.color,
            ),
          ),
          title: Text(miniProgram.name),
          subtitle: Text(miniProgram.description),
          onTap: () {
            close(context, miniProgram);
            onMiniProgramSelected(miniProgram);
          },
        );
      },
    );
  }
}

/// 管理小程序页面
class ManageMiniProgramsPage extends StatefulWidget {
  final List<MiniProgram> miniPrograms;
  
  const ManageMiniProgramsPage({
    Key? key,
    required this.miniPrograms,
  }) : super(key: key);

  @override
  State<ManageMiniProgramsPage> createState() => _ManageMiniProgramsPageState();
}

class _ManageMiniProgramsPageState extends State<ManageMiniProgramsPage> {
  late List<MiniProgram> _miniPrograms;
  
  @override
  void initState() {
    super.initState();
    _miniPrograms = List.from(widget.miniPrograms);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理小程序'),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingNormal),
        itemCount: _miniPrograms.length,
        itemBuilder: (context, index) {
          final miniProgram = _miniPrograms[index];
          return Dismissible(
            key: Key(miniProgram.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              color: Colors.red,
              padding: const EdgeInsets.only(right: AppTheme.spacingNormal),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              setState(() {
                _miniPrograms.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${miniProgram.name}已移除'),
                  action: SnackBarAction(
                    label: '撤销',
                    onPressed: () {
                      setState(() {
                        _miniPrograms.insert(index, miniProgram);
                      });
                    },
                  ),
                ),
              );
            },
            child: Card(
              child: CustomListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: miniProgram.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Icon(
                    miniProgram.icon,
                    color: miniProgram.color,
                  ),
                ),
                title: Text(miniProgram.name),
                subtitle: Text(miniProgram.description),
                trailing: const Icon(Icons.drag_handle),
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _miniPrograms.removeAt(oldIndex);
            _miniPrograms.insert(newIndex, item);
          });
        },
      ),
    );
  }
}