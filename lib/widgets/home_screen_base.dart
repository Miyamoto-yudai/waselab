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
  final bool isDemo;
  
  const HomeScreenBase({
    super.key,
    required this.title,
    required this.experiments,
    required this.canCreateExperiment,
    required this.userName,
    required this.isWasedaUser,
    required this.onLogout,
    this.onCreateExperiment,
    this.isDemo = false,
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
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  
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
    
    // 日付フィルター
    if (_startDateFilter != null || _endDateFilter != null) {
      filtered = filtered.where((experiment) {
        // 柔軟なスケジュールの場合
        if (experiment.allowFlexibleSchedule) {
          final expStart = experiment.experimentPeriodStart;
          final expEnd = experiment.experimentPeriodEnd;
          
          if (expStart == null || expEnd == null) return false;
          
          // 期間が重なるかチェック
          if (_startDateFilter != null && _endDateFilter != null) {
            return !(expEnd.isBefore(_startDateFilter!) || expStart.isAfter(_endDateFilter!));
          } else if (_startDateFilter != null) {
            return !expEnd.isBefore(_startDateFilter!);
          } else if (_endDateFilter != null) {
            return !expStart.isAfter(_endDateFilter!);
          }
        } else {
          // 固定日程の場合
          final expDate = experiment.recruitmentStartDate;
          if (expDate == null) return false;
          
          if (_startDateFilter != null && _endDateFilter != null) {
            return expDate.isAfter(_startDateFilter!.subtract(const Duration(days: 1))) && 
                   expDate.isBefore(_endDateFilter!.add(const Duration(days: 1)));
          } else if (_startDateFilter != null) {
            return !expDate.isBefore(_startDateFilter!);
          } else if (_endDateFilter != null) {
            return !expDate.isAfter(_endDateFilter!);
          }
        }
        return true;
      }).toList();
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
  
  /// 日付範囲選択ダイアログを表示
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDateFilter != null && _endDateFilter != null
          ? DateTimeRange(start: _startDateFilter!, end: _endDateFilter!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8E1728),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDateFilter = picked.start;
        _endDateFilter = picked.end;
      });
    }
  }
  
  /// クイック日付選択
  void _setQuickDateRange(String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      switch (type) {
        case 'today':
          _startDateFilter = today;
          _endDateFilter = today;
          break;
        case 'tomorrow':
          final tomorrow = today.add(const Duration(days: 1));
          _startDateFilter = tomorrow;
          _endDateFilter = tomorrow;
          break;
        case 'in2days':
          final in2days = today.add(const Duration(days: 2));
          _startDateFilter = in2days;
          _endDateFilter = in2days;
          break;
        case 'in3days':
          final in3days = today.add(const Duration(days: 3));
          _startDateFilter = in3days;
          _endDateFilter = in3days;
          break;
        case 'thisWeek':
          final weekday = now.weekday;
          _startDateFilter = today.subtract(Duration(days: weekday - 1));
          _endDateFilter = today.add(Duration(days: 7 - weekday));
          break;
        case 'clear':
          _startDateFilter = null;
          _endDateFilter = null;
          break;
      }
    });
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
  
  Widget _buildDateChip(String label, String type) {
    final isSelected = _checkDateSelection(type);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      height: 24,
      child: Material(
        color: isSelected 
          ? const Color(0xFF8E1728).withOpacity(0.1)
          : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _setQuickDateRange(type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                  ? const Color(0xFF8E1728)
                  : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  bool _checkDateSelection(String type) {
    if (_startDateFilter == null || _endDateFilter == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (type) {
      case 'today':
        return _startDateFilter == today && _endDateFilter == today;
      case 'tomorrow':
        final tomorrow = today.add(const Duration(days: 1));
        return _startDateFilter == tomorrow && _endDateFilter == tomorrow;
      case 'in2days':
        final in2days = today.add(const Duration(days: 2));
        return _startDateFilter == in2days && _endDateFilter == in2days;
      case 'in3days':
        final in3days = today.add(const Duration(days: 3));
        return _startDateFilter == in3days && _endDateFilter == in3days;
      case 'thisWeek':
        final weekday = now.weekday;
        final weekStart = today.subtract(Duration(days: weekday - 1));
        final weekEnd = today.add(Duration(days: 7 - weekday));
        return _startDateFilter == weekStart && _endDateFilter == weekEnd;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // アプリバー部分（スクロールで隠れる）
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isHeaderVisible ? 60 : 0,
            child: AppBar(
              toolbarHeight: 60,
              titleSpacing: 0,
              centerTitle: false,
              leading: LayoutBuilder(
                builder: (context, constraints) {
                  // 画面幅が600px以上の場合はフラスコアイコンを表示
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (screenWidth >= 600) {
                    return Container(
                      margin: const EdgeInsets.only(left: 16),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.science,
                        size: 24,
                        color: Color(0xFF8E1728),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              title: Padding(
                padding: const EdgeInsets.only(left: 8),
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
          ),
          // 検索バー、日付フィルター、種別切り替えボタン、ソート選択
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isHeaderVisible ? 150 : 0,
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
                    // 日付フィルター
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // 日付範囲選択ボタン
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: OutlinedButton.icon(
                                onPressed: _selectDateRange,
                                icon: Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: (_startDateFilter != null || _endDateFilter != null)
                                      ? const Color(0xFF8E1728)
                                      : Colors.grey[600],
                                ),
                                label: Text(
                                  (_startDateFilter != null && _endDateFilter != null)
                                      ? '${_startDateFilter!.month}/${_startDateFilter!.day}〜${_endDateFilter!.month}/${_endDateFilter!.day}'
                                      : '期間で絞り込む',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: (_startDateFilter != null || _endDateFilter != null)
                                        ? const Color(0xFF8E1728)
                                        : Colors.grey[700],
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: const Size(0, 28),
                                  side: BorderSide(
                                    color: (_startDateFilter != null || _endDateFilter != null)
                                        ? const Color(0xFF8E1728)
                                        : Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            // クイック選択ボタン（Chip風デザイン）
                            _buildDateChip('今日', 'today'),
                            _buildDateChip('明日', 'tomorrow'),
                            _buildDateChip('2日後', 'in2days'),
                            _buildDateChip('3日後', 'in3days'),
                            _buildDateChip('今週', 'thisWeek'),
                            // クリアボタン
                            if (_startDateFilter != null || _endDateFilter != null)
                              IconButton(
                                onPressed: () => _setQuickDateRange('clear'),
                                icon: const Icon(Icons.clear, size: 16),
                                tooltip: 'クリア',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                          ],
                        ),
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
                            mainAxisExtent: 230, // カードの固定高さを230pxに設定
                          ),
                          itemCount: filteredExperiments.length,
                          itemBuilder: (context, index) {
                            final experiment = filteredExperiments[index];
                            return ExperimentCard(
                              experiment: experiment,
                              isDemo: widget.isDemo,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isHeaderVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isHeaderVisible ? 1.0 : 0.0,
          child: SizedBox(
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
        ),
      ),
    );
  }
}