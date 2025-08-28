import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../widgets/experiment_card.dart';
import '../widgets/type_filter_bar.dart';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 42, // アプリバーの高さをさらに細くする
        titleSpacing: 0, // タイトルを完全に左寄せ
        centerTitle: false, // タイトルを左寄せに配置
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
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
                      widget.userName!.split(' ')[0], // 名前の最初の部分のみ表示
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: widget.onLogout,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      // 実験作成ボタン（権限に応じて表示）
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
          Column(
            children: [
              // 検索バー
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: '実験を検索（タイトル、説明、研究室、場所、報酬額）',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF8E1728),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18,
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              TypeFilterBar(
                selectedType: _selectedType,
                onTypeSelected: (type) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              ),
              // ソート選択ドロップダウン
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.sort, size: 20, color: Color(0xFF8E1728)),
                    const SizedBox(width: 8),
                    const Text(
                      '並び替え:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E1728),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SortOption>(
                            value: _sortOption,
                            isDense: true,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8E1728)),
                            style: const TextStyle(
                              fontSize: 14,
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
                                child: Text(value.label),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
            ],
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
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 700, // カード最大幅を700pxに設定
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