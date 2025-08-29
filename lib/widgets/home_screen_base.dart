import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../widgets/experiment_card.dart';

/// ホーム画面の共通ベースウィジェット
class HomeScreenBase extends StatefulWidget {
  final String title;
  final List<Experiment> experiments;
  final bool canCreateExperiment;
  final String? userName;
  final bool isWasedaUser;
  final VoidCallback onLogout;
  final VoidCallback? onCreateExperiment;
  
  const HomeScreenBase({
    super.key,
    required this.title,
    required this.experiments,
    required this.canCreateExperiment,
    required this.userName,
    required this.isWasedaUser,
    required this.onLogout,
    this.onCreateExperiment,
  });

  @override
  State<HomeScreenBase> createState() => _HomeScreenBaseState();
}

enum SortOption {
  newest('新しい順'),
  oldest('古い順'),
  highReward('報酬額が高い順'),
  lowReward('報酬額が低い順'),
  soonest('開催日が近い順'),
  latest('開催日が遠い順');

  final String label;
  const SortOption(this.label);
}

class _HomeScreenBaseState extends State<HomeScreenBase> {
  ExperimentType? _selectedType;
  SortOption _sortOption = SortOption.newest;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isHeaderVisible = true;
  
  List<Experiment> get filteredExperiments {
    List<Experiment> filtered = List.from(widget.experiments);
    
    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((experiment) {
        // タイトル、説明、研究室名、場所で検索
        final titleMatch = experiment.title.toLowerCase().contains(query);
        final descriptionMatch = experiment.description.toLowerCase().contains(query);
        final labNameMatch = experiment.labName?.toLowerCase().contains(query) ?? false;
        final locationMatch = experiment.location.toLowerCase().contains(query);
        
        // 報酬額での検索（数値として入力された場合）
        final rewardMatch = int.tryParse(_searchQuery) != null 
            ? experiment.reward.toString().contains(_searchQuery)
            : false;
        
        return titleMatch || descriptionMatch || labNameMatch || locationMatch || rewardMatch;
      }).toList();
    }
    
    // タイプフィルター
    if (_selectedType != null) {
      filtered = filtered.where((e) => e.type == _selectedType).toList();
    }
    
    // ソート処理
    switch (_sortOption) {
      case SortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.highReward:
        filtered.sort((a, b) => b.reward.compareTo(a.reward));
        break;
      case SortOption.lowReward:
        filtered.sort((a, b) => a.reward.compareTo(b.reward));
        break;
      case SortOption.soonest:
        filtered.sort((a, b) {
          if (a.experimentDate == null && b.experimentDate == null) return 0;
          if (a.experimentDate == null) return 1;
          if (b.experimentDate == null) return -1;
          return a.experimentDate!.compareTo(b.experimentDate!);
        });
        break;
      case SortOption.latest:
        filtered.sort((a, b) {
          if (a.experimentDate == null && b.experimentDate == null) return 0;
          if (a.experimentDate == null) return -1;
          if (b.experimentDate == null) return 1;
          return b.experimentDate!.compareTo(a.experimentDate!);
        });
        break;
    }
    
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final newOffset = _scrollController.offset;
    // スクロール方向を検出して、ヘッダーの表示/非表示を切り替え
    if (newOffset > _scrollOffset && newOffset > 100) {
      // 下スクロール かつ 100px以上スクロールしている
      if (_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      }
    } else if (newOffset < _scrollOffset || newOffset <= 100) {
      // 上スクロール または スクロール位置が100px以下
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
    }
    _scrollOffset = newOffset;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCompactFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8E1728) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60, // アプリバーを自然な高さに
        titleSpacing: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
            actions: [
              // ユーザー情報表示
              if (widget.userName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Row(
                      children: [
                        if (widget.isWasedaUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '早稲田',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          widget.userName!.split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.logout, size: 24),
                onPressed: widget.onLogout,
                padding: const EdgeInsets.all(12),
              ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 64,
        child: FloatingActionButton.extended(
          onPressed: widget.canCreateExperiment
              ? widget.onCreateExperiment ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('実験作成機能は準備中です'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('実験募集は早稲田大学のメールアカウントでログインした方のみご利用いただけます'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
          icon: Icon(
            Icons.add,
            size: 24,
            color: widget.canCreateExperiment ? Colors.white : Colors.white70,
          ),
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '実験を募集',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.canCreateExperiment ? Colors.white : Colors.white70,
                ),
              ),
              if (!widget.canCreateExperiment)
                const Text(
                  '早稲田メール限定',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          backgroundColor: widget.canCreateExperiment
              ? const Color(0xFF8E1728)
              : Colors.grey,
          elevation: widget.canCreateExperiment ? 6 : 2,
        ),
      ),
      body: Column(
        children: [
          // 検索バー、種別切り替えボタン、ソート選択
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isHeaderVisible ? 100 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHeaderVisible ? 1.0 : 0.0,
                child: Column(
                  children: [
                    // 検索バー
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '検索（タイトル、研究室、場所など）',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 22,
                                  color: Color(0xFF8E1728),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          size: 20,
                                          color: Colors.grey.shade600,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E1728),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${filteredExperiments.length}件',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // タイプフィルターとソートを同じ行に配置
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // タイプフィルター（コンパクト版）
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCompactFilterChip('すべて', _selectedType == null, () {
                                  setState(() {
                                    _selectedType = null;
                                  });
                                }),
                                const SizedBox(width: 6),
                                ...ExperimentType.values.map((type) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: _buildCompactFilterChip(type.label, _selectedType == type, () {
                                      setState(() {
                                        _selectedType = _selectedType == type ? null : type;
                                      });
                                    }),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ソート選択
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SortOption>(
                              value: _sortOption,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF8E1728)),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                              onChanged: (SortOption? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _sortOption = newValue;
                                  });
                                }
                              },
                              items: SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption value) {
                                return DropdownMenuItem<SortOption>(
                                  value: value,
                                  child: Text(value.label, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
          
          // 実験リスト（レスポンシブグリッド）
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: filteredExperiments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? '「$_searchQuery」に一致する実験が見つかりません'
                                : '実験がありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 600, // カード最大幅を600pxに設定
                            crossAxisSpacing: 4, // 列間隔を4pxに設定
                            mainAxisSpacing: 4, // 行間隔を4pxに設定
                            mainAxisExtent: 250, // カードの固定高さを250pxに削減
                          ),
                          itemCount: filteredExperiments.length,
                          itemBuilder: (context, index) {
                            final experiment = filteredExperiments[index];
                            return ExperimentCard(experiment: experiment);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}